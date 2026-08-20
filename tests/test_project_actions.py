import json
import subprocess
import sys
import unittest
from pathlib import Path

import yaml

from scripts.project_actions import (
    AI_SYSTEM_ROOT,
    ProjectActionError,
    canonical_target_path,
    import_skill,
    sync_project,
)
from scripts.project_skills import scan_project

from tests.test_project_skills import ProjectFixture


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "scripts" / "project_actions.py"


class ActionFixture(ProjectFixture):
    """Project fixture whose manifest lives on disk so writes can be verified."""

    def __init__(self) -> None:
        super().__init__()
        self.project["install_shared_targets"] = ["codex", "claude"]
        self.write_configs()

    def reload_manifest(self) -> dict:
        return yaml.safe_load(self.manifest_path.read_text(encoding="utf-8"))

    def do_import(self, skill: str, source: str = "codex") -> dict:
        self.write_configs()
        manifest = self.reload_manifest()
        payload = import_skill(
            self.registry, manifest, self.manifest_path, "Suggst", skill, source
        )
        self.manifest = self.reload_manifest()
        return payload

    def do_sync(self, *, apply: bool = True) -> dict:
        self.write_configs()
        manifest = self.reload_manifest()
        payload = sync_project(self.registry, manifest, "Suggst", apply=apply)
        self.manifest = self.reload_manifest()
        return payload

    def scan(self) -> dict:
        return scan_project(self.registry, self.reload_manifest(), "Suggst")


class ImportTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = ActionFixture()

    def tearDown(self) -> None:
        self.fixture.close()

    def skill(self, payload: dict, name: str) -> dict:
        return next(skill for skill in payload["skills"] if skill["name"] == name)

    def test_codex_only_skill_becomes_managed(self):
        self.fixture.add_runtime("new-skill", codex=True)

        payload = self.fixture.do_import("new-skill", "codex")

        self.assertEqual(payload["status"], "ok")
        self.assertEqual(payload["outcome"], "imported")
        self.assertEqual(payload["writeState"], "applied")
        self.assertEqual(payload["changes"]["created"], 1)

        canonical = Path(payload["changes"]["canonicalPath"])
        self.assertTrue(canonical.is_file())
        self.assertIn("name: new-skill", canonical.read_text(encoding="utf-8"))

        entries = [
            artifact
            for artifact in self.fixture.reload_manifest()["artifacts"]
            if artifact["canonical_id"] == "suggst.new-skill"
        ]
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0]["scope"], "project")
        self.assertEqual(entries[0]["project"], "Suggst")

    def test_claude_only_skill_can_be_imported(self):
        self.fixture.add_runtime("claude-tool", claude=True)

        payload = self.fixture.do_import("claude-tool", "claude")

        self.assertEqual(payload["outcome"], "imported")
        self.assertTrue(Path(payload["changes"]["canonicalPath"]).is_file())

    def test_repeated_import_is_idempotent(self):
        self.fixture.add_runtime("new-skill", codex=True)
        first = self.fixture.do_import("new-skill", "codex")
        self.assertEqual(first["outcome"], "imported")

        second = self.fixture.do_import("new-skill", "codex")

        self.assertEqual(second["outcome"], "already_managed")
        self.assertEqual(second["writeState"], "no_changes")
        self.assertEqual(second["changes"]["created"], 0)

        entries = [
            artifact
            for artifact in self.fixture.reload_manifest()["artifacts"]
            if artifact["canonical_id"] == "suggst.new-skill"
        ]
        self.assertEqual(len(entries), 1)

        canonical_dir = Path(first["changes"]["canonicalPath"]).parent
        self.assertEqual(len(list(canonical_dir.glob("canonical*.md"))), 1)

    def test_already_managed_skill_reports_without_writing(self):
        self.fixture.add_runtime("stable", codex=True, claude=True)
        self.fixture.add_manifest("stable")

        payload = self.fixture.do_import("stable", "codex")

        self.assertEqual(payload["outcome"], "already_managed")
        self.assertEqual(payload["writeState"], "no_changes")

    def test_incompatible_canonical_is_a_conflict_and_writes_nothing(self):
        self.fixture.add_runtime("new-skill", codex=True)

        canonical = canonical_target_path(
            self.fixture.manifest_path, "Suggst", "new-skill"
        )
        canonical.parent.mkdir(parents=True, exist_ok=True)
        canonical.write_text("---\nname: other\n---\n\nDifferent.\n", encoding="utf-8")

        before = self.fixture.manifest_path.read_bytes()
        with self.assertRaises(ProjectActionError) as raised:
            self.fixture.do_import("new-skill", "codex")

        self.assertEqual(raised.exception.code, "canonical_conflict")
        self.assertEqual(raised.exception.write_state, "no_changes")
        self.assertEqual(self.fixture.manifest_path.read_bytes(), before)

    def test_expected_exception_is_not_importable(self):
        self.fixture.registry["pairing_exceptions"] = [
            {
                "project": "Suggst",
                "name": "claude-only",
                "artifact_type": "claude_command",
                "expected_status": "expected_claude_only",
                "reason": "Commande Claude uniquement.",
            }
        ]
        self.fixture.add_runtime("claude-only", claude=True)

        with self.assertRaises(ProjectActionError) as raised:
            self.fixture.do_import("claude-only", "claude")

        self.assertEqual(raised.exception.code, "not_importable")
        self.assertEqual(raised.exception.write_state, "no_changes")

    def test_frontmatter_error_blocks_import(self):
        self.fixture.add_runtime(
            "broken",
            codex=True,
            codex_content=self.fixture.content("broken", frontmatter=False),
        )

        with self.assertRaises(ProjectActionError) as raised:
            self.fixture.do_import("broken", "codex")

        self.assertEqual(raised.exception.code, "not_importable")

    def test_unknown_skill_is_structured(self):
        with self.assertRaises(ProjectActionError) as raised:
            self.fixture.do_import("ghost", "codex")

        self.assertEqual(raised.exception.code, "unknown_skill")

    def test_source_mismatch_is_rejected(self):
        self.fixture.add_runtime("new-skill", codex=True)

        with self.assertRaises(ProjectActionError) as raised:
            self.fixture.do_import("new-skill", "claude")

        self.assertIn(raised.exception.code, {"missing_source", "source_mismatch"})
        self.assertEqual(raised.exception.write_state, "no_changes")

    def test_imported_skill_is_recognised_by_a_rescan(self):
        self.fixture.add_runtime("new-skill", codex=True)
        self.fixture.do_import("new-skill", "codex")

        row = self.skill(self.fixture.scan(), "new-skill")

        self.assertTrue(row["managed"])
        self.assertEqual(row["canonicalId"], "suggst.new-skill")
        # Claude export is expected but absent until a sync runs.
        self.assertEqual(row["status"], "missing_claude")


