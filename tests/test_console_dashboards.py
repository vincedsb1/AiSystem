import io
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from scripts.ai_doctor import (
    classify_line,
    dashboard_results,
    doctor_status,
    print_doctor_dashboard,
    truncate_finding_text,
)
from scripts.ai_inventory import inventory_status, print_inventory_dashboard


class InventoryDashboardTests(unittest.TestCase):
    def test_status_uses_issue_severity(self):
        self.assertEqual(
            inventory_status({"issues_count": 0, "issues": []}),
            "OK",
        )
        self.assertEqual(
            inventory_status({
                "issues_count": 1,
                "issues": [{"severity": "warning"}],
            }),
            "WARN",
        )
        self.assertEqual(
            inventory_status({
                "issues_count": 1,
                "issues": [{"severity": "error"}],
            }),
            "FAIL",
        )

    def test_dashboard_shows_projects_pairing_and_relative_reports(self):
        report = {
            "summary": {
                "issues_count": 1,
                "issues": [{
                    "severity": "warning",
                    "project": "InterviewOS",
                    "code": "missing_frontmatter",
                    "path": ".claude/commands/example.md",
                }],
                "projects": {
                    "InterviewOS": {
                        "artifacts": 3,
                        "issues": 1,
                        "claude_commands": 1,
                        "codex_skills": 0,
                        "claude_rules": 1,
                        "claude_hooks": 0,
                        "codex_hooks": 0,
                        "root_docs": 1,
                    },
                },
                "pair_counts": {"missing_codex_skill": 1},
            },
            "pairs": [{
                "project": "InterviewOS",
                "name": "example",
                "issue": "missing_codex_skill",
                "claude_path": ".claude/commands/example.md",
                "codex_path": None,
            }],
        }
        output = io.StringIO()

        with redirect_stdout(output):
            print_inventory_dashboard(
                report,
                json_path=Path.cwd() / "reports/inventory.json",
                markdown_path=Path.cwd() / "reports/inventory.md",
            )

        rendered = output.getvalue()
        self.assertIn("AI Inventory — WARN", rendered)
        self.assertIn("InterviewOS", rendered)
        self.assertIn("missing_codex_skill", rendered)
        self.assertIn("reports/inventory.md", rendered)


class DoctorDashboardTests(unittest.TestCase):
    def test_status_and_truncation(self):
        self.assertEqual(doctor_status({"danger": 1, "review": 0}), "FAIL")
        self.assertEqual(doctor_status({"danger": 0, "review": 1}), "WARN")
        self.assertEqual(doctor_status({"danger": 0, "review": 0}), "OK")
        self.assertEqual(len(truncate_finding_text("x" * 120)), 100)
        self.assertEqual(
            classify_line(
                "Si absent, chercher la page marketing principale du projet."
            ),
            "acceptable",
        )
        self.assertEqual(
            classify_line(
                "Cascade fallback : options persona DB > options génériques DB."
            ),
            "acceptable",
        )
        self.assertEqual(
            classify_line('Le template par défaut "SaaS Standard" a 4 sections.'),
            "acceptable",
        )
        self.assertEqual(
            classify_line(
                "Fallback hérité : extraction du handle depuis l'URL si "
                "disponible. Si aucun handle n'est présent, conserver Unknown."
            ),
            "acceptable",
        )
        self.assertEqual(
            classify_line(
                "Fallback chain : local → Gemini → MiniMax. "
                "AllProvidersFailedError si tout échoue."
            ),
            "acceptable",
        )
        self.assertEqual(
            classify_line("Si aucun résultat n'existe, appliquer par défaut."),
            "danger",
        )

    def test_all_dangers_remain_visible_past_limit(self):
        results = [
            {"classification": "danger", "artifact": str(index)}
            for index in range(3)
        ] + [
            {"classification": "review", "artifact": "review"}
        ]

        visible, hidden = dashboard_results(results, max_findings=2)

        self.assertEqual(len(visible), 3)
        self.assertTrue(
            all(result["classification"] == "danger" for result in visible)
        )
        self.assertEqual(hidden, 1)

    def test_dashboard_groups_project_and_artifact(self):
        results = [{
            "classification": "danger",
            "project": "InterviewOS",
            "artifact": "update-strategy",
            "inventory_path": ".claude/commands/update-strategy.md",
            "line": 126,
            "pattern": "fallback",
            "text": "Fallback _next_minor_ver(STRATEGY_VERSION_actuel)",
        }]
        summary = {"danger": 1, "review": 0, "acceptable": 7}
        output = io.StringIO()

        with redirect_stdout(output):
            print_doctor_dashboard(
                results,
                summary,
                max_findings=20,
                markdown_path=Path.cwd() / "reports/doctor.md",
                json_path=Path.cwd() / "reports/doctor.json",
            )

        rendered = output.getvalue()
        self.assertIn("AI Doctor — FAIL", rendered)
        self.assertIn("InterviewOS", rendered)
        self.assertIn(".claude/commands/update-strategy.md", rendered)
        self.assertIn(
            "line 126 | fallback | Fallback _next_minor_ver",
            rendered,
        )
        self.assertNotIn("/Users/", rendered)


if __name__ == "__main__":
    unittest.main()
