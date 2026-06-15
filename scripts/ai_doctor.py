#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path
from typing import Any

import yaml


DEFAULT_REGISTRY = "/Users/vincentdesbrosses/Documents/Misc/ai-system/skills-registry.yml"
DEFAULT_INVENTORY = "/Users/vincentdesbrosses/Documents/Misc/ai-system/reports/ai-inventory.latest.json"
DEFAULT_JSON_OUTPUT = "/Users/vincentdesbrosses/Documents/Misc/ai-system/reports/ai-doctor.latest.json"
DEFAULT_MARKDOWN_OUTPUT = "/Users/vincentdesbrosses/Documents/Misc/ai-system/reports/ai-doctor.latest.md"


SAFE_CONTEXT_MARKERS = [
    "blocage si absent",
    "fallback silencieux",
    "problème historique",
    "historique",
    "optimise à l'aveugle",
    "cible inconnue",
    "stagnation observée",
    "valeurs par défaut",
    "valeurs default",
    "valeurs par default",
    "test_",
    "tests snapshot",
    "golden snapshot",
    "diagnostic",
    "404",
    "à éviter",
    "a éviter",
    "ne pas",
    "jamais",
    "interdit",
    "interdire",
    "stop",
    "bloquer",
    "blocage",
    "do not",
    "never",
    "forbid",
    "forbidden",
    "must not",
    "si absent : créer une section",
    "si absent : ajouter dans",
    "si absent et qu'il existe",
    "si absent, chercher la page marketing principale",
    "read on demand, not auto-loaded",
    "diffèrent des conventions par défaut",
    "different from the language defaults",
    "cibler **180 lignes / 15 kb** par défaut",
    "pas de mock/fallback data",
    "aucune donnée mock / fallback introduite",
    "politique no-fallback",
    "toujours fournir une valeur par défaut",
    "valeur par défaut proposée",
    "bloquant → si absent/inutilisable : fail",
    "recommandé (par défaut",
    "palette tailwind par défaut",
    "slate/zinc/gray par défaut",
    "alignement grille `stretch` par défaut",
    "fallback `reduced-motion`",
    "suspense fallback",
    "états skeleton pendant ssr",
    "reads forecast artifacts from disk only; no mock or fallback data",
    "`floor_fields` ou logique d'opérateur par défaut",
    "schémas (ui/flow/états) : **bloquant** → si absent/inutilisable : fail",
    "persona_fallback_options",
    "minimax m2.5 (fallback)",
    "fallback options",
    "cascade fallback :",
    "suggested_options_fallback",
    "fallback sur originales si < 5 résultats",
    "fallback code dans `matcher.py`",
    "fallback js firefox",
    "ou le calcule via le service d'embedding si absent",
    'template par défaut "saas standard"',
]


DANGEROUS_CONTEXT_MARKERS = [
    "appliquer par défaut",
    "appliquer par default",
    "utiliser par défaut",
    "utiliser par default",
    "prendre par défaut",
    "prendre par default",
    "par défaut mmxm",
    "par default mmxm",
    "si aucune",
    "si aucun",
    "if no ",
    "if none",
    "fallback_next_minor_ver",
    "fallback `+1 minor`",
    "fallback +1 minor",
    "_next_minor_ver",
    "dernière stratégie mentionnée",
    "derniere stratégie mentionnée",
    "dernière strategie mentionnee",
    "derniere strategie mentionnee",
    "latest mentioned strategy",
    "depuis le contexte courant",
    "from current context",
]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def load_yaml(path: Path) -> dict[str, Any]:
    loaded = yaml.safe_load(read_text(path))
    return loaded if isinstance(loaded, dict) else {}


def load_json(path: Path) -> dict[str, Any]:
    loaded = json.loads(read_text(path))
    return loaded if isinstance(loaded, dict) else {}


def dump_json(data: dict[str, Any]) -> str:
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


