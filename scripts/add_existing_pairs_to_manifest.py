#!/usr/bin/env python3

from __future__ import annotations

import argparse
import shutil
from pathlib import Path
from typing import Any

import yaml


DEFAULT_MANIFEST = "/Users/vincentdesbrosses/Documents/Misc/ai-system/skills-manifest.yml"
AI_SYSTEM_ROOT = Path("/Users/vincentdesbrosses/Documents/Misc/ai-system")
AIMOTO_ROOT = Path("/Users/vincentdesbrosses/Documents/Misc/aimoto")


PAIRS = [
    "add-indicator",
    "analyse-signal",
    "article-review",
    "bilan",
    "edit-export-llm-report",
    "next",
]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def write_text(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def load_yaml(path: Path) -> dict[str, Any]:
    loaded = yaml.safe_load(read_text(path))
    return loaded if isinstance(loaded, dict) else {}


def dump_yaml(data: dict[str, Any]) -> str:
    return yaml.safe_dump(
        data,
        sort_keys=False,
        allow_unicode=True,
        width=120,
    )


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


def extract_description_from_markdown(path: Path) -> str | None:
    if not path.exists():
        return None

    frontmatter, _ = split_frontmatter(read_text(path))

    if not frontmatter:
        return None

    description = frontmatter.get("description")

    if not description:
        return None

    return str(description).strip()


def canonical_body_from_claude_command(path: Path) -> str:
    content = read_text(path)
    _, body = split_frontmatter(content)

    return body.rstrip() + "\n"


def artifact_exists(manifest: dict[str, Any], canonical_id: str) -> bool:
    return any(
        artifact.get("canonical_id") == canonical_id
        for artifact in manifest.get("artifacts", [])
    )


def find_artifact(manifest: dict[str, Any], canonical_id: str) -> dict[str, Any] | None:
    for artifact in manifest.get("artifacts", []):
        if artifact.get("canonical_id") == canonical_id:
            return artifact
    return None


def ensure_export(artifact: dict[str, Any], target: str, path: str) -> bool:
    exports = artifact.setdefault("exports", [])

    for export in exports:
        if export.get("target") == target and export.get("path") == path:
            return False

    exports.append(
        {
            "target": target,
            "path": path,
        }
    )

    return True


def build_artifact(name: str, description: str) -> dict[str, Any]:
    canonical_id = f"aimoto.{name}"
    canonical_path = (
        AI_SYSTEM_ROOT
        / "skills"
        / "projects"
        / "aimoto"
        / name
        / "canonical.md"
    )

    claude_path = AIMOTO_ROOT / ".claude" / "commands" / f"{name}.md"
    codex_path = AIMOTO_ROOT / ".agents" / "skills" / name / "SKILL.md"

    return {
        "canonical_id": canonical_id,
        "name": name,
        "description": description,
        "version": "1.0.0",
        "scope": "project",
        "project": "aimoto",
        "domain": "backtesting",
        "status": "active",
        "source_of_truth": str(canonical_path),
        "compatibility": {
            "claude_code": True,
            "codex": True,
        },
        "guards": {
            "requires_project_context": True,
            "requires_repo_read_before_recommendation": True,
            "project_specific_references_allowed": True,
        },
        "exports": [
            {
                "target": "claude_command",
                "path": str(claude_path),
            },
            {
                "target": "codex_skill",
                "path": str(codex_path),
            },
        ],
    }


def validate_pair_files(name: str) -> list[str]:
    errors: list[str] = []

    claude_path = AIMOTO_ROOT / ".claude" / "commands" / f"{name}.md"
    codex_path = AIMOTO_ROOT / ".agents" / "skills" / name / "SKILL.md"

    if not claude_path.exists():
        errors.append(f"Missing Claude command: {claude_path}")

    if not codex_path.exists():
        errors.append(f"Missing Codex skill: {codex_path}")

    return errors


def ensure_canonical_file(name: str, apply: bool, overwrite: bool) -> str:
    claude_path = AIMOTO_ROOT / ".claude" / "commands" / f"{name}.md"
    canonical_path = (
        AI_SYSTEM_ROOT
        / "skills"
        / "projects"
        / "aimoto"
        / name
        / "canonical.md"
    )

    if not claude_path.exists():
        return f"ERROR missing Claude source: {claude_path}"

    body = canonical_body_from_claude_command(claude_path)

    if canonical_path.exists() and not overwrite:
        return f"OK canonical exists: {canonical_path}"

    if not apply:
        action = "would overwrite" if canonical_path.exists() else "would create"
        return f"DRY-RUN {action}: {canonical_path}"

    canonical_path.parent.mkdir(parents=True, exist_ok=True)

    if canonical_path.exists():
        backup_path = canonical_path.with_suffix(canonical_path.suffix + ".bak-bootstrap")
        shutil.copy2(canonical_path, backup_path)

    write_text(canonical_path, body)

    action = "OVERWROTE" if canonical_path.exists() else "CREATED"
    return f"{action}: {canonical_path}"


def infer_description(name: str) -> str:
    codex_path = AIMOTO_ROOT / ".agents" / "skills" / name / "SKILL.md"
    claude_path = AIMOTO_ROOT / ".claude" / "commands" / f"{name}.md"

    description = extract_description_from_markdown(codex_path)

    if description:
        return description

    description = extract_description_from_markdown(claude_path)

    if description:
        return description

    return f"Run the {name} workflow for AIMOTO."


def add_pairs_to_manifest(
    *,
    manifest_path: Path,
    pair_names: list[str],
    apply: bool,
    overwrite_canonical: bool,
) -> list[str]:
    messages: list[str] = []

    manifest = load_yaml(manifest_path)
    manifest.setdefault("version", 1)
    manifest.setdefault("artifacts", [])

    changed = False

    for name in pair_names:
        canonical_id = f"aimoto.{name}"

        errors = validate_pair_files(name)
        if errors:
            messages.extend(f"ERROR {error}" for error in errors)
            continue

        messages.append(
            ensure_canonical_file(
                name=name,
                apply=apply,
                overwrite=overwrite_canonical,
            )
        )

        existing = find_artifact(manifest, canonical_id)

        if existing:
            claude_path = str(AIMOTO_ROOT / ".claude" / "commands" / f"{name}.md")
            codex_path = str(AIMOTO_ROOT / ".agents" / "skills" / name / "SKILL.md")

            did_add_claude = ensure_export(existing, "claude_command", claude_path)
            did_add_codex = ensure_export(existing, "codex_skill", codex_path)

            if did_add_claude or did_add_codex:
                changed = True
                messages.append(f"UPDATED manifest exports: {canonical_id}")
            else:
                messages.append(f"OK manifest entry exists: {canonical_id}")

            continue

        description = infer_description(name)
        manifest["artifacts"].append(build_artifact(name, description))
        changed = True
        messages.append(f"ADDED manifest entry: {canonical_id}")

    if not changed:
        messages.append("OK manifest unchanged")
        return messages

    if not apply:
        messages.append("DRY-RUN would update manifest")
        return messages

    backup_path = manifest_path.with_suffix(manifest_path.suffix + ".bak-bootstrap")
    shutil.copy2(manifest_path, backup_path)

    write_text(manifest_path, dump_yaml(manifest))
    messages.append(f"UPDATED manifest: {manifest_path}")
    messages.append(f"BACKUP manifest: {backup_path}")

    return messages


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default=DEFAULT_MANIFEST)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument(
        "--overwrite-canonical",
        action="store_true",
        help="Overwrite existing canonical.md files from Claude commands.",
    )
    parser.add_argument(
        "--only",
        nargs="*",
        default=[],
        help="Optional pair names, e.g. add-indicator next",
    )
    args = parser.parse_args()

    pair_names = args.only or PAIRS

    messages = add_pairs_to_manifest(
        manifest_path=Path(args.manifest),
        pair_names=pair_names,
        apply=args.apply,
        overwrite_canonical=args.overwrite_canonical,
    )

    has_error = False

    for message in messages:
        print(message)

        if message.startswith("ERROR"):
            has_error = True

    raise SystemExit(1 if has_error else 0)


if __name__ == "__main__":
    main()