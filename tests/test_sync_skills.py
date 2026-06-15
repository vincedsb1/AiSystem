import tempfile
import unittest
from pathlib import Path

from scripts.sync_skills import (
    manifest_codex_export_policy_error,
    registry_shared_codex_exports,
)


class SharedSkillPolicyTests(unittest.TestCase):
    def test_builds_project_local_codex_export_for_shared_skill(self):
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
                    "scope": "shared",
                    "compatibility": {"codex": True},
                }],
            }

            exports, errors = registry_shared_codex_exports(registry, manifest)

            self.assertEqual(errors, [])
            self.assertEqual(len(exports), 1)
            self.assertEqual(
                exports[0]["path"],
                str(Path(directory) / ".agents/skills/implement/SKILL.md"),
            )

    def test_rejects_project_canonical_in_shared_install_policy(self):
        registry = {
            "projects": [{
                "name": "InterviewOS",
                "root": "/tmp/interviewos",
                "enabled": True,
                "install_shared_skills": ["aimoto.next"],
                "paths": {"codex_skills": ".agents/skills"},
            }],
        }
        manifest = {
            "artifacts": [{
                "canonical_id": "aimoto.next",
                "name": "next",
                "scope": "project",
                "compatibility": {"codex": True},
            }],
        }

        exports, errors = registry_shared_codex_exports(registry, manifest)

        self.assertEqual(exports, [])
        self.assertEqual(errors[0]["status"], "error")
        self.assertIn("only accepts shared.*", errors[0]["message"])

    def test_project_export_cannot_target_another_project(self):
        artifact = {
            "canonical_id": "aimoto.next",
            "scope": "project",
            "project": "aimoto",
        }
        registry = {
            "projects": [
                {"name": "aimoto", "root": "/projects/aimoto"},
                {"name": "InterviewOS", "root": "/projects/InterviewOS"},
            ],
        }

        error = manifest_codex_export_policy_error(
            artifact=artifact,
            export_path=Path("/projects/InterviewOS/.agents/skills/next/SKILL.md"),
            registry=registry,
            allowed_shared_paths=set(),
        )

        self.assertIn("must stay inside", error)

    def test_shared_codex_export_requires_registry_policy(self):
        artifact = {
            "canonical_id": "shared.implement",
            "scope": "shared",
            "project": None,
        }
        export_path = Path("/projects/InterviewOS/.agents/skills/implement/SKILL.md")

        error = manifest_codex_export_policy_error(
            artifact=artifact,
            export_path=export_path,
            registry={},
            allowed_shared_paths=set(),
        )

        self.assertIn("install_shared_skills", error)


if __name__ == "__main__":
    unittest.main()