def fallback_patterns(registry: dict[str, Any]) -> list[str]:
    patterns = registry.get("quality_rules", {}).get(
        "forbidden_silent_fallback_patterns",
        [],
    )

    return [str(pattern) for pattern in patterns if str(pattern).strip()]


def classify_line(line: str) -> str:
    lowered = line.lower()

    if any(marker in lowered for marker in DANGEROUS_CONTEXT_MARKERS):
        return "danger"

    if any(marker in lowered for marker in SAFE_CONTEXT_MARKERS):
        return "acceptable"

    return "review"


def scan_file(
    *,
    path: Path,
    patterns: list[str],
    artifact: dict[str, Any] | None = None,
) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []

    artifact = artifact or {}

    base_result = {
        "project": artifact.get("project"),
        "artifact": artifact.get("name") or path.name,
        "artifact_type": artifact.get("artifact_type"),
        "canonical_id": artifact.get("canonical_id"),
        "manifest_found": artifact.get("manifest_found"),
        "path": str(path),
        "inventory_path": artifact.get("path"),
    }

    if not path.exists():
        return [
            {
                **base_result,
                "classification": "danger",
                "line": None,
                "pattern": None,
                "text": "FILE_NOT_FOUND",
            }
        ]

    lines = read_text(path).splitlines()

    for index, line in enumerate(lines, start=1):
        lowered = line.lower()

        for pattern in patterns:
            if pattern.lower() in lowered:
                results.append(
                    {
                        **base_result,
                        "classification": classify_line(line),
                        "line": index,
                        "pattern": pattern,
                        "text": line.strip(),
                    }
                )

    return results


def active_inventory_artifacts(inventory: dict[str, Any]) -> list[dict[str, Any]]:
    artifacts = inventory.get("artifacts", [])

    if not isinstance(artifacts, list):
        return []

    active: list[dict[str, Any]] = []

    for artifact in artifacts:
        if not isinstance(artifact, dict):
            continue

        if not artifact.get("active", False):
            continue

        if not artifact.get("exists", False):
            continue

        absolute_path = artifact.get("absolute_path")

        if not absolute_path:
            continue

        active.append(artifact)

    return active