class WriteIsolationTests(unittest.TestCase):
    """Actions must never write outside the AI System root they were given."""

    def setUp(self) -> None:
        self.fixture = ActionFixture()

    def tearDown(self) -> None:
        self.fixture.close()

    def test_canonical_target_stays_under_the_selected_manifest_root(self):
        target = canonical_target_path(self.fixture.manifest_path, "Suggst", "new-skill")

        self.assertTrue(target.is_relative_to(self.fixture.ai_root))
        self.assertFalse(target.is_relative_to(AI_SYSTEM_ROOT / "skills"))

    def test_import_does_not_touch_the_real_repository(self):
        real_projects = AI_SYSTEM_ROOT / "skills" / "projects"
        before = sorted(path.name for path in real_projects.rglob("*"))

        self.fixture.add_runtime("new-skill", codex=True)
        payload = self.fixture.do_import("new-skill", "codex")

        self.assertTrue(
            Path(payload["changes"]["canonicalPath"]).is_relative_to(self.fixture.ai_root)
        )
        self.assertEqual(sorted(path.name for path in real_projects.rglob("*")), before)


class SyncTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = ActionFixture()

    def tearDown(self) -> None:
        self.fixture.close()

    def test_sync_creates_a_missing_export(self):
        self.fixture.add_runtime("paired", codex=True)
        self.fixture.add_manifest("paired")

        payload = self.fixture.do_sync()

        self.assertEqual(payload["status"], "ok")
        self.assertEqual(payload["writeState"], "applied")
        self.assertEqual(payload["changes"]["created"], 1)
        self.assertTrue((self.fixture.claude_root / "paired.md").is_file())

    def test_sync_without_change_reports_no_write(self):
        self.fixture.add_runtime("stable", codex=True, claude=True)
        self.fixture.add_manifest("stable")

        payload = self.fixture.do_sync()

        self.assertEqual(payload["writeState"], "no_changes")
        self.assertEqual(payload["changes"]["created"], 0)
        self.assertEqual(payload["changes"]["updated"], 0)

    def test_sync_is_idempotent(self):
        self.fixture.add_runtime("paired", codex=True)
        self.fixture.add_manifest("paired")

        first = self.fixture.do_sync()
        second = self.fixture.do_sync()

        self.assertEqual(first["changes"]["created"], 1)
        self.assertEqual(second["changes"]["created"], 0)
        self.assertEqual(second["writeState"], "no_changes")

    def test_dry_run_writes_nothing(self):
        self.fixture.add_runtime("paired", codex=True)
        self.fixture.add_manifest("paired")

        payload = self.fixture.do_sync(apply=False)

        self.assertEqual(payload["outcome"], "planned")
        self.assertEqual(payload["writeState"], "no_changes")
        self.assertEqual(payload["changes"]["created"], 1)
        self.assertFalse(payload["changes"]["applied"])
        self.assertFalse((self.fixture.claude_root / "paired.md").exists())

    def test_conflicts_are_reported_and_never_overwritten(self):
        self.fixture.add_runtime("drifted", codex=True, claude=True)
        self.fixture.add_manifest(
            "drifted", canonical_id="suggst.drifted-codex", export_targets=("codex",)
        )
        self.fixture.add_manifest(
            "drifted", canonical_id="suggst.drifted-claude", export_targets=("claude",)
        )
        before = (self.fixture.claude_root / "drifted.md").read_bytes()

        payload = self.fixture.do_sync()

        self.assertGreaterEqual(payload["changes"]["conflicts"], 1)
        self.assertEqual(payload["writeState"], "no_changes")
        self.assertEqual((self.fixture.claude_root / "drifted.md").read_bytes(), before)

    def test_summary_is_human_readable(self):
        self.fixture.add_runtime("paired", codex=True)
        self.fixture.add_manifest("paired")

        payload = self.fixture.do_sync()

        self.assertIn("Synchronisation terminée", payload["summary"])
        self.assertIn("créé", payload["summary"])


