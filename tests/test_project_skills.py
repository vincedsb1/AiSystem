import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import yaml

from scripts.project_skills import (
    ProjectSkillsError,
    build_overview,
    list_projects,
    resolve_project,
    scan_project,
)


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "scripts" / "project_skills.py"


class ProjectFixture:
    """Small isolated registry/project fixture for read-only scan tests."""

    def __init__(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.base = Path(self.temp_dir.name)
        self.project_root = self.base / "Suggst"
        self.codex_root = self.project_root / ".agents" / "skills"
        self.claude_root = self.project_root / ".claude" / "commands"
        self.codex_root.mkdir(parents=True)
        self.claude_root.mkdir(parents=True)

        self.ai_root = self.base / "ai-system"
        self.ai_root.mkdir()
        self.manifest_path = self.ai_root / "skills-manifest.yml"
        self.registry_path = self.base / "skills-registry.yml"

        self.registry = {
            "version": 1,
            "settings": {"skills_manifest": str(self.manifest_path)},
            "projects": [
                {
                    "name": "Suggst",
                    "root": str(self.project_root),
                    "enabled": True,
                    "install_shared_targets": ["codex", "claude"],
                    "install_shared_skills": [],
                    "paths": {
                        "codex_skills": ".agents/skills",
                        "claude_commands": ".claude/commands",
                    },
                }
            ],
            "shared_sources": [],
            "pairing_exceptions": [],
            "quality_rules": {
                "metadata_required_for": ["codex_skill", "claude_command"],
                "required_frontmatter_fields": ["name", "description"],
                "recommended_frontmatter_fields": [],
                "ignore_names": [],
                "backup_patterns": [".bak", "~"],
                "forbidden_silent_fallback_patterns": [],
            },
        }
        self.manifest = {"version": 1, "artifacts": []}

    def close(self) -> None:
        self.temp_dir.cleanup()

    @property
    def project(self) -> dict:
        return self.registry["projects"][0]

    def content(
        self,
        name: str,
        *,
        description: str = "A test skill.",
        body: str = "# Test skill\n",
        frontmatter: bool = True,
        declared_name: str | None = None,
        include_description: bool = True,
    ) -> str:
        if not frontmatter:
            return body
        fields = [f"name: {declared_name or name}"]
        if include_description:
            fields.append(f"description: {description}")
        return "---\n" + "\n".join(fields) + "\n---\n\n" + body

    def add_runtime(
        self,
        name: str,
        *,
        codex: bool = False,
        claude: bool = False,
        codex_content: str | None = None,
        claude_content: str | None = None,
    ) -> None:
        if codex:
            skill_dir = self.codex_root / name
            skill_dir.mkdir(parents=True, exist_ok=True)
            (skill_dir / "SKILL.md").write_text(
                codex_content or self.content(name),
                encoding="utf-8",
            )
        if claude:
            (self.claude_root / f"{name}.md").write_text(
                claude_content or self.content(name),
                encoding="utf-8",
            )

    def add_manifest(
        self,
        name: str,
        *,
        canonical_id: str | None = None,
        scope: str = "project",
        project: str | None = "Suggst",
        export_targets: tuple[str, ...] = ("codex", "claude"),
        source_path: Path | None = None,
        description: str = "A test skill.",
    ) -> dict:
        canonical_id = canonical_id or f"suggst.{name}"
        if source_path is None:
            source_dir = (
                self.ai_root / "skills" / "shared" / name
                if scope == "shared"
                else self.ai_root / "skills" / "projects" / "suggst" / name
            )
            source_path = source_dir / "canonical.md"
        source_path.parent.mkdir(parents=True, exist_ok=True)
        source_path.write_text(
            self.content(name, description=description),
            encoding="utf-8",
        )

        exports = []
        for target in export_targets:
            if target == "codex":
                export_path = self.codex_root / name / "SKILL.md"
                export_target = "codex_skill"
            else:
                export_path = self.claude_root / f"{name}.md"
                export_target = "claude_command"
            exports.append({"target": export_target, "path": str(export_path)})

        artifact = {
            "canonical_id": canonical_id,
            "name": name,
            "description": description,
            "version": "1.0.0",
            "scope": scope,
            "project": None if scope == "shared" else project,
            "status": "active",
            "source_of_truth": str(source_path),
            "compatibility": {"claude_code": True, "codex": True},
            "exports": exports,
        }
        self.manifest["artifacts"].append(artifact)
        if scope == "shared":
            self.project["install_shared_skills"].append(canonical_id)
        return artifact

    def write_configs(self) -> None:
        self.registry_path.write_text(
            yaml.safe_dump(self.registry, sort_keys=False),
            encoding="utf-8",
        )
        self.manifest_path.write_text(
            yaml.safe_dump(self.manifest, sort_keys=False),
            encoding="utf-8",
        )

    def scan(self) -> dict:
        return scan_project(self.registry, self.manifest, "Suggst")


class ProjectSkillsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = ProjectFixture()

    def tearDown(self) -> None:
        self.fixture.close()

    def skill(self, payload: dict, name: str) -> dict:
        return next(skill for skill in payload["skills"] if skill["name"] == name)

    def test_list_projects_returns_only_enabled_projects(self):
        self.fixture.registry["projects"].append(
            {
                "name": "suggst",
                "root": str(self.fixture.base / "missing-disabled"),
                "enabled": False,
                "paths": {
                    "codex_skills": ".agents/skills",
                    "claude_commands": ".claude/commands",
                },
            }
        )

        projects = list_projects(self.fixture.registry)

        self.assertEqual([project["name"] for project in projects], ["Suggst"])
        self.assertTrue(projects[0]["enabled"])
        self.assertEqual(
            projects[0]["paths"]["codexSkills"],
            str(self.fixture.codex_root.resolve()),
        )

    def test_exact_resolution_does_not_select_disabled_case_variant(self):
        self.fixture.registry["projects"].append(
            {
                "name": "suggst",
                "root": str(self.fixture.base / "missing-disabled"),
                "enabled": False,
                "paths": {
                    "codex_skills": ".agents/skills",
                    "claude_commands": ".claude/commands",
                },
            }
        )

        self.assertEqual(
            resolve_project(self.fixture.registry, "Suggst")["name"],
            "Suggst",
        )
        with self.assertRaises(ProjectSkillsError) as disabled:
            resolve_project(self.fixture.registry, "suggst")
        self.assertEqual(disabled.exception.code, "disabled_project")

    def test_unknown_project_is_structured(self):
        with self.assertRaises(ProjectSkillsError) as context:
            resolve_project(self.fixture.registry, "Unknown")
        self.assertEqual(context.exception.code, "unknown_project")

    def test_codex_only_unmanaged_is_detected_and_importable(self):
        self.fixture.add_runtime("new-skill", codex=True)

        skill = self.skill(self.fixture.scan(), "new-skill")

        self.assertEqual(skill["status"], "local_codex_only")
        self.assertFalse(skill["managed"])
        self.assertTrue(skill["importable"])
        self.assertTrue(skill["presence"]["codex"])
        self.assertFalse(skill["presence"]["claude"])
        self.assertEqual(skill["candidateCanonicalId"], "suggst.new-skill")

    def test_claude_only_unmanaged_is_detected_and_importable(self):
        self.fixture.add_runtime("new-command", claude=True)

        skill = self.skill(self.fixture.scan(), "new-command")

        self.assertEqual(skill["status"], "local_claude_only")
        self.assertFalse(skill["managed"])
        self.assertTrue(skill["importable"])

    def test_expected_claude_only_pairing_exception_is_not_importable(self):
        self.fixture.registry["pairing_exceptions"].append(
            {
                "project": "Suggst",
                "artifact_type": "claude_command",
                "name": "intentional-command",
                "expected_status": "claude_only_project_command",
                "reason": "Kept Claude-only by project policy.",
            }
        )
        self.fixture.add_runtime("intentional-command", claude=True)

        skill = self.skill(self.fixture.scan(), "intentional-command")

        self.assertEqual(skill["status"], "expected_claude_only")
        self.assertFalse(skill["managed"])
        self.assertFalse(skill["importable"])
        self.assertEqual(
            skill["exception"]["status"], "claude_only_project_command"
        )

    def test_both_sides_without_canonical_are_unmanaged(self):
        self.fixture.add_runtime(
            "manual-skill",
            codex=True,
            claude=True,
            codex_content=self.fixture.content(
                "manual-skill", body="# Codex version\n"
            ),
            claude_content=self.fixture.content(
                "manual-skill", body="# Claude version\n"
            ),
        )

        skill = self.skill(self.fixture.scan(), "manual-skill")

        self.assertEqual(skill["status"], "local_both_unmanaged")
        self.assertFalse(skill["managed"])
        self.assertFalse(skill["importable"])

    def test_project_specific_canonical_is_managed_and_paired(self):
        self.fixture.add_runtime("foo", codex=True, claude=True)
        self.fixture.add_manifest("foo")

        skill = self.skill(self.fixture.scan(), "foo")

        self.assertEqual(skill["status"], "managed_synced")
        self.assertTrue(skill["managed"])
        self.assertEqual(skill["canonicalId"], "suggst.foo")
        self.assertEqual(skill["scope"], "project")
        self.assertTrue(skill["presence"]["codex"])
        self.assertTrue(skill["presence"]["claude"])

    def test_shared_skill_is_managed_for_selected_project(self):
        self.fixture.add_runtime("shared-foo", codex=True, claude=True)
        self.fixture.add_manifest(
            "shared-foo",
            canonical_id="shared.shared-foo",
            scope="shared",
            project=None,
        )

        skill = self.skill(self.fixture.scan(), "shared-foo")

        self.assertEqual(skill["status"], "managed_synced")
        self.assertTrue(skill["managed"])
        self.assertEqual(skill["canonicalId"], "shared.shared-foo")
        self.assertEqual(skill["scope"], "shared")

    def test_registered_external_shared_claude_symlink_is_allowed(self):
        shared_root = self.fixture.base / "claude-commands"
        shared_root.mkdir()
        shared_file = shared_root / "shared-foo.md"
        shared_file.write_text(
            self.fixture.content("shared-foo"),
            encoding="utf-8",
        )
        claude_link = self.fixture.claude_root / "shared-foo.md"
        claude_link.symlink_to(shared_file)
        self.fixture.add_runtime("shared-foo", codex=True)
        self.fixture.registry["shared_sources"] = [
            {
                "name": "claude-commands",
                "root": str(shared_root),
                "artifact_type": "claude_command",
                "enabled": True,
            }
        ]
        self.fixture.add_manifest(
            "shared-foo",
            canonical_id="shared.shared-foo",
            scope="shared",
            project=None,
        )
        self.fixture.manifest["artifacts"][-1]["exports"][1]["path"] = str(
            shared_file
        )

        skill = self.skill(self.fixture.scan(), "shared-foo")

        self.assertEqual(skill["status"], "managed_synced")
        self.assertTrue(skill["managed"])

    def test_missing_claude_on_managed_canonical_is_reported(self):
        self.fixture.add_manifest("codex-only-managed")
        self.fixture.add_runtime("codex-only-managed", codex=True)

        skill = self.skill(self.fixture.scan(), "codex-only-managed")

        self.assertEqual(skill["status"], "missing_claude")
        self.assertTrue(skill["managed"])
        self.assertFalse(skill["presence"]["claude"])

    def test_missing_codex_on_managed_canonical_is_reported(self):
        self.fixture.add_manifest("claude-only-managed")
        self.fixture.add_runtime("claude-only-managed", claude=True)

        skill = self.skill(self.fixture.scan(), "claude-only-managed")

        self.assertEqual(skill["status"], "missing_codex")
        self.assertTrue(skill["managed"])
        self.assertFalse(skill["presence"]["codex"])

    def test_canonical_drift_is_a_conflict(self):
        self.fixture.add_runtime("drifted", codex=True, claude=True)
        self.fixture.add_manifest(
            "drifted",
            canonical_id="suggst.drifted-codex",
            export_targets=("codex",),
        )
        self.fixture.add_manifest(
            "drifted",
            canonical_id="suggst.drifted-claude",
            export_targets=("claude",),
        )

        skill = self.skill(self.fixture.scan(), "drifted")

        self.assertEqual(skill["status"], "conflict")
        self.assertFalse(skill["managed"])
        self.assertEqual(skill["conflict"]["code"], "manifest_name_collision")

    def test_frontmatter_error_is_localized_and_not_importable(self):
        self.fixture.add_runtime(
            "invalid-skill",
            codex=True,
            codex_content=self.fixture.content(
                "invalid-skill",
                frontmatter=True,
                include_description=False,
            ),
        )

        skill = self.skill(self.fixture.scan(), "invalid-skill")

        self.assertEqual(skill["status"], "local_codex_only")
        self.assertFalse(skill["importable"])
        self.assertEqual(skill["conflict"]["code"], "missing_description")

    def test_path_escape_symlink_is_rejected(self):
        outside = self.fixture.base / "outside.md"
        outside.write_text(self.fixture.content("escaped"), encoding="utf-8")
        (self.fixture.claude_root / "escaped.md").symlink_to(outside)

        with self.assertRaises(ProjectSkillsError) as context:
            self.fixture.scan()

        self.assertEqual(context.exception.code, "path_escape")

    def test_disabled_project_scan_is_rejected(self):
        self.fixture.project["enabled"] = False

        with self.assertRaises(ProjectSkillsError) as context:
            self.fixture.scan()

        self.assertEqual(context.exception.code, "disabled_project")

    def test_json_error_output_is_valid_and_structured(self):
        bad_registry = self.fixture.base / "invalid-registry.yml"
        bad_registry.write_text("projects: [\n", encoding="utf-8")

        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "--registry",
                str(bad_registry),
                "list-projects",
                "--json",
            ],
            check=False,
            capture_output=True,
            text=True,
        )

        payload = json.loads(result.stdout)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(payload["status"], "error")
        self.assertEqual(payload["error"]["code"], "invalid_registry")
        self.assertEqual(result.stderr, "")

    def test_summary_matches_skill_rows(self):
        self.fixture.add_runtime("unmanaged", codex=True)
        self.fixture.add_runtime("managed", codex=True, claude=True)
        self.fixture.add_manifest("managed")

        payload = self.fixture.scan()
        summary = payload["summary"]
        skills = payload["skills"]

        self.assertEqual(summary["total"], len(skills))
        self.assertEqual(summary["managed"], sum(skill["managed"] for skill in skills))
        self.assertEqual(
            summary["unmanaged"],
            sum(
                not skill["managed"]
                and skill["status"]
                not in {"expected_claude_only", "expected_codex_only"}
                for skill in skills
            ),
        )
        self.assertEqual(
            summary["actionRequired"],
            sum(
                skill["status"]
                in {
                    "local_codex_only",
                    "local_claude_only",
                    "local_both_unmanaged",
                    "missing_claude",
                    "missing_codex",
                    "canonical_drift",
                    "manifest_error",
                    "conflict",
                }
                for skill in skills
            ),
        )

    def test_scan_is_idempotent_and_read_only(self):
        self.fixture.add_runtime("stable", codex=True, claude=True)
        self.fixture.add_manifest("stable")

        def snapshot() -> dict[str, bytes]:
            return {
                str(path.relative_to(self.fixture.base)): path.read_bytes()
                for path in self.fixture.base.rglob("*")
                if path.is_file() or path.is_symlink()
            }

        before = snapshot()
        first = self.fixture.scan()
        after_first = snapshot()
        second = self.fixture.scan()
        after_second = snapshot()

        first["generatedAt"] = None
        second["generatedAt"] = None
        self.assertEqual(first, second)
        self.assertEqual(before, after_first)
        self.assertEqual(after_first, after_second)