def scan_inventory(
    *,
    inventory_path: Path,
    patterns: list[str],
    dedupe_paths: bool,
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    inventory = load_json(inventory_path)
    artifacts = active_inventory_artifacts(inventory)

    results: list[dict[str, Any]] = []
    seen_paths: set[str] = set()

    for artifact in artifacts:
        absolute_path = str(artifact["absolute_path"])

        if dedupe_paths:
            realpath = str(artifact.get("realpath") or absolute_path)
            dedupe_key = realpath
        else:
            dedupe_key = absolute_path

        if dedupe_key in seen_paths:
            continue

        seen_paths.add(dedupe_key)

        results.extend(
            scan_file(
                path=Path(absolute_path),
                patterns=patterns,
                artifact=artifact,
            )
        )

    return inventory, results


def summarize_results(results: list[dict[str, Any]]) -> dict[str, Any]:
    by_classification = Counter(result["classification"] for result in results)
    by_artifact_type = Counter(
        result.get("artifact_type") or "unknown"
        for result in results
    )
    by_pattern = Counter(result.get("pattern") or "unknown" for result in results)

    by_artifact: dict[str, Counter[str]] = defaultdict(Counter)

    for result in results:
        artifact_key = "{artifact_type}:{artifact}".format(
            artifact_type=result.get("artifact_type") or "unknown",
            artifact=result.get("artifact") or "unknown",
        )
        by_artifact[artifact_key][result["classification"]] += 1

    return {
        "total": len(results),
        "danger": by_classification.get("danger", 0),
        "review": by_classification.get("review", 0),
        "acceptable": by_classification.get("acceptable", 0),
        "by_artifact_type": dict(sorted(by_artifact_type.items())),
        "by_pattern": dict(sorted(by_pattern.items())),
        "by_artifact": {
            key: dict(value)
            for key, value in sorted(by_artifact.items())
        },
    }


def filter_results(
    results: list[dict[str, Any]],
    *,
    only_danger: bool,
    include_acceptable: bool,
) -> list[dict[str, Any]]:
    filtered = results

    if only_danger:
        filtered = [
            result
            for result in filtered
            if result["classification"] == "danger"
        ]

    if not include_acceptable:
        filtered = [
            result
            for result in filtered
            if result["classification"] != "acceptable"
        ]

    return filtered


def render_markdown_report(
    *,
    generated_at: str,
    registry_path: Path,
    inventory_path: Path | None,
    json_output_path: Path | None,
    results: list[dict[str, Any]],
    summary: dict[str, Any],
) -> str:
    lines: list[str] = []

    lines.append("# AI Doctor Report")
    lines.append("")
    lines.append(f"Generated: {generated_at}")
    lines.append("")
    lines.append("## Inputs")
    lines.append("")
    lines.append(f"- Registry: `{registry_path}`")

    if inventory_path:
        lines.append(f"- Inventory: `{inventory_path}`")

    if json_output_path:
        lines.append(f"- JSON output: `{json_output_path}`")

    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append("| Metric | Count |")
    lines.append("|---|---:|")
    lines.append(f"| total | {summary['total']} |")
    lines.append(f"| danger | {summary['danger']} |")
    lines.append(f"| review | {summary['review']} |")
    lines.append(f"| acceptable | {summary['acceptable']} |")
    lines.append("")

    lines.append("## By artifact type")
    lines.append("")
    lines.append("| Artifact type | Count |")
    lines.append("|---|---:|")

    for artifact_type, count in summary["by_artifact_type"].items():
        lines.append(f"| {artifact_type} | {count} |")

    lines.append("")

    lines.append("## By pattern")
    lines.append("")
    lines.append("| Pattern | Count |")
    lines.append("|---|---:|")

    for pattern, count in summary["by_pattern"].items():
        lines.append(f"| `{pattern}` | {count} |")

    lines.append("")

    lines.append("## Findings")
    lines.append("")

    if not results:
        lines.append("No finding.")
        lines.append("")
        return "\n".join(lines)

    lines.append("| Classification | Artifact | Type | Pattern | Location | Text |")
    lines.append("|---|---|---|---|---|---|")

    for result in results:
        classification = result["classification"].upper()
        artifact = escape_md_cell(str(result.get("artifact") or ""))
        artifact_type = escape_md_cell(str(result.get("artifact_type") or ""))
        pattern = escape_md_cell(f"`{result.get('pattern')}`")
        line = result.get("line")
        path = result.get("inventory_path") or result.get("path") or ""
        location = escape_md_cell(f"{path}:{line}" if line else str(path))
        text = escape_md_cell(str(result.get("text") or ""))

        lines.append(
            f"| {classification} | {artifact} | {artifact_type} | {pattern} | {location} | {text} |"
        )

    lines.append("")
    return "\n".join(lines)


def escape_md_cell(value: str) -> str:
    return (
        value
        .replace("\\", "\\\\")
        .replace("|", "\\|")
        .replace("\n", " ")
    )


def build_report_payload(
    *,
    generated_at: str,
    registry_path: Path,
    inventory_path: Path | None,
    results: list[dict[str, Any]],
    raw_results: list[dict[str, Any]],
    summary: dict[str, Any],
) -> dict[str, Any]:
    return {
        "generated_at": generated_at,
        "registry": str(registry_path),
        "inventory": str(inventory_path) if inventory_path else None,
        "summary": summary,
        "findings": results,
        "raw_findings_count": len(raw_results),
    }


def print_plain_results(results: list[dict[str, Any]], summary: dict[str, Any]) -> None:
    print(
        "Summary: danger={danger}, review={review}, acceptable={acceptable}".format(
            danger=summary["danger"],
            review=summary["review"],
            acceptable=summary["acceptable"],
        )
    )

    if not results:
        print("OK: no matching fallback candidate found")
        return

    for result in results:
        print(
            "{classification}: {path}:{line}: [{pattern}] {text}".format(
                classification=result["classification"].upper(),
                path=result.get("path"),
                line=result.get("line"),
                pattern=result.get("pattern"),
                text=result.get("text"),
            )
        )


def console_path(path: Path) -> str:
    try:
        return str(path.relative_to(Path.cwd()))
    except ValueError:
        return str(path)


def truncate_finding_text(value: str, limit: int = 100) -> str:
    compact = " ".join(value.split())
    if len(compact) <= limit:
        return compact
    return compact[: limit - 3].rstrip() + "..."


def doctor_status(summary: dict[str, Any]) -> str:
    if summary["danger"] > 0:
        return "FAIL"
    if summary["review"] > 0:
        return "WARN"
    return "OK"


def dashboard_results(
    results: list[dict[str, Any]],
    max_findings: int,
) -> tuple[list[dict[str, Any]], int]:
    visible_candidates = [
        result
        for result in results
        if result["classification"] != "acceptable"
    ]
    dangers = [
        result
        for result in visible_candidates
        if result["classification"] == "danger"
    ]
    other_findings = [
        result
        for result in visible_candidates
        if result["classification"] != "danger"
    ]
    remaining_slots = max(max_findings - len(dangers), 0)
    visible = dangers + other_findings[:remaining_slots]
    dangerous_artifacts = {
        (
            str(result.get("project") or "standalone"),
            str(result.get("artifact") or "unknown"),
        )
        for result in visible
        if result["classification"] == "danger"
    }
    visible.sort(
        key=lambda result: (
            str(result.get("project") or "standalone"),
            0
            if (
                str(result.get("project") or "standalone"),
                str(result.get("artifact") or "unknown"),
            ) in dangerous_artifacts
            else 1,
            str(result.get("artifact") or "unknown"),
            0 if result["classification"] == "danger" else 1,
            result.get("line") or 0,
        )
    )
    return visible, len(visible_candidates) - len(visible)


def print_doctor_dashboard(
    results: list[dict[str, Any]],
    summary: dict[str, Any],
    *,
    max_findings: int,
    markdown_path: Path | None,
    json_path: Path | None,
) -> None:
    visible, hidden_count = dashboard_results(results, max_findings)

    print(f"AI Doctor — {doctor_status(summary)}")
    print()
    print(
        "Summary"
        f"  danger={summary['danger']}"
        f"  review={summary['review']}"
        f"  acceptable hidden={summary['acceptable']}"
    )

    if visible:
        print()
        print("Findings")
        current_project = None
        current_artifact = None
        for result in visible:
            project = str(result.get("project") or "standalone")
            artifact = str(result.get("artifact") or "unknown")
            path = str(
                result.get("inventory_path")
                or result.get("path")
                or ""
            )

            if project != current_project:
                current_project = project
                current_artifact = None
                print(f"  {project}")

            artifact_key = (artifact, path)
            if artifact_key != current_artifact:
                current_artifact = artifact_key
                print(f"    {artifact}  {path}")

            line = result.get("line")
            line_label = f"line {line}" if line else "line ?"
            pattern = result.get("pattern") or "unknown"
            text = truncate_finding_text(str(result.get("text") or ""))
            print(f"      {line_label} | {pattern} | {text}")
    else:
        print()
        print("Findings")
        print("  No danger or review finding.")

    if hidden_count > 0:
        report_path = (
            console_path(markdown_path)
            if markdown_path
            else "the Markdown report"
        )
        print()
        print(f"... {hidden_count} more findings. See {report_path}")

    if markdown_path or json_path:
        print()
        print("Reports")
        if markdown_path:
            print(f"  Markdown  {console_path(markdown_path)}")
        if json_path:
            print(f"  JSON      {console_path(json_path)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--registry", default=DEFAULT_REGISTRY)

    source_group = parser.add_mutually_exclusive_group(required=True)
    source_group.add_argument(
        "--file",
        help="Single file to scan, e.g. /Users/.../.claude/commands/update-strategy.md",
    )
    source_group.add_argument(
        "--inventory",
        nargs="?",
        const=DEFAULT_INVENTORY,
        help="Inventory JSON to scan. Defaults to reports/ai-inventory.latest.json.",
    )

    parser.add_argument(
        "--json-output",
        default=None,
        help="Write JSON report. With --inventory, defaults to reports/ai-doctor.latest.json.",
    )
    parser.add_argument(
        "--markdown-output",
        default=None,
        help="Write Markdown report. With --inventory, defaults to reports/ai-doctor.latest.md.",
    )
    parser.add_argument(
        "--only-danger",
        action="store_true",
        help="Only print/write dangerous candidates.",
    )
    parser.add_argument(
        "--include-acceptable",
        action="store_true",
        help="Include acceptable findings in printed/written findings.",
    )
    parser.add_argument(
        "--dedupe-paths",
        action="store_true",
        help="When using --inventory, scan each realpath once.",
    )
    parser.add_argument(
        "--plain",
        action="store_true",
        help="Use the legacy line-by-line console output.",
    )
    parser.add_argument(
        "--max-findings",
        type=int,
        default=20,
        metavar="N",
        help="Maximum dashboard findings to show (all dangers are always shown).",
    )

    args = parser.parse_args()
    if args.max_findings < 0:
        parser.error("--max-findings must be >= 0")

    registry_path = Path(args.registry)
    registry = load_yaml(registry_path)
    patterns = fallback_patterns(registry)

    generated_at = datetime.now().isoformat(timespec="seconds")

    inventory_path: Path | None = None

    if args.file:
        raw_results = scan_file(
            path=Path(args.file),
            patterns=patterns,
        )
    else:
        inventory_path = Path(args.inventory)
        _, raw_results = scan_inventory(
            inventory_path=inventory_path,
            patterns=patterns,
            dedupe_paths=args.dedupe_paths,
        )

    raw_summary = summarize_results(raw_results)

    results = filter_results(
        raw_results,
        only_danger=args.only_danger,
        include_acceptable=args.include_acceptable,
    )

    filtered_summary = summarize_results(results)

    json_output: Path | None = None
    markdown_output: Path | None = None

    if args.json_output:
        json_output = Path(args.json_output)
    elif args.inventory:
        json_output = Path(DEFAULT_JSON_OUTPUT)

    if args.markdown_output:
        markdown_output = Path(args.markdown_output)
    elif args.inventory:
        markdown_output = Path(DEFAULT_MARKDOWN_OUTPUT)

    payload = build_report_payload(
        generated_at=generated_at,
        registry_path=registry_path,
        inventory_path=inventory_path,
        results=results,
        raw_results=raw_results,
        summary={
            **filtered_summary,
            "raw": raw_summary,
        },
    )

    if json_output:
        write_text(json_output, dump_json(payload))

    if markdown_output:
        markdown = render_markdown_report(
            generated_at=generated_at,
            registry_path=registry_path,
            inventory_path=inventory_path,
            json_output_path=json_output,
            results=results,
            summary={
                **filtered_summary,
                "raw": raw_summary,
            },
        )
        write_text(markdown_output, markdown + "\n")

    # Console status reflects the raw classification state even when reports
    # filter acceptable findings or only include dangers.
    if args.plain:
        print_plain_results(results, raw_summary)
        if json_output:
            print(f"JSON report: {json_output}")
        if markdown_output:
            print(f"Markdown report: {markdown_output}")
    else:
        print_doctor_dashboard(
            results,
            raw_summary,
            max_findings=args.max_findings,
            markdown_path=markdown_output,
            json_path=json_output,
        )

    if raw_summary["danger"] > 0:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
