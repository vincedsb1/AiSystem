#!/usr/bin/env python3

from __future__ import annotations

import argparse
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
    return yaml.safe_load(read_text(path))


def split_frontmatter(content: str) -> tuple[dict[str, Any] | None, str]:
    """
    Returns (frontmatter, body).

    If no YAML frontmatter starts at byte 0, returns (None, full_content).
    """
    if not content.startswith("---\n"):
        return None, content

    parts = content.split("---", 2)
    if len(parts) < 3:
        return None, content

    raw_frontmatter = parts[1].strip()
    body = parts[2].lstrip("\n")

    if not raw_frontmatter:
        return {}, body

    parsed = yaml.safe_load(raw_frontmatter)
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


def is_generated_note_line(line: str) -> bool:
    return line.startswith("# Frontmatter pour ")


def clean_body(body: str) -> str:
    """
    Supprime uniquement la ligne de note que je t'avais donnée dans l'exemple.
    Ne supprime pas les vrais titres de commandes.
    """
    lines = body.splitlines()

    if lines and is_generated_note_line(lines[0]):
        lines = lines[1:]

    return "\n".join(lines).lstrip("\n") + ("\n" if lines else "")


def apply_frontmatter_to_file(
    *,
    path: Path,
    name: str,
    description: str,
    apply: bool,
    backup: bool,
) -> str:
    if not path.exists():
        return f"SKIP missing: {path}"

    original = read_text(path)
    existing_frontmatter, body = split_frontmatter(original)

    body = clean_body(body)

    new_frontmatter = build_runtime_frontmatter(name, description)
    new_content = new_frontmatter + body

    if original == new_content:
        return f"OK unchanged: {path}"

    if not apply:
        return f"DRY-RUN would update: {path}"

    if backup:
        backup_path = path.with_suffix(path.suffix + ".bak-ai-frontmatter")
        shutil.copy2(path, backup_path)

    write_text(path, new_content)
    return f"UPDATED: {path}"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default=DEFAULT_MANIFEST)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--no-backup", action="store_true")
    parser.add_argument(
        "--only",
        nargs="*",
        default=[],
        help="Optional canonical IDs to update, e.g. shared.implement aimoto.new-strategy",
    )
    args = parser.parse_args()

    manifest = load_yaml(Path(args.manifest))
    only = set(args.only)

    for artifact in manifest.get("artifacts", []):
        canonical_id = artifact["canonical_id"]

        if only and canonical_id not in only:
            continue

        name = artifact["name"]

        for export in artifact.get("exports", []):
            path = Path(export["path"])

            # Description runtime :
            # - si un jour tu veux une description différente par export,
            #   ajoute description dans exports[].
            description = export.get("description") or artifact.get("description")

            if not description:
                # fallback contrôlé : description minimale depuis le nom.
                description = f"Run the {name} workflow."

            result = apply_frontmatter_to_file(
                path=path,
                name=name,
                description=description,
                apply=args.apply,
                backup=not args.no_backup,
            )

            print(result)


if __name__ == "__main__":
    main()