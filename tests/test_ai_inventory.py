import tempfile
import unittest
from pathlib import Path

from scripts.ai_inventory import (
    build_pairs,
    expected_shared_codex_exports,
    summarize,
    validate_manifest_exports,
)


def artifact(
    artifact_type,
    project,
    name,
    canonical_id=None,
    scope=None,
):
    return {
        "artifact_type": artifact_type,
        "project": project,
        "name": name,
        "normalized_name": name,
        "active": True,
        "path": f"{project}/{name}",
        "version": "1.0.0" if canonical_id else None,
        "canonical_id": canonical_id,
        "scope": scope,
        "source_of_truth": canonical_id,
        "manifest_found": bool(canonical_id),
        "sha256": project,
        "issues": [],
    }


class ProjectAwarePairingTests(unittest.TestCase):
    def test_same_name_is_paired_within_project(self):
        artifacts = [
            artifact(
                "claude_command",
                "aimoto",
                "analyse-signal",
                "aimoto.analyse-signal",
                "project",
            ),
            artifact(
                "codex_skill",
                "aimoto",
                "analyse-signal",
                "aimoto.analyse-signal",
                "project",
            ),
            artifact("claude_command", "InterviewOS", "analyse-signal"),
        ]

        pairs = build_pairs(artifacts)

        self.assertEqual(
            [
                (pair["project"], pair["issue"])
                for pair in pairs
            ],
            [
                ("InterviewOS", "missing_codex_skill"),
                ("aimoto", "ok_same_canonical"),
            ],
        )

    def test_cross_project_pairing_requires_shared_metadata_on_both_sides(self):
        artifacts = [
            artifact(
                "claude_command",
                "InterviewOS",
                "implement",
                "shared.implement",
                "shared",
            ),
            artifact(
                "codex_skill",
                "aimoto",
                "implement",
                "shared.implement",
                "shared",
            ),
        ]

        pairs = build_pairs(artifacts)

        self.assertEqual(len(pairs), 2)
        self.assertTrue(
            all(pair["issue"] == "ok_same_canonical" for pair in pairs)
        )
        self.assertEqual(pairs[0]["codex_project"], "aimoto")
        self.assertEqual(pairs[1]["claude_project"], "InterviewOS")

    def test_project_claude_only_exception_changes_missing_status(self):
        artifacts = [
            artifact("claude_command", "Pylaa", "data-slot-add"),
        ]
        registry = {
            "pairing_exceptions": [{
                "project": "Pylaa",
                "artifact_type": "claude_command",
                "name": "data-slot-add",
                "expected_status": "claude_only_project_command",
                "reason": "Project command.",
            }],
        }

        pair = build_pairs(artifacts, registry)[0]

        self.assertEqual(pair["raw_issue"], "missing_codex_skill")
        self.assertEqual(pair["issue"], "expected_claude_only")
        self.assertEqual(pair["exception_reason"], "Project command.")

    def test_exception_does_not_apply_to_shared_artifact(self):
        artifacts = [
            artifact(
                "claude_command",
                "Pylaa",
                "implement",
                "shared.implement",
                "shared",
            ),
        ]
        registry = {
            "pairing_exceptions": [{
                "project": "Pylaa",
                "artifact_type": "claude_command",
                "name": "implement",
                "expected_status": "claude_only_project_command",
            }],
        }

        pair = build_pairs(artifacts, registry)[0]

        self.assertEqual(pair["issue"], "missing_codex_skill")

    def test_exception_never_masks_drift(self):
        artifacts = [
            artifact(
                "claude_command",
                "Pylaa",
                "custom",
                "pylaa.custom",
                "project",
            ),
            artifact(
                "codex_skill",
                "Pylaa",
                "custom",
                "pylaa.other",
                "project",
            ),
        ]
        registry = {
            "pairing_exceptions": [{
                "project": "Pylaa",
                "artifact_type": "claude_command",
                "name": "custom",
                "expected_status": "claude_only_project_command",
            }],
        }

        pair = build_pairs(artifacts, registry)[0]

        self.assertEqual(pair["issue"], "drift_canonical_id_mismatch")

    def test_project_summary_counts_artifacts_and_issues(self):
        artifacts = [
            artifact("claude_command", "InterviewOS", "analyse-signal"),
            artifact(
                "codex_skill",
                "aimoto",
                "analyse-signal",
                "aimoto.analyse-signal",
                "project",
            ),
        ]
        pairs = build_pairs(artifacts)

        summary = summarize(
            artifacts,
            pairs,
            [],
            ["aimoto", "InterviewOS"],
        )

        self.assertEqual(summary["projects"]["aimoto"]["codex_skills"], 1)
        self.assertEqual(summary["projects"]["InterviewOS"]["claude_commands"], 1)
        self.assertEqual(summary["projects"]["InterviewOS"]["artifacts"], 1)
        self.assertEqual(summary["projects"]["InterviewOS"]["issues"], 1)
        self.assertEqual(summary["projects"]["aimoto"]["issues"], 1)

    def test_missing_registered_shared_skill_is_reported_for_project(self):
        with tempfile.TemporaryDirectory() as directory:
            registry = {
                "projects": [{
                    "name": "InterviewOS",
                    "root": directory,
                    "enabled": True,
                    "install_shared_skills": ["shared.implement"],
                    "paths": {"codex_skills": ".agents/skills"},
                }],
            }
            manifest = {
                "artifacts": [{
                    "canonical_id": "shared.implement",
                    "name": "implement",
                    "version": "1.0.0",
                    "scope": "shared",
                    "compatibility": {"codex": True},
                }],
            }

            exports = expected_shared_codex_exports(registry, manifest)
            issues = validate_manifest_exports(exports)

            self.assertEqual(len(issues), 1)
            self.assertEqual(issues[0]["project"], "InterviewOS")
            self.assertEqual(issues[0]["code"], "manifest_export_missing")
            self.assertEqual(
                Path(issues[0]["path"]),
                Path(directory) / ".agents/skills/implement/SKILL.md",
            )


if __name__ == "__main__":
    unittest.main()
