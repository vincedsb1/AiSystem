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
SHARED_CLAUDE_COMMANDS_ROOT = Path("/Users/vincentdesbrosses/Documents/Misc/claude-commands")


SHARED_SKILLS: dict[str, dict[str, Any]] = {
    "commit": {
        "description": "Prepare, validate, commit, and optionally push the current Git changes while respecting project commit and documentation rules.",
        "domain": "git",
        "guards": {
            "requires_project_config": True,
            "forbids_generated_commit_mentions": True,
            "requires_git_status_review": True,
        },
    },
    "create-doc": {
        "description": "Create or update useful project documentation while respecting the current project's documentation conventions.",
        "domain": "documentation",
        "guards": {
            "requires_project_config": True,
            "forbids_low_value_documentation": True,
            "requires_doc_location_check": True,
        },
    },
    "optimize-claude-md": {
        "description": "Audit and optimize project AI instruction files such as CLAUDE.md, AGENTS.md, project-config.md, and related context documents.",
        "domain": "ai-maintenance",
        "guards": {
            "requires_project_config": True,
            "requires_existing_instruction_review": True,
            "forbids_unscoped_rewrites": True,
        },
    },
    "spec-0-feedback": {
        "description": "Collect and structure feedback before starting a formal specification workflow.",
        "domain": "specification",
        "guards": {
            "requires_project_config": True,
            "forbids_implementation": True,
            "requires_explicit_problem_context": True,
        },
    },
    "spec-1-intake": {
        "description": "Transform an idea or request into a structured intake for a specification workflow.",
        "domain": "specification",
        "guards": {
            "requires_project_config": True,
            "forbids_implementation": True,
            "requires_scope_clarification": True,
        },
    },
    "spec-2-draft": {
        "description": "Draft a structured implementation specification from a validated intake.",
        "domain": "specification",
        "guards": {
            "requires_project_config": True,
            "forbids_implementation": True,
            "requires_validated_intake": True,
        },
    },
    "spec-3-audit": {
        "description": "Audit a draft specification for ambiguity, missing constraints, risks, and implementation readiness.",
        "domain": "specification",
        "guards": {
            "requires_project_config": True,
            "forbids_implementation": True,
            "requires_draft_spec": True,
        },
    },
    "spec-4-challenge": {
        "description": "Challenge a specification by identifying weak assumptions, alternatives, hidden risks, and unnecessary complexity.",
        "domain": "specification",
        "guards": {
            "requires_project_config": True,
            "forbids_implementation": True,
            "requires_draft_or_audited_spec": True,
        },
    },
    "spec-5-revise": {
        "description": "Revise a specification after audit or challenge feedback and produce an implementation-ready version.",
        "domain": "specification",
        "guards": {
            "requires_project_config": True,
            "forbids_implementation": True,
            "requires_prior_spec_feedback": True,
        },
    },
    "test": {
        "description": "Run the current project's relevant test, lint, typecheck, or validation commands and report failures clearly.",
        "domain": "quality",
        "guards": {
            "requires_project_config": True,
            "requires_test_command_discovery": True,
            "forbids_silent_failure": True,
        },
    },
    "ui-review": {
        "description": "Review UI implementation, layout, accessibility, responsiveness, and visual consistency against project conventions.",
        "domain": "frontend",
        "guards": {
            "requires_project_config": True,
            "requires_existing_ui_pattern_review": True,
            "forbids_unscoped_redesign": True,
        },
    },
}


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


def canonical_body_from_claude_command(path: Path) -> str:
    content = read_text(path)
    _, body = split_frontmatter(content)

    return body.rstrip() + "\n"


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


def source_claude_path(name: str) -> Path:
    return SHARED_CLAUDE_COMMANDS_ROOT / f"{name}.md"


def canonical_path(name: str) -> Path:
    return AI_SYSTEM_ROOT / "skills" / "shared" / name / "canonical.md"


def codex_skill_path(name: str) -> Path:
    return AIMOTO_ROOT / ".agents" / "skills" / name / "SKILL.md"


