#!/usr/bin/env python3
"""Mutating project skill actions for the local AI System backend.

This module owns the two write paths the interface can trigger: importing an
unmanaged runtime skill into the managed sources, and synchronising a project's
exports from its canonicals.

Design rules:

* every write is atomic (temporary file + ``os.replace``);
* nothing is overwritten silently: an incompatible canonical is a conflict;
* both actions are idempotent;
* every response reports ``writeState`` so the interface can say whether
  anything was modified;
* the backend stays authoritative on what may be imported or synchronised.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Any

import yaml

AI_SYSTEM_ROOT = Path(__file__).resolve().parents[1]
if str(AI_SYSTEM_ROOT) not in sys.path:
    sys.path.insert(0, str(AI_SYSTEM_ROOT))

from scripts.project_skills import (  # noqa: E402
    DEFAULT_REGISTRY,
    SCHEMA_VERSION,
    ProjectSkillsError,
    generated_at,
    load_manifest_path,
    normalize_project_slug,
    read_yaml_document,
    resolve_path,
    resolve_project,
    scan_project,
    validate_manifest_shape,
    validate_registry_shape,
)
from scripts.ai_inventory import normalize_name, project_shared_targets  # noqa: E402
from scripts.sync_skills import (  # noqa: E402
    build_export_content,
    canonical_body,
    split_frontmatter,
)

# Write outcome reported to the interface (spec 21.6).
WRITE_NO_CHANGES = "no_changes"
WRITE_APPLIED = "applied"
WRITE_PARTIAL = "partial_changes"
WRITE_ROLLED_BACK = "rolled_back"

IMPORTABLE_SOURCES = {"codex", "claude"}

SOURCE_TO_EXPORT_TARGET = {
    "codex": "codex_skill",
    "claude": "claude_command",
}

# Statuses a sync is allowed to repair. Anything else needs an explicit human
# decision and must never be overwritten.
SYNCABLE_STATUSES = {"missing_claude", "missing_codex", "canonical_drift"}


class ProjectActionError(ProjectSkillsError):
    """Expected mutating-action error carrying a write state."""

    def __init__(
        self,
        code: str,
        message: str,
        details: dict[str, Any] | None = None,
        *,
        write_state: str = WRITE_NO_CHANGES,
        retryable: bool = False,
        suggested_action: str | None = None,
    ) -> None:
        super().__init__(code, message, details)
        self.write_state = write_state
        self.retryable = retryable
        self.suggested_action = suggested_action


# --------------------------------------------------------------------------
# Atomic IO
# --------------------------------------------------------------------------


def atomic_write_text(path: Path, content: str) -> None:
    """Write ``content`` to ``path`` without ever leaving a partial file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    handle, temp_name = tempfile.mkstemp(
        dir=str(path.parent),
        prefix=f".{path.name}.",
        suffix=".tmp",
    )
    try:
        with os.fdopen(handle, "w", encoding="utf-8") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp_name, path)
    except BaseException:
        Path(temp_name).unlink(missing_ok=True)
        raise


def dump_manifest(manifest: dict[str, Any]) -> str:
    return yaml.safe_dump(manifest, sort_keys=False, allow_unicode=True, width=100)


# --------------------------------------------------------------------------
# Envelopes
# --------------------------------------------------------------------------


def success_payload(
    *,
    action: str,
    project: str,
    write_state: str,
    summary: str,
    changes: dict[str, Any],
    outcome: str,
    skill: str | None = None,
) -> dict[str, Any]:
    return {
        "schemaVersion": SCHEMA_VERSION,
        "status": "ok",
        "generatedAt": generated_at(),
        "action": action,
        "project": project,
        "skill": skill,
        "outcome": outcome,
        "writeState": write_state,
        "summary": summary,
        "changes": changes,
        "error": None,
    }


def action_error_payload(
    *,
    action: str,
    project: str | None,
    skill: str | None,
    error: ProjectActionError,
) -> dict[str, Any]:
    return {
        "schemaVersion": SCHEMA_VERSION,
        "status": "error",
        "generatedAt": generated_at(),
        "action": action,
        "project": project,
        "skill": skill,
        "outcome": "failed",
        "writeState": error.write_state,
        "summary": error.message,
        "changes": None,
        "error": {
            "code": error.code,
            "message": error.message,
            "details": error.details,
            "retryable": error.retryable,
            "writeState": error.write_state,
            "suggestedAction": error.suggested_action,
        },
    }


# --------------------------------------------------------------------------
# Shared helpers
# --------------------------------------------------------------------------