class SharedTargetPolicyTests(unittest.TestCase):
    """A shared export is only expected on the targets a project installs."""

    def setUp(self) -> None:
        self.fixture = ProjectFixture()

    def tearDown(self) -> None:
        self.fixture.close()

    def skill(self, payload: dict, name: str) -> dict:
        return next(skill for skill in payload["skills"] if skill["name"] == name)

    def test_codex_only_project_does_not_report_missing_claude_export(self):
        self.fixture.project["install_shared_targets"] = ["codex"]
        self.fixture.add_runtime("shared-tool", codex=True)
        self.fixture.add_manifest("shared-tool", canonical_id="shared.shared-tool", scope="shared")

        payload = self.fixture.scan()
        row = self.skill(payload, "shared-tool")

        self.assertEqual(row["status"], "managed_synced")
        self.assertTrue(row["managed"])
        self.assertEqual(payload["summary"]["actionRequired"], 0)
        self.assertEqual(payload["project"]["sharedTargets"], ["codex"])

    def test_missing_shared_targets_defaults_to_codex_only(self):
        self.fixture.project.pop("install_shared_targets", None)
        self.fixture.add_runtime("shared-tool", codex=True)
        self.fixture.add_manifest("shared-tool", canonical_id="shared.shared-tool", scope="shared")

        payload = self.fixture.scan()

        self.assertEqual(payload["project"]["sharedTargets"], ["codex"])
        self.assertEqual(self.skill(payload, "shared-tool")["status"], "managed_synced")

    def test_claude_targeted_project_still_reports_missing_claude_export(self):
        self.fixture.project["install_shared_targets"] = ["codex", "claude"]
        self.fixture.add_runtime("shared-tool", codex=True)
        self.fixture.add_manifest("shared-tool", canonical_id="shared.shared-tool", scope="shared")

        payload = self.fixture.scan()
        row = self.skill(payload, "shared-tool")

        self.assertEqual(row["status"], "missing_claude")
        self.assertEqual(row["severity"], "attention")
        self.assertEqual(row["allowedActions"], ["sync"])
        self.assertEqual(payload["summary"]["actionRequired"], 1)

    def test_project_scoped_skill_is_unaffected_by_shared_targets(self):
        self.fixture.project["install_shared_targets"] = ["codex"]
        self.fixture.add_runtime("local-tool", codex=True)
        self.fixture.add_manifest("local-tool")

        row = self.skill(self.fixture.scan(), "local-tool")

        self.assertEqual(row["status"], "missing_claude")


