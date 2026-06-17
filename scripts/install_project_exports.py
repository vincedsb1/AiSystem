#!/usr/bin/env python3

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.sync_skills import (
    load_yaml,
    normalize_shared_targets,
    project_shared_targets,
    registry_shared_exports,
    sync_export,
)


DEFAULT_MANIFEST = "/Users/vincentdesbrosses/Documents/Misc/ai-system/skills-manifest.yml"
DEFAULT_REGISTRY = "/Users/vincentdesbrosses/Documents/Misc/ai-system/skills-registry.yml"


def find_project(registry: dict[str, Any], project_name: str) -> dict[str, Any] | None:
    for project in registry.get("projects", []):
        if project.get("name") == project_name and project.get("enabled"):
            return project
    return None


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Install shared Claude/Codex exports for a single project.",
    )
    parser.add_argument("--project", required=True)
    parser.add_argument("--targets", nargs="+", default=["both"])
    parser.add_argument("--manifest", default=DEFAULT_MANIFEST)
    parser.add_argument("--registry", default=DEFAULT_REGISTRY)
    parser.add_argument("--no-backup", action="store_true")
    parser.add_argument("--diff", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    registry = load_yaml(Path(args.registry))
    manifest = load_yaml(Path(args.manifest))
    project = find_project(registry, args.project)

    if not project:
        print(f"AI Project Export Install — FAIL")
        print(f"  project={args.project}")
        print("  message=Project not found or not enabled")
        return 1

    requested_targets = normalize_shared_targets(args.targets) or {"codex"}
    allowed_targets = project_shared_targets(project)

    unsupported = requested_targets - allowed_targets
    if unsupported:
        print("AI Project Export Install — FAIL")
        print(f"  project={args.project}")
        print(
            "  message="
            f"Requested targets not allowed for {args.project}: "
            f"{', '.join(sorted(unsupported))}"
        )
        return 1

    exports, errors = registry_shared_exports(
        registry,
        manifest,
        project_name=args.project,
        targets=requested_targets,
    )

    if errors:
        print("AI Project Export Install — FAIL")
        for error in errors:
            print(
                "  error="
                f"{error.get('message', '')}"
                f" path={error.get('path', '')}"
            )
        return 1

    if args.dry_run:
        print("AI Project Export Install — OK")
        for export in exports:
            print(
                f"  would_update {export['target']} {export['path']} "
                f"({export['canonical_id']})"
            )
        return 0

    results: list[dict[str, Any]] = []
    for export in exports:
        artifact = export["artifact"]
        result = sync_export(
            canonical_path=Path(artifact["source_of_truth"]),
            export_path=Path(export["path"]),
            name=artifact["name"],
            description=artifact.get("description") or "",
            apply=True,
            backup=not args.no_backup,
            show_diff=args.diff,
        )
        result["canonical_id"] = export["canonical_id"]
        result["target"] = export["target"]
        result["project"] = export["project"]
        results.append(result)

    status = "FAIL" if any(result["status"] == "error" for result in results) else "OK"
    print(f"AI Project Export Install — {status}")
    print(f"  project={args.project}")
    print(f"  targets={','.join(sorted(requested_targets))}")
    for result in results:
        print(
            "{status}: {canonical_id} -> {target} :: {path} :: {message}".format(
                status=result.get("status"),
                canonical_id=result.get("canonical_id", ""),
                target=result.get("target", ""),
                path=result.get("path", ""),
                message=result.get("message", ""),
            )
        )
        if result.get("diff"):
            print(result["diff"])

    return 1 if status == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