def build_artifact(name: str, metadata: dict[str, Any]) -> dict[str, Any]:
    return {
        "canonical_id": f"shared.{name}",
        "name": name,
        "description": metadata["description"],
        "version": "1.0.0",
        "scope": "shared",
        "project": None,
        "domain": metadata["domain"],
        "status": "active",
        "source_of_truth": str(canonical_path(name)),
        "compatibility": {
            "claude_code": True,
            "codex": True,
        },
        "guards": {
            "project_specific_references_allowed": False,
            **metadata.get("guards", {}),
        },
        "exports": [
            {
                "target": "claude_command",
                "path": str(source_claude_path(name)),
            },
            {
                "target": "codex_skill",
                "path": str(codex_skill_path(name)),
            },
        ],
    }


def validate_source_files(names: list[str]) -> list[str]:
    errors: list[str] = []

    for name in names:
        path = source_claude_path(name)

        if not path.exists():
            errors.append(f"Missing shared Claude command: {path}")

    return errors


def ensure_canonical_file(name: str, *, apply: bool, overwrite: bool) -> tuple[bool, str]:
    source_path = source_claude_path(name)
    target_path = canonical_path(name)

    if not source_path.exists():
        return False, f"ERROR missing source: {source_path}"

    body = canonical_body_from_claude_command(source_path)

    if target_path.exists() and not overwrite:
        return False, f"OK canonical exists: {target_path}"

    if not apply:
        action = "would overwrite" if target_path.exists() else "would create"
        return True, f"DRY-RUN {action}: {target_path}"

    target_path.parent.mkdir(parents=True, exist_ok=True)

    existed_before = target_path.exists()

    if existed_before:
        backup_path = target_path.with_suffix(target_path.suffix + ".bak-shared-bootstrap")
        shutil.copy2(target_path, backup_path)

    write_text(target_path, body)

    action = "OVERWROTE" if existed_before else "CREATED"
    return True, f"{action}: {target_path}"


def ensure_codex_skill_directory(name: str, *, apply: bool) -> tuple[bool, str]:
    path = codex_skill_path(name).parent

    if path.exists():
        return False, f"OK Codex skill directory exists: {path}"

    if not apply:
        return True, f"DRY-RUN would create Codex skill directory: {path}"

    path.mkdir(parents=True, exist_ok=True)
    return True, f"CREATED Codex skill directory: {path}"


def add_missing_shared_skills(
    *,
    manifest_path: Path,
    names: list[str],
    apply: bool,
    overwrite_canonical: bool,
) -> list[str]:
    messages: list[str] = []

    errors = validate_source_files(names)
    if errors:
        return [f"ERROR {error}" for error in errors]

    manifest = load_yaml(manifest_path)
    manifest.setdefault("version", 1)
    manifest.setdefault("artifacts", [])

    manifest_changed = False

    for name in names:
        metadata = SHARED_SKILLS[name]
        canonical_id = f"shared.{name}"

        _, canonical_message = ensure_canonical_file(
            name,
            apply=apply,
            overwrite=overwrite_canonical,
        )
        messages.append(canonical_message)

        _, directory_message = ensure_codex_skill_directory(name, apply=apply)
        messages.append(directory_message)

        artifact = find_artifact(manifest, canonical_id)

        if artifact:
            did_add_claude = ensure_export(
                artifact,
                "claude_command",
                str(source_claude_path(name)),
            )
            did_add_codex = ensure_export(
                artifact,
                "codex_skill",
                str(codex_skill_path(name)),
            )

            if did_add_claude or did_add_codex:
                manifest_changed = True
                messages.append(f"UPDATED manifest exports: {canonical_id}")
            else:
                messages.append(f"OK manifest entry exists: {canonical_id}")

            continue

        manifest["artifacts"].append(build_artifact(name, metadata))
        manifest_changed = True
        messages.append(f"ADDED manifest entry: {canonical_id}")

    if not manifest_changed:
        messages.append("OK manifest unchanged")
        return messages

    if not apply:
        messages.append("DRY-RUN would update manifest")
        return messages

    backup_path = manifest_path.with_suffix(manifest_path.suffix + ".bak-shared-bootstrap")
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
        help="Overwrite existing canonical.md files from shared Claude commands.",
    )
    parser.add_argument(
        "--only",
        nargs="*",
        default=[],
        help="Optional shared skill names, e.g. commit create-doc test",
    )
    args = parser.parse_args()

    names = args.only or list(SHARED_SKILLS.keys())

    unknown = [name for name in names if name not in SHARED_SKILLS]

    if unknown:
        for name in unknown:
            print(f"ERROR unknown shared skill: {name}")
        raise SystemExit(1)

    messages = add_missing_shared_skills(
        manifest_path=Path(args.manifest),
        names=names,
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