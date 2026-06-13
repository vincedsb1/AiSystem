#!/usr/bin/env python3

from __future__ import annotations

import argparse
import difflib
import shutil
from pathlib import Path
from typing import Any

import yaml


DEFAULT_MANIFEST = "/Users/vincentdesbrosses/Documents/Misc/ai-system/skills-manifest.yml"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def write_text(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def load_yaml(path: Path) -> dict[str, Any]:
    loaded = yaml.safe_load(read_text(path))
    return loaded if isinstance(loaded, dict) else {}


def split_frontmatter(content: str) -> tuple[dict[str, Any] | None, str]:
    if not content.startswith("---\n"):
        return None, content

    parts = content.split("---", 2)
    if len(parts) < 3:
        return None, content

    raw = parts[1].strip()
    body = parts[2].lstrip("\n")

    if not raw:
        return {}, body

    parsed = yaml.safe_load(raw)
    return parsed if isinstance(parsed, dict) else {}, body


def build_runtime_frontmatter(name: str, description: str) -> str:
    data = {
        "name": name,
        "description": description,
    }

    return "---\n" + yaml.safe_dump(
        data,
        sort_keys=False,
        allow_unicode=True,
        width=120,
    ) + "---\n\n"


def canonical_body(path: Path) -> str:
    content = read_text(path)
    _, body = split_frontmatter(content)
    return body.rstrip() + "\n"


def build_export_content(
    *,
    canonical_path: Path,
    name: str,
    description: str,
) -> str:
    return build_runtime_frontmatter(name, description) + canonical_body(canonical_path)


def unified_diff(old: str, new: str, fromfile: str, tofile: str) -> str:
    return "".join(
        difflib.unified_diff(
            old.splitlines(keepends=True),
            new.splitlines(keepends=True),
            fromfile=fromfile,
            tofile=tofile,
        )
    )


def sync_export(
    *,
    canonical_path: Path,
    export_path: Path,
    name: str,
    description: str,
    apply: bool,
    backup: bool,
    show_diff: bool,
) -> dict[str, Any]:
    if not canonical_path.exists():
        return {
            "status": "error",
            "path": str(export_path),
            "message": f"Canonical source missing: {canonical_path}",
        }

    new_content = build_export_content(
        canonical_path=canonical_path,
        name=name,
        description=description,
    )

    old_content = read_text(export_path) if export_path.exists() else ""

    if old_content == new_content:
        return {
            "status": "unchanged",
            "path": str(export_path),
            "message": "No change",
        }

    diff = unified_diff(
        old_content,
        new_content,
        fromfile=str(export_path),
        tofile=str(export_path),
    )

    if not apply:
        return {
            "status": "would_update",
            "path": str(export_path),
            "message": "Would update",
            "diff": diff if show_diff else None,
        }

    export_path.parent.mkdir(parents=True, exist_ok=True)

    if backup and export_path.exists():
        backup_path = export_path.with_suffix(export_path.suffix + ".bak-sync")
        shutil.copy2(export_path, backup_path)

    write_text(export_path, new_content)

    return {
        "status": "updated",
        "path": str(export_path),
        "message": "Updated",
        "diff": diff if show_diff else None,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default=DEFAULT_MANIFEST)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--no-backup", action="store_true")
    parser.add_argument("--diff", action="store_true")
    parser.add_argument(
        "--only",
        nargs="*",
        default=[],
        help="Optional canonical IDs to sync, e.g. shared.implement aimoto.new-strategy",
    )
    args = parser.parse_args()

    manifest = load_yaml(Path(args.manifest))
    only = set(args.only)

    results: list[dict[str, Any]] = []

    for artifact in manifest.get("artifacts", []):
        canonical_id = artifact["canonical_id"]

        if only and canonical_id not in only:
            continue

        name = artifact["name"]
        description = artifact.get("description")
        source_of_truth = artifact.get("source_of_truth")

        if not description:
            results.append(
                {
                    "status": "error",
                    "path": "",
                    "message": f"Missing description for {canonical_id}",
                }
            )
            continue

        if not source_of_truth:
            results.append(
                {
                    "status": "error",
                    "path": "",
                    "message": f"Missing source_of_truth for {canonical_id}",
                }
            )
            continue

        canonical_path = Path(source_of_truth)

        for export in artifact.get("exports", []):
            export_path = Path(export["path"])

            export_description = export.get("description") or description

            result = sync_export(
                canonical_path=canonical_path,
                export_path=export_path,
                name=name,
                description=export_description,
                apply=args.apply,
                backup=not args.no_backup,
                show_diff=args.diff,
            )

            result["canonical_id"] = canonical_id
            result["target"] = export.get("target")
            results.append(result)

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

    has_error = any(result["status"] == "error" for result in results)
    raise SystemExit(1 if has_error else 0)


if __name__ == "__main__":
    main()