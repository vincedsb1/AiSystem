#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


DEFAULT_INVENTORY = "reports/ai-inventory.latest.json"
DEFAULT_DOCTOR = "reports/ai-doctor.latest.json"


def load_json(path: Path) -> dict[str, Any]:
    loaded = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(loaded, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return loaded


def validate_reports(
    inventory: dict[str, Any],
    doctor: dict[str, Any],
) -> tuple[list[str], dict[str, int]]:
    inventory_summary = inventory.get("summary", {})
    doctor_summary = doctor.get("summary", {})
    doctor_raw = doctor_summary.get("raw", doctor_summary)

    classification_counts = inventory_summary.get("classification_counts", {})
    pair_counts = inventory_summary.get("pair_counts", {})
    counts = inventory_summary.get("counts", {})

    action_required = int(classification_counts.get("action_required", 0))
    accepted_findings = int(classification_counts.get("accepted_findings", 0))
    expected_exceptions = int(classification_counts.get("expected_exceptions", 0))
    doctor_danger = int(doctor_raw.get("danger", 0))
    doctor_review = int(doctor_raw.get("review", 0))
    missing_codex = int(pair_counts.get("missing_codex_skill", 0))
    missing_claude = int(pair_counts.get("missing_claude_command", 0))
    semantic_review = int(pair_counts.get("semantic_review_needed", 0))
    manifest_missing = int(counts.get("manifest_missing_exports", 0))
    drift_count = sum(
        int(value)
        for status, value in pair_counts.items()
        if str(status).startswith("drift_")
    )

    metrics = {
        "action_required": action_required,
        "accepted_findings": accepted_findings,
        "expected_exceptions": expected_exceptions,
        "doctor_danger": doctor_danger,
        "doctor_review": doctor_review,
        "missing_codex_skill": missing_codex,
        "missing_claude_command": missing_claude,
        "semantic_review_needed": semantic_review,
        "drift": drift_count,
        "manifest_missing_exports": manifest_missing,
    }

    failures: list[str] = []
    required_zero = {
        "action_required": action_required,
        "doctor danger": doctor_danger,
        "doctor review": doctor_review,
        "missing_codex_skill": missing_codex,
        "missing_claude_command": missing_claude,
        "semantic_review_needed": semantic_review,
        "drift_*": drift_count,
        "manifest_missing_exports": manifest_missing,
    }
    for label, value in required_zero.items():
        if value > 0:
            failures.append(f"{label}={value}")

    return failures, metrics


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate the generated AI Inventory and AI Doctor reports.",
    )
    parser.add_argument("--inventory", default=DEFAULT_INVENTORY)
    parser.add_argument("--doctor", default=DEFAULT_DOCTOR)
    args = parser.parse_args()

    try:
        inventory = load_json(Path(args.inventory))
        doctor = load_json(Path(args.doctor))
        failures, metrics = validate_reports(inventory, doctor)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print("AI System Check — FAIL")
        print(f"  report_error={exc}")
        return 1

    status = "FAIL" if failures else "OK"
    print(f"AI System Check — {status}")
    print(
        "  Inventory"
        f"  action_required={metrics['action_required']}"
        f"  accepted_findings={metrics['accepted_findings']}"
        f"  expected_exceptions={metrics['expected_exceptions']}"
    )
    print(
        "  Pairing"
        f"  missing_codex_skill={metrics['missing_codex_skill']}"
        f"  missing_claude_command={metrics['missing_claude_command']}"
        f"  semantic_review_needed={metrics['semantic_review_needed']}"
        f"  drift_*={metrics['drift']}"
    )
    print(
        "  Doctor"
        f"  danger={metrics['doctor_danger']}"
        f"  review={metrics['doctor_review']}"
    )
    print(
        "  Manifest"
        f"  missing_exports={metrics['manifest_missing_exports']}"
    )

    if failures:
        print("  Failures  " + ", ".join(failures))
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