class ActionCliTests(unittest.TestCase):
    """Machine routes must emit clean, parseable JSON on stdout."""

    def setUp(self) -> None:
        self.fixture = ActionFixture()
        self.fixture.add_runtime("paired", codex=True)
        self.fixture.add_manifest("paired")
        self.fixture.write_configs()

    def tearDown(self) -> None:
        self.fixture.close()

    def run_cli(self, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            [sys.executable, str(SCRIPT_PATH), "--registry",
             str(self.fixture.registry_path), *args],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_sync_dry_run_cli_emits_json(self):
        result = self.run_cli("sync", "--project", "Suggst", "--dry-run", "--json")

        self.assertEqual(result.returncode, 0)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["schemaVersion"], 1)
        self.assertEqual(payload["action"], "sync")
        self.assertEqual(payload["writeState"], "no_changes")

    def test_unknown_project_cli_emits_structured_error(self):
        result = self.run_cli("sync", "--project", "Ghost", "--json")

        self.assertEqual(result.returncode, 1)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["status"], "error")
        self.assertEqual(payload["error"]["code"], "unknown_project")
        self.assertEqual(payload["writeState"], "no_changes")

    def test_invalid_source_is_rejected_by_the_parser(self):
        result = self.run_cli(
            "import", "--project", "Suggst", "--skill", "paired",
            "--source", "rm -rf /", "--json",
        )

        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()


class AddProjectTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = ActionFixture()
        self.candidate = Path(self.fixture.base) / "NewProject"
        (self.candidate / ".agents" / "skills").mkdir(parents=True)

    def tearDown(self) -> None:
        self.fixture.close()

    def inspect(self, path: str) -> dict:
        from scripts.project_actions import inspect_folder

        return inspect_folder(self.fixture.registry, path)

    def add(self, name: str, path: str, targets: list[str]) -> dict:
        from scripts.project_actions import add_project

        self.fixture.write_configs()
        registry = yaml.safe_load(
            self.fixture.registry_path.read_text(encoding="utf-8")
        )
        payload = add_project(
            registry, self.fixture.registry_path, name, path, targets
        )
        self.fixture.registry = yaml.safe_load(
            self.fixture.registry_path.read_text(encoding="utf-8")
        )
        return payload

    def test_inspect_suggests_name_and_detects_targets(self):
        payload = self.inspect(str(self.candidate))

        self.assertEqual(payload["suggestedName"], "NewProject")
        self.assertEqual(payload["detectedTargets"], ["codex"])
        self.assertEqual(payload["proposedTargets"], ["codex"])
        self.assertIsNone(payload["alreadyRegistered"])

    def test_inspect_preserves_the_existing_install_now_default(self):
        payload = self.inspect(str(self.candidate))

        self.assertFalse(payload["defaultInstallNow"])

    def test_inspect_detects_both_runtimes(self):
        (self.candidate / ".claude" / "commands").mkdir(parents=True)

        payload = self.inspect(str(self.candidate))

        self.assertEqual(sorted(payload["detectedTargets"]), ["claude", "codex"])

    def test_inspect_falls_back_to_codex_when_nothing_is_detected(self):
        bare = Path(self.fixture.base) / "Bare"
        bare.mkdir()

        payload = self.inspect(str(bare))

        self.assertEqual(payload["detectedTargets"], [])
        self.assertEqual(payload["proposedTargets"], ["codex"])

    def test_inspect_reports_an_already_registered_root(self):
        payload = self.inspect(str(self.fixture.project_root))

        self.assertIsNotNone(payload["alreadyRegistered"])
        self.assertEqual(payload["alreadyRegistered"]["reason"], "same_root")

    def test_inspect_rejects_a_relative_path(self):
        with self.assertRaises(ProjectActionError) as raised:
            self.inspect("relative/path")

        self.assertEqual(raised.exception.code, "invalid_path")

    def test_inspect_rejects_a_missing_folder(self):
        with self.assertRaises(ProjectActionError) as raised:
            self.inspect(str(Path(self.fixture.base) / "ghost"))

        self.assertEqual(raised.exception.code, "folder_unreadable")

    def test_add_writes_the_project_to_the_registry(self):
        payload = self.add("NewProject", str(self.candidate), ["codex"])

        self.assertEqual(payload["outcome"], "added")
        self.assertEqual(payload["writeState"], "applied")

        names = [project["name"] for project in self.fixture.registry["projects"]]
        self.assertIn("NewProject", names)

        entry = next(
            project
            for project in self.fixture.registry["projects"]
            if project["name"] == "NewProject"
        )
        self.assertTrue(entry["enabled"])
        self.assertEqual(entry["install_shared_targets"], ["codex"])
        self.assertEqual(entry["paths"]["codex_skills"], ".agents/skills")

    def test_add_accepts_a_path_with_spaces(self):
        spaced = Path(self.fixture.base) / "My Project"
        (spaced / ".agents" / "skills").mkdir(parents=True)

        payload = self.add("My Project", str(spaced), ["codex"])

        self.assertEqual(payload["outcome"], "added")
        # The backend resolves the path, so /var becomes /private/var on macOS.
        self.assertEqual(
            Path(payload["changes"]["root"]), spaced.resolve(strict=False)
        )

    def test_add_rejects_a_duplicate_name(self):
        with self.assertRaises(ProjectActionError) as raised:
            self.add("Suggst", str(self.candidate), ["codex"])

        self.assertEqual(raised.exception.code, "project_exists")
        self.assertEqual(raised.exception.write_state, "no_changes")

    def test_add_rejects_a_duplicate_root(self):
        with self.assertRaises(ProjectActionError) as raised:
            self.add("Another", str(self.fixture.project_root), ["codex"])

        self.assertEqual(raised.exception.code, "project_exists")

    def test_add_rejects_an_empty_name(self):
        with self.assertRaises(ProjectActionError) as raised:
            self.add("   ", str(self.candidate), ["codex"])

        self.assertEqual(raised.exception.code, "invalid_name")

    def test_add_rejects_a_name_with_a_path_separator(self):
        with self.assertRaises(ProjectActionError) as raised:
            self.add("a/b", str(self.candidate), ["codex"])

        self.assertEqual(raised.exception.code, "invalid_name")

    def test_add_rejects_invalid_targets(self):
        with self.assertRaises(ProjectActionError) as raised:
            self.add("NewProject", str(self.candidate), ["bogus"])

        self.assertEqual(raised.exception.code, "invalid_targets")

    def test_failed_add_leaves_the_registry_untouched(self):
        self.fixture.write_configs()
        before = self.fixture.registry_path.read_bytes()

        with self.assertRaises(ProjectActionError):
            self.add("Suggst", str(self.candidate), ["codex"])

        self.assertEqual(self.fixture.registry_path.read_bytes(), before)

    def test_added_project_is_immediately_scannable(self):
        self.add("NewProject", str(self.candidate), ["codex"])

        from scripts.project_skills import list_projects

        names = [project["name"] for project in list_projects(self.fixture.registry)]
        self.assertIn("NewProject", names)
