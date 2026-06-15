import unittest

from scripts.check_ai_system import validate_reports


def healthy_inventory():
    return {
        "summary": {
            "classification_counts": {
                "action_required": 0,
                "accepted_findings": 206,
                "expected_exceptions": 30,
            },
            "pair_counts": {
                "ok_same_canonical": 139,
                "expected_claude_only": 30,
            },
            "counts": {
                "manifest_missing_exports": 0,
            },
        },
    }


def healthy_doctor():
    return {
        "summary": {
            "raw": {
                "danger": 0,
                "review": 0,
                "acceptable": 373,
            },
        },
    }


class CheckAiSystemTests(unittest.TestCase):
    def test_healthy_reports_pass(self):
        failures, metrics = validate_reports(
            healthy_inventory(),
            healthy_doctor(),
        )

        self.assertEqual(failures, [])
        self.assertEqual(metrics["accepted_findings"], 206)
        self.assertEqual(metrics["expected_exceptions"], 30)

    def test_each_blocking_metric_fails(self):
        cases = [
            ("action_required", "classification_counts"),
            ("missing_codex_skill", "pair_counts"),
            ("missing_claude_command", "pair_counts"),
            ("semantic_review_needed", "pair_counts"),
            ("drift_version_mismatch", "pair_counts"),
            ("manifest_missing_exports", "counts"),
        ]

        for metric, section in cases:
            with self.subTest(metric=metric):
                inventory = healthy_inventory()
                inventory["summary"][section][metric] = 1
                failures, _ = validate_reports(inventory, healthy_doctor())
                self.assertTrue(failures)

    def test_doctor_danger_and_review_fail(self):
        for metric in ("danger", "review"):
            with self.subTest(metric=metric):
                doctor = healthy_doctor()
                doctor["summary"]["raw"][metric] = 1
                failures, _ = validate_reports(healthy_inventory(), doctor)
                self.assertTrue(failures)


if __name__ == "__main__":
    unittest.main()