class SkillActionContractTests(unittest.TestCase):
    """Backend stays authoritative on severity and allowed actions."""

    def setUp(self) -> None:
        self.fixture = ProjectFixture()

    def tearDown(self) -> None:
        self.fixture.close()

    def skill(self, payload: dict, name: str) -> dict:
        return next(skill for skill in payload["skills"] if skill["name"] == name)

    def test_synced_skill_exposes_no_action(self):
        self.fixture.add_runtime("stable", codex=True, claude=True)
        self.fixture.add_manifest("stable")

        row = self.skill(self.fixture.scan(), "stable")

        self.assertIsNone(row["severity"])
        self.assertEqual(row["allowedActions"], [])

    def test_importable_skill_exposes_import_action(self):
        self.fixture.add_runtime("new-skill", codex=True)

        row = self.skill(self.fixture.scan(), "new-skill")

        self.assertEqual(row["status"], "local_codex_only")
        self.assertTrue(row["importable"])
        self.assertEqual(row["allowedActions"], ["import"])
        self.assertEqual(row["severity"], "attention")

    def test_non_importable_skill_falls_back_to_review(self):
        self.fixture.add_runtime(
            "broken",
            codex=True,
            codex_content=self.fixture.content("broken", frontmatter=False),
        )

        row = self.skill(self.fixture.scan(), "broken")

        self.assertFalse(row["importable"])
        self.assertNotIn("import", row["allowedActions"])
        self.assertEqual(row["allowedActions"], ["review"])


class OverviewTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = ProjectFixture()

    def tearDown(self) -> None:
        self.fixture.close()

    def overview(self) -> dict:
        return build_overview(self.fixture.registry, self.fixture.manifest)

    def test_healthy_system_reports_no_action(self):
        self.fixture.add_runtime("stable", codex=True, claude=True)
        self.fixture.add_manifest("stable")

        payload = self.overview()

        self.assertEqual(payload["schemaVersion"], 1)
        self.assertEqual(payload["status"], "ok")
        self.assertEqual(payload["state"], "healthy")
        self.assertEqual(payload["summary"]["projectsTotal"], 1)
        self.assertEqual(payload["summary"]["projectsHealthy"], 1)
        self.assertEqual(payload["summary"]["actionRequired"], 0)
        self.assertEqual(payload["actions"], [])
        self.assertIsNone(payload["error"])

    def test_actionable_skill_surfaces_as_attention(self):
        self.fixture.add_runtime("new-skill", codex=True)

        payload = self.overview()

        self.assertEqual(payload["state"], "attention")
        self.assertEqual(payload["summary"]["projectsAttention"], 1)
        self.assertEqual(len(payload["actions"]), 1)

        action = payload["actions"][0]
        self.assertEqual(action["id"], "Suggst::new-skill")
        self.assertEqual(action["project"], "Suggst")
        self.assertEqual(action["severity"], "attention")
        self.assertTrue(action["importable"])

    def test_blocking_status_surfaces_as_error_and_sorts_first(self):
        self.fixture.add_runtime("new-skill", codex=True)
        self.fixture.add_runtime("drifted", codex=True, claude=True)
        self.fixture.add_manifest(
            "drifted",
            canonical_id="suggst.drifted-codex",
            export_targets=("codex",),
        )
        self.fixture.add_manifest(
            "drifted",
            canonical_id="suggst.drifted-claude",
            export_targets=("claude",),
        )

        payload = self.overview()

        self.assertEqual(payload["state"], "error")
        self.assertEqual(payload["summary"]["projectsError"], 1)
        self.assertEqual(payload["actions"][0]["severity"], "error")

    def test_disabled_projects_are_excluded(self):
        self.fixture.registry["projects"].append(
            {
                "name": "Disabled",
                "root": str(self.fixture.project_root),
                "enabled": False,
                "paths": {
                    "codex_skills": ".agents/skills",
                    "claude_commands": ".claude/commands",
                },
            }
        )

        payload = self.overview()

        self.assertEqual(payload["summary"]["projectsTotal"], 1)
        self.assertEqual([entry["name"] for entry in payload["projects"]], ["Suggst"])

    def test_unscannable_project_is_reported_without_breaking_overview(self):
        self.fixture.add_runtime("stable", codex=True, claude=True)
        self.fixture.add_manifest("stable")
        self.fixture.registry["projects"].append(
            {
                "name": "Broken",
                "root": str(self.fixture.base / "does-not-exist"),
                "enabled": True,
                "install_shared_targets": ["codex"],
                "install_shared_skills": [],
                "paths": {
                    "codex_skills": ".agents/skills",
                    "claude_commands": ".claude/commands",
                },
            }
        )

        payload = self.overview()

        self.assertEqual(payload["state"], "error")
        self.assertEqual(payload["summary"]["projectsTotal"], 2)
        self.assertEqual(payload["summary"]["projectsError"], 1)

        broken = next(entry for entry in payload["projects"] if entry["name"] == "Broken")
        self.assertEqual(broken["state"], "error")
        self.assertEqual(broken["error"]["code"], "missing_project_root")

        healthy = next(entry for entry in payload["projects"] if entry["name"] == "Suggst")
        self.assertEqual(healthy["state"], "healthy")

    def test_overview_is_read_only(self):
        self.fixture.add_runtime("stable", codex=True, claude=True)
        self.fixture.add_manifest("stable")

        def snapshot() -> dict[str, bytes]:
            return {
                str(path.relative_to(self.fixture.base)): path.read_bytes()
                for path in self.fixture.base.rglob("*")
                if path.is_file() or path.is_symlink()
            }

        before = snapshot()
        self.overview()
        self.assertEqual(before, snapshot())


class OverviewCliTests(unittest.TestCase):
    """The machine route must emit clean JSON on stdout."""

    def setUp(self) -> None:
        self.fixture = ProjectFixture()
        self.fixture.add_runtime("stable", codex=True, claude=True)
        self.fixture.add_manifest("stable")
        self.fixture.write_configs()

    def tearDown(self) -> None:
        self.fixture.close()

    def test_overview_cli_emits_parseable_json(self):
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "--registry",
                str(self.fixture.registry_path),
                "overview",
                "--json",
            ],
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["schemaVersion"], 1)
        self.assertEqual(payload["status"], "ok")
        self.assertEqual(payload["state"], "healthy")


if __name__ == "__main__":
    unittest.main()