def find_skill(scan: dict[str, Any], skill_name: str) -> dict[str, Any]:
    key = normalize_name(skill_name)
    matches = [
        skill for skill in scan["skills"] if normalize_name(skill["name"]) == key
    ]
    if not matches:
        raise ProjectActionError(
            "unknown_skill",
            f"Skill not found in project: {skill_name}",
            {"skill": skill_name},
            suggested_action="rescan_project",
        )
    if len(matches) > 1:
        raise ProjectActionError(
            "ambiguous_skill",
            f"Multiple skills match this name: {skill_name}",
            {"skill": skill_name},
            suggested_action="review_conflict",
        )
    return matches[0]


def skills_root(manifest_path: Path) -> Path:
    """Managed sources live beside the manifest that declares them.

    Deriving the root from the manifest rather than a module constant keeps
    every write inside whichever AI System root the caller selected, so tests
    can never touch the real repository.
    """
    return manifest_path.parent / "skills"


def canonical_target_path(
    manifest_path: Path,
    project_name: str,
    skill_key: str,
) -> Path:
    slug = normalize_project_slug(project_name)
    return skills_root(manifest_path) / "projects" / slug / skill_key / "canonical.md"


def manifest_entry_for(manifest: dict[str, Any], canonical_id: str) -> dict[str, Any] | None:
    for artifact in manifest.get("artifacts", []):
        if str(artifact.get("canonical_id")) == canonical_id:
            return artifact
    return None


def build_canonical_content(name: str, description: str, body: str) -> str:
    header = yaml.safe_dump(
        {"name": name, "description": description},
        sort_keys=False,
        allow_unicode=True,
        width=120,
    )
    return "---\n" + header + "---\n\n" + body.lstrip("\n").rstrip() + "\n"


# --------------------------------------------------------------------------
# Import
# --------------------------------------------------------------------------


def import_skill(
    registry: dict[str, Any],
    manifest: dict[str, Any],
    manifest_path: Path,
    project_name: str,
    skill_name: str,
    source: str,
) -> dict[str, Any]:
    """Promote an unmanaged runtime skill into the managed sources."""
    validate_registry_shape(registry)
    validate_manifest_shape(manifest)

    if source not in IMPORTABLE_SOURCES:
        raise ProjectActionError(
            "invalid_source",
            f"Source must be one of {sorted(IMPORTABLE_SOURCES)}: {source}",
            {"source": source},
        )

    project = resolve_project(registry, project_name)
    scan = scan_project(registry, manifest, project_name)
    skill = find_skill(scan, skill_name)
    skill_key = normalize_name(skill["name"])

    canonical_id = skill.get("candidateCanonicalId") or (
        f"{normalize_project_slug(project_name)}.{skill_key}"
    )
    existing_entry = manifest_entry_for(manifest, canonical_id)
    canonical_path = canonical_target_path(manifest_path, project_name, skill_key)

    # Already managed: report it plainly instead of rewriting anything.
    if skill.get("managed") and existing_entry is not None:
        return success_payload(
            action="import",
            project=project_name,
            skill=skill["name"],
            outcome="already_managed",
            write_state=WRITE_NO_CHANGES,
            summary=f"{skill['name']} est déjà géré par AI System.",
            changes={"created": 0, "updated": 0, "unchanged": 1, "canonicalId": canonical_id},
        )

    if not skill.get("importable"):
        raise ProjectActionError(
            "not_importable",
            f"Le backend n'autorise pas l'import de ce skill : {skill['name']}",
            {"skill": skill["name"], "status": skill.get("status")},
            suggested_action="review_conflict",
        )

    source_path_raw = skill.get("paths", {}).get(source)
    if not source_path_raw:
        raise ProjectActionError(
            "missing_source",
            f"Aucune source {source} détectée pour {skill['name']}.",
            {"skill": skill["name"], "source": source},
        )

    source_path = Path(source_path_raw)
    if not source_path.is_file():
        raise ProjectActionError(
            "missing_source",
            f"Fichier source introuvable : {source_path}",
            {"path": str(source_path)},
        )

    present = skill.get("presence", {}).get(source)
    if not present:
        raise ProjectActionError(
            "source_mismatch",
            f"Le skill n'est pas présent dans {source}.",
            {"skill": skill["name"], "source": source},
        )

    raw = source_path.read_text(encoding="utf-8", errors="replace")
    frontmatter, body = split_frontmatter(raw)
    if not isinstance(frontmatter, dict):
        raise ProjectActionError(
            "invalid_frontmatter",
            f"Le fichier source n'a pas de frontmatter exploitable : {source_path}",
            {"path": str(source_path)},
        )

    description = frontmatter.get("description")
    if not isinstance(description, str) or not description.strip():
        raise ProjectActionError(
            "invalid_frontmatter",
            f"Le frontmatter source ne déclare pas de description : {source_path}",
            {"path": str(source_path)},
        )

    canonical_content = build_canonical_content(skill["name"], description, body)

    # An existing canonical with different content is a conflict, never an
    # overwrite (spec 23.2).
    if canonical_path.exists():
        current = canonical_path.read_text(encoding="utf-8", errors="replace")
        if current != canonical_content:
            raise ProjectActionError(
                "canonical_conflict",
                "Une source gérée incompatible existe déjà.",
                {"canonicalId": canonical_id, "path": str(canonical_path)},
                suggested_action="review_conflict",
            )

    if existing_entry is not None and canonical_path.exists():
        return success_payload(
            action="import",
            project=project_name,
            skill=skill["name"],
            outcome="already_managed",
            write_state=WRITE_NO_CHANGES,
            summary=f"{skill['name']} est déjà géré par AI System.",
            changes={"created": 0, "updated": 0, "unchanged": 1, "canonicalId": canonical_id},
        )

    targets = sorted(project_shared_targets(project["_raw"]) | {source})
    exports = []
    for target in targets:
        if target == "codex":
            export_path = Path(project["paths"]["codexSkills"]) / skill["name"] / "SKILL.md"
        else:
            export_path = Path(project["paths"]["claudeCommands"]) / f"{skill['name']}.md"
        exports.append({"target": SOURCE_TO_EXPORT_TARGET[target], "path": str(export_path)})

    entry = {
        "canonical_id": canonical_id,
        "name": skill["name"],
        "description": description,
        "version": "1.0.0",
        "scope": "project",
        "project": project_name,
        "status": "active",
        "source_of_truth": str(canonical_path),
        "compatibility": {"claude_code": "claude" in targets, "codex": "codex" in targets},
        "exports": exports,
    }

    created_canonical = not canonical_path.exists()
    atomic_write_text(canonical_path, canonical_content)

    updated_manifest = {
        **manifest,
        "artifacts": list(manifest.get("artifacts", [])),
    }
    if existing_entry is None:
        updated_manifest["artifacts"].append(entry)

    try:
        atomic_write_text(manifest_path, dump_manifest(updated_manifest))
    except OSError as exc:
        # The canonical landed but the manifest did not: undo the canonical so
        # the system is never left half-managed.
        if created_canonical:
            canonical_path.unlink(missing_ok=True)
        raise ProjectActionError(
            "manifest_write_failed",
            "Le manifest n'a pas pu être écrit ; l'import a été annulé.",
            {"path": str(manifest_path), "reason": str(exc)},
            write_state=WRITE_ROLLED_BACK,
            retryable=True,
        ) from exc

    return success_payload(
        action="import",
        project=project_name,
        skill=skill["name"],
        outcome="imported",
        write_state=WRITE_APPLIED,
        summary=(
            f"{skill['name']} est désormais géré par AI System "
            f"({canonical_id})."
        ),
        changes={
            "created": 1 if created_canonical else 0,
            "updated": 0 if created_canonical else 1,
            "unchanged": 0,
            "canonicalId": canonical_id,
            "canonicalPath": str(canonical_path),
            "targets": targets,
        },
    )


