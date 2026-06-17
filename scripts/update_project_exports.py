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


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Update shared Claude/Codex exports for all enabled projects.",
    )
    parser.add_argument("--targets", nargs="+", default=["both"])
    parser.add_argument("--manifest", default=DEFAULT_MANIFEST)
    parser.add_argument("--registry", default=DEFAULT_REGISTRY)
    parser.add_argument("--no-backup", action="store_true")
    parser.add_argument("--diff", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    registry = load_yaml(Path(args.registry))
    manifest = load_yaml(Path(args.manifest))
    requested_targets = normalize_shared_targets(args.targets) or {"codex"}

    projects = [p for p in registry.get("projects", []) if p.get("enabled")]
    if not projects:
        print("AI Project Exports Update — FAIL")
        print("  message=No enabled projects found")
        return 1

    print(f"AI Project Exports Update — Processing {len(projects)} project(s)")
    print()

    global_status = "OK"
    for project in projects:
        project_name = project.get("name", "unknown")
        allowed_targets = project_shared_targets(project)

        # Intersect requested targets with allowed targets for this project
        effective_targets = requested_targets & allowed_targets

        if not effective_targets:
            print(f"  {project_name}")
            print(f"    targets=none (skipped, no overlap with {','.join(sorted(requested_targets))})")
            print()
            continue

        exports, errors = registry_shared_exports(
            registry,
            manifest,
            project_name=project_name,
            targets=effective_targets,
        )

        if errors:
            print(f"  {project_name}")
            print(f"    targets={','.join(sorted(effective_targets))}")
            print(f"    status=FAIL")
            for error in errors:
                print(
                    f"    error={error.get('message', '')} "
                    f"path={error.get('path', '')}"
                )
            global_status = "FAIL"
            print()
            continue

        if args.dry_run:
            print(f"  {project_name}")
            print(f"    targets={','.join(sorted(effective_targets))}")
            print(f"    status=OK (dry-run)")
            for export in exports:
                print(f"    would_update {export['target']} {export['canonical_id']}")
            print()
            continue

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
            results.append(result)

        project_status = "FAIL" if any(result["status"] == "error" for result in results) else "OK"
        if project_status == "FAIL":
            global_status = "FAIL"

        updated = sum(1 for r in results if r["status"] == "updated")
        unchanged = sum(1 for r in results if r["status"] == "unchanged")
        errored = sum(1 for r in results if r["status"] == "error")

        print(f"  {project_name}")
        print(f"    targets={','.join(sorted(effective_targets))}")
        print(f"    status={project_status}")
        print(f"    updated={updated} unchanged={unchanged} error={errored}")

        if args.diff or project_status == "FAIL":
            for result in results:
                if result.get("diff") or result.get("status") == "error":
                    print(
                        f"    {result.get('status', 'unknown')}: "
                        f"{result.get('canonical_id', '')} -> {result.get('target', '')}"
                    )
                    if result.get("message"):
                        print(f"      {result.get('message', '')}")
                    if result.get("diff"):
                        print(result["diff"])

        print()

    status_str = "FAIL" if global_status == "FAIL" else "OK"
    print(f"AI Project Exports Update — {status_str}")
    return 1 if global_status == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