# --------------------------------------------------------------------------
# Sync
# --------------------------------------------------------------------------


def plan_sync(
    registry: dict[str, Any],
    manifest: dict[str, Any],
    project_name: str,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Return the (repairable, blocked) skills for a project sync."""
    scan = scan_project(registry, manifest, project_name)
    repairable = [
        skill for skill in scan["skills"] if skill["status"] in SYNCABLE_STATUSES
    ]
    blocked = [
        skill
        for skill in scan["skills"]
        if skill["status"] in {"conflict", "manifest_error"}
    ]
    return repairable, blocked


def sync_project(
    registry: dict[str, Any],
    manifest: dict[str, Any],
    project_name: str,
    *,
    apply: bool,
) -> dict[str, Any]:
    """Rebuild a project's missing or drifted exports from its canonicals.

    Only statuses the backend considers safe are repaired. Conflicts are
    reported, never resolved automatically.
    """
    validate_registry_shape(registry)
    validate_manifest_shape(manifest)
    resolve_project(registry, project_name)

    repairable, blocked = plan_sync(registry, manifest, project_name)

    created = 0
    updated = 0
    unchanged = 0
    failures: list[dict[str, Any]] = []
    touched: list[dict[str, Any]] = []

    for skill in repairable:
        canonical_raw = skill.get("sourceOfTruth") or skill.get("paths", {}).get("canonical")
        if not canonical_raw:
            failures.append({"skill": skill["name"], "reason": "canonical_unknown"})
            continue

        canonical_path = Path(canonical_raw)
        if not canonical_path.is_file():
            failures.append({"skill": skill["name"], "reason": "canonical_missing"})
            continue

        description = skill.get("description") or ""
        for target in ("codex", "claude"):
            if skill["status"] == "missing_claude" and target != "claude":
                continue
            if skill["status"] == "missing_codex" and target != "codex":
                continue

            export_raw = skill.get("paths", {}).get(target)
            if not export_raw:
                continue

            export_path = Path(export_raw)
            new_content = build_export_content(
                canonical_path=canonical_path,
                name=skill["name"],
                description=description,
            )
            existed = export_path.exists()
            old_content = (
                export_path.read_text(encoding="utf-8", errors="replace") if existed else ""
            )

            if old_content == new_content:
                unchanged += 1
                continue

            if not apply:
                if existed:
                    updated += 1
                else:
                    created += 1
                touched.append({"skill": skill["name"], "target": target, "path": str(export_path)})
                continue

            try:
                atomic_write_text(export_path, new_content)
            except OSError as exc:
                failures.append(
                    {"skill": skill["name"], "target": target, "reason": str(exc)}
                )
                continue

            if existed:
                updated += 1
            else:
                created += 1
            touched.append({"skill": skill["name"], "target": target, "path": str(export_path)})

    if apply:
        if failures and (created or updated):
            write_state = WRITE_PARTIAL
        elif created or updated:
            write_state = WRITE_APPLIED
        else:
            write_state = WRITE_NO_CHANGES
    else:
        write_state = WRITE_NO_CHANGES

    outcome = "failed" if failures and not (created or updated) else (
        "partial" if failures else ("planned" if not apply else "synced")
    )

    parts = []
    if created:
        parts.append(f"{created} export{'s' if created > 1 else ''} créé{'s' if created > 1 else ''}")
    if updated:
        parts.append(f"{updated} mis à jour")
    if unchanged:
        parts.append(f"{unchanged} inchangé{'s' if unchanged > 1 else ''}")
    if not parts:
        parts.append("aucun changement")

    conflict_note = ""
    if blocked:
        conflict_note = (
            f" — {len(blocked)} conflit{'s' if len(blocked) > 1 else ''} non résolu"
            f"{'s' if len(blocked) > 1 else ''}"
        )

    verb = "Prévisualisation" if not apply else "Synchronisation terminée"
    summary = f"{verb} — {', '.join(parts)}{conflict_note}."

    return success_payload(
        action="sync",
        project=project_name,
        outcome=outcome,
        write_state=write_state,
        summary=summary,
        changes={
            "created": created,
            "updated": updated,
            "unchanged": unchanged,
            "conflicts": len(blocked),
            "failures": failures,
            "targets": touched,
            "blocked": [
                {"skill": skill["name"], "status": skill["status"]} for skill in blocked
            ],
            "applied": apply,
        },
    )


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Import and synchronise AI System project skills as JSON."
    )
    parser.add_argument("--registry", default=str(DEFAULT_REGISTRY))
    parser.add_argument("--manifest", default=None)
    subparsers = parser.add_subparsers(dest="command", required=True)

    import_parser = subparsers.add_parser("import")
    import_parser.add_argument("--project", required=True)
    import_parser.add_argument("--skill", required=True)
    import_parser.add_argument("--source", required=True, choices=sorted(IMPORTABLE_SOURCES))
    import_parser.add_argument("--json", action="store_true")

    sync_parser = subparsers.add_parser("sync")
    sync_parser.add_argument("--project", required=True)
    sync_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report what would change without writing anything.",
    )
    sync_parser.add_argument("--json", action="store_true")

    return parser.parse_args(argv)


def execute(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    project = getattr(args, "project", None)
    skill = getattr(args, "skill", None)
    try:
        registry_path = resolve_path(args.registry)
        registry = read_yaml_document(registry_path, error_code="invalid_registry")
        manifest_path = load_manifest_path(registry, args.manifest)
        manifest = read_yaml_document(manifest_path, error_code="invalid_manifest")

        if args.command == "import":
            return (
                import_skill(
                    registry,
                    manifest,
                    manifest_path,
                    args.project,
                    args.skill,
                    args.source,
                ),
                0,
            )

        return (
            sync_project(registry, manifest, args.project, apply=not args.dry_run),
            0,
        )
    except ProjectActionError as exc:
        return action_error_payload(
            action=args.command, project=project, skill=skill, error=exc
        ), 1
    except ProjectSkillsError as exc:
        wrapped = ProjectActionError(exc.code, exc.message, exc.details)
        return action_error_payload(
            action=args.command, project=project, skill=skill, error=wrapped
        ), 1
    except Exception as exc:  # pragma: no cover - fail-closed boundary
        wrapped = ProjectActionError(
            "internal_error",
            "Erreur interne du backend d'action.",
            {"type": type(exc).__name__, "reason": str(exc)},
        )
        return action_error_payload(
            action=getattr(args, "command", None),
            project=project,
            skill=skill,
            error=wrapped,
        ), 1


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    payload, exit_code = execute(args)
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
