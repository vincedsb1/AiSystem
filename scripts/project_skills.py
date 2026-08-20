#!/usr/bin/env python3
"""Machine-readable project skill discovery for the local AI System backend.

This phase is intentionally read-only.  It exposes project resolution and
runtime/manifest pairing for SwiftUI without importing, writing, or syncing
any artifact.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable

import yaml

# Make direct execution (`python scripts/project_skills.py ...`) behave like
# imports from the repository root used by the existing test suite.
AI_SYSTEM_ROOT = Path(__file__).resolve().parents[1]
if str(AI_SYSTEM_ROOT) not in sys.path:
    sys.path.insert(0, str(AI_SYSTEM_ROOT))

from scripts.ai_inventory import (
    artifact_from_file,
    build_manifest_index,
    build_pairs,
    enrich_artifacts_from_manifest,
    expected_shared_exports,
    is_backup,
    is_ignored,
    normalize_name,
    path_index_keys,
    pairing_exception,
    project_shared_targets,
)
from scripts.sync_skills import path_is_within


DEFAULT_REGISTRY = AI_SYSTEM_ROOT / "skills-registry.yml"
SCHEMA_VERSION = 1

RUNTIME_ARTIFACT_TYPES = {
    "codex_skill": "codex",
    "claude_command": "claude",
}

FRONTMATTER_ERROR_CODES = {
    "missing_frontmatter",
    "frontmatter_parse_error",
    "missing_name",
    "missing_description",
    "read_error",
}

ACTION_REQUIRED_STATUSES = {
    "local_codex_only",
    "local_claude_only",
    "local_both_unmanaged",
    "missing_claude",
    "missing_codex",
    "canonical_drift",
    "manifest_error",
    "conflict",
}

# Backend stays authoritative on severity (spec section 10.9).  "error" means a
# blocking inconsistency the user must resolve explicitly; "attention" means a
# safe, actionable remediation.
BLOCKING_STATUSES = {"manifest_error", "conflict"}

# Backend stays authoritative on the actions an interface may offer.
ALLOWED_ACTIONS_BY_STATUS = {
    "local_codex_only": ["import"],
    "local_claude_only": ["import"],
    "local_both_unmanaged": ["review"],
    "missing_claude": ["sync"],
    "missing_codex": ["sync"],
    "canonical_drift": ["review", "sync"],
    "manifest_error": ["review"],
    "conflict": ["review"],
}


class ProjectSkillsError(Exception):
    """Expected backend error that can be represented in the JSON contract."""

    def __init__(
        self,
        code: str,
        message: str,
        details: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.details = details or {}


def generated_at() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds").replace(
        "+00:00",
        "Z",
    )


def error_payload(
    *,
    code: str,
    message: str,
    details: dict[str, Any] | None = None,
    project: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return {
        "schemaVersion": SCHEMA_VERSION,
        "status": "error",
        "generatedAt": generated_at(),
        "project": project,
        "summary": None,
        "skills": [],
        "error": {
            "code": code,
            "message": message,
            "details": details or {},
        },
    }


def read_yaml_document(path: Path, *, error_code: str) -> dict[str, Any]:
    try:
        content = path.read_text(encoding="utf-8")
    except FileNotFoundError as exc:
        raise ProjectSkillsError(
            error_code,
            f"YAML file not found: {path}",
            {"path": str(path)},
        ) from exc
    except OSError as exc:
        raise ProjectSkillsError(
            error_code,
            f"Unable to read YAML file: {path}",
            {"path": str(path), "reason": str(exc)},
        ) from exc

    try:
        loaded = yaml.safe_load(content)
    except yaml.YAMLError as exc:
        raise ProjectSkillsError(
            error_code,
            f"Invalid YAML: {path}",
            {"path": str(path), "reason": str(exc)},
        ) from exc

    if not isinstance(loaded, dict):
        raise ProjectSkillsError(
            error_code,
            f"YAML document must be a mapping: {path}",
            {"path": str(path)},
        )

    return loaded


def validate_registry_shape(registry: dict[str, Any]) -> None:
    projects = registry.get("projects")
    if not isinstance(projects, list):
        raise ProjectSkillsError(
            "invalid_registry",
            "Registry projects must be a list.",
            {"field": "projects"},
        )

    seen_names: set[str] = set()
    for index, project in enumerate(projects):
        if not isinstance(project, dict):
            raise ProjectSkillsError(
                "invalid_registry",
                f"Registry project at index {index} must be a mapping.",
                {"index": index},
            )

        name = project.get("name")
        if not isinstance(name, str) or not name.strip():
            raise ProjectSkillsError(
                "invalid_registry",
                f"Registry project at index {index} has no valid name.",
                {"index": index},
            )

        if name in seen_names:
            raise ProjectSkillsError(
                "invalid_registry",
                f"Duplicate exact project name: {name}",
                {"project": name},
            )
        seen_names.add(name)

        if not isinstance(project.get("enabled"), bool):
            raise ProjectSkillsError(
                "invalid_registry",
                f"Project {name} has no boolean enabled field.",
                {"project": name},
            )


def validate_manifest_shape(manifest: dict[str, Any]) -> None:
    artifacts = manifest.get("artifacts")
    if not isinstance(artifacts, list):
        raise ProjectSkillsError(
            "invalid_manifest",
            "Manifest artifacts must be a list.",
            {"field": "artifacts"},
        )

    seen_ids: set[str] = set()
    for index, artifact in enumerate(artifacts):
        if not isinstance(artifact, dict):
            raise ProjectSkillsError(
                "invalid_manifest",
                f"Manifest artifact at index {index} must be a mapping.",
                {"index": index},
            )

        canonical_id = artifact.get("canonical_id")
        name = artifact.get("name")
        if not isinstance(canonical_id, str) or not canonical_id.strip():
            raise ProjectSkillsError(
                "invalid_manifest",
                f"Manifest artifact at index {index} has no canonical_id.",
                {"index": index},
            )
        if not isinstance(name, str) or not name.strip():
            raise ProjectSkillsError(
                "invalid_manifest",
                f"Manifest artifact {canonical_id} has no name.",
                {"canonicalId": canonical_id},
            )
        if canonical_id in seen_ids:
            raise ProjectSkillsError(
                "invalid_manifest",
                f"Duplicate canonical_id: {canonical_id}",
                {"canonicalId": canonical_id},
            )
        seen_ids.add(canonical_id)


def normalize_project_slug(value: str) -> str:
    normalized = normalize_name(value)
    normalized = re.sub(r"[^a-z0-9-]+", "-", normalized)
    normalized = re.sub(r"-+", "-", normalized).strip("-")
    if not normalized:
        raise ProjectSkillsError(
            "invalid_registry",
            f"Project name cannot produce a canonical slug: {value}",
            {"project": value},
        )
    return normalized


def resolve_path(raw: str, *, base: Path | None = None) -> Path:
    candidate = Path(raw).expanduser()
    if not candidate.is_absolute():
        if base is None:
            raise ProjectSkillsError(
                "invalid_registry",
                f"Expected an absolute path: {raw}",
                {"path": raw},
            )
        candidate = base / candidate
    return candidate.resolve(strict=False)


def validate_project_entry(project: dict[str, Any]) -> dict[str, Any]:
    name = project.get("name")
    root_raw = project.get("root")
    paths = project.get("paths")

    if not isinstance(root_raw, str) or not root_raw.strip():
        raise ProjectSkillsError(
            "missing_project_root",
            f"Project {name} has no usable root.",
            {"project": name},
        )
    if not isinstance(paths, dict):
        raise ProjectSkillsError(
            "missing_project_paths",
            f"Project {name} has no paths mapping.",
            {"project": name},
        )

    root = resolve_path(root_raw)
    if not root.is_dir():
        raise ProjectSkillsError(
            "missing_project_root",
            f"Project root is not a directory: {root}",
            {"project": name, "root": str(root)},
        )

    runtime_paths: dict[str, str] = {}
    for registry_key, json_key in (
        ("codex_skills", "codexSkills"),
        ("claude_commands", "claudeCommands"),
    ):
        raw_path = paths.get(registry_key)
        if not isinstance(raw_path, str) or not raw_path.strip():
            raise ProjectSkillsError(
                "missing_project_paths",
                f"Project {name} is missing paths.{registry_key}.",
                {"project": name, "field": registry_key},
            )

        runtime_path = resolve_path(raw_path, base=root)
        if not path_is_within(runtime_path, root):
            raise ProjectSkillsError(
                "path_escape",
                f"Runtime path escapes project root: {runtime_path}",
                {
                    "project": name,
                    "field": registry_key,
                    "root": str(root),
                    "path": str(runtime_path),
                },
            )
        runtime_paths[json_key] = str(runtime_path)

    return {
        "name": name,
        "root": str(root),
        "enabled": True,
        "paths": runtime_paths,
        "_raw": project,
    }


def validate_registry_projects(registry: dict[str, Any]) -> None:
    for project in registry.get("projects", []):
        if project.get("enabled"):
            validate_project_entry(project)


def resolve_project(registry: dict[str, Any], requested_name: str) -> dict[str, Any]:
    projects = registry.get("projects", [])
    exact = [project for project in projects if project.get("name") == requested_name]

    if len(exact) > 1:
        raise ProjectSkillsError(
            "ambiguous_project",
            f"Multiple exact registry entries match: {requested_name}",
            {"project": requested_name},
        )

    if exact:
        project = exact[0]
        if not project.get("enabled"):
            raise ProjectSkillsError(
                "disabled_project",
                f"Project is disabled: {requested_name}",
                {"project": requested_name},
            )
        return validate_project_entry(project)

    folded = [
        project
        for project in projects
        if str(project.get("name", "")).casefold() == requested_name.casefold()
    ]
    if folded:
        raise ProjectSkillsError(
            "ambiguous_project",
            f"Project name must match registry case exactly: {requested_name}",
            {
                "requested": requested_name,
                "candidates": [project.get("name") for project in folded],
            },
        )

    raise ProjectSkillsError(
        "unknown_project",
        f"Project not found: {requested_name}",
        {"project": requested_name},
    )


def list_projects(registry: dict[str, Any]) -> list[dict[str, Any]]:
    validate_registry_shape(registry)
    projects = []
    for project in registry.get("projects", []):
        if not project.get("enabled"):
            continue
        projects.append(validate_project_entry(project))

    projects.sort(key=lambda item: str(item["name"]).casefold())
    return [
        {
            "name": project["name"],
            "root": project["root"],
            "enabled": project["enabled"],
            "paths": project["paths"],
        }
        for project in projects
    ]


def load_manifest_path(
    registry: dict[str, Any],
    override: str | None,
) -> Path:
    raw_path = override or registry.get("settings", {}).get("skills_manifest")
    if not isinstance(raw_path, str) or not raw_path.strip():
        raise ProjectSkillsError(
            "invalid_registry",
            "Registry settings.skills_manifest is missing.",
            {"field": "settings.skills_manifest"},
        )
    return resolve_path(raw_path)


def registered_shared_claude_path(
    path: Path,
    *,
    project: dict[str, Any],
    registry: dict[str, Any],
    manifest_index: dict[str, dict[str, Any]],
) -> bool:
    """Allow only registry-backed Claude shared-export symlinks.

    The project runtime normally stays below its own root.  The existing
    registry intentionally supports Claude shared commands as symlinks to the
    central ``shared_sources`` directory, so those links are the one explicit
    exception.  A link is accepted only when its resolved target is both below
    a registered shared source root and known as an enabled shared export for
    the selected project.
    """
    resolved = path.resolve(strict=False)
    shared_roots = []
    for source in registry.get("shared_sources", []):
        if not isinstance(source, dict) or not source.get("enabled", True):
            continue
        if source.get("artifact_type") != "claude_command":
            continue
        raw_root = source.get("root")
        if isinstance(raw_root, str) and raw_root.strip():
            shared_roots.append(resolve_path(raw_root))

    if not any(path_is_within(resolved, shared_root) for shared_root in shared_roots):
        return False

    payload = None
    for key in path_index_keys(resolved):
        payload = manifest_index.get(key)
        if payload:
            break
    if not payload:
        exception = pairing_exception(
            registry,
            project=project["name"],
            name=path.stem,
            artifact_type="claude_command",
        )
        return bool(
            exception
            and exception.get("expected_status") in {
                "claude_only_project_command",
                "expected_claude_only",
            }
        )

    shared_ids = {
        str(canonical_id)
        for canonical_id in project["_raw"].get("install_shared_skills", [])
    }
    exception = pairing_exception(
        registry,
        project=project["name"],
        name=path.stem,
        artifact_type="claude_command",
    )
    return (
        payload.get("manifest_scope") == "shared"
        and payload.get("manifest_export_target") == "claude_command"
        and str(payload.get("manifest_canonical_id")) in shared_ids
    ) or bool(
        exception
        and exception.get("expected_status")
        in {"claude_only_project_command", "expected_claude_only"}
    )


def ensure_runtime_entry_within(
    path: Path,
    root: Path,
    *,
    project: dict[str, Any],
    registry: dict[str, Any],
    manifest_index: dict[str, dict[str, Any]],
    artifact_type: str,
) -> None:
    if path_is_within(path, root):
        return
    if (
        artifact_type == "claude_command"
        and registered_shared_claude_path(
            path,
            project=project,
            registry=registry,
            manifest_index=manifest_index,
        )
    ):
        return

    raise ProjectSkillsError(
        "path_escape",
        f"Runtime artifact escapes project root: {path}",
        {
            "project": project["name"],
            "root": str(root),
            "path": str(path),
        },
    )


def scan_codex_runtime(
    project: dict[str, Any],
    registry: dict[str, Any],
    manifest_index: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    root = Path(project["root"])
    base = Path(project["paths"]["codexSkills"])
    if not base.exists():
        return []
    if not base.is_dir():
        raise ProjectSkillsError(
            "missing_project_paths",
            f"Codex skills path is not a directory: {base}",
            {"project": project["name"], "path": str(base)},
        )

    artifacts: list[dict[str, Any]] = []
    for entry in sorted(base.iterdir(), key=lambda item: item.name.casefold()):
        ensure_runtime_entry_within(
            entry,
            root,
            project=project,
            registry=registry,
            manifest_index=manifest_index,
            artifact_type="codex_skill",
        )
        if is_ignored(entry, registry):
            continue
        if not entry.is_dir():
            continue

        skill_md = entry / "SKILL.md"
        if not skill_md.exists() and not skill_md.is_symlink():
            continue
        ensure_runtime_entry_within(
            skill_md,
            root,
            project=project,
            registry=registry,
            manifest_index=manifest_index,
            artifact_type="codex_skill",
        )
        artifacts.append(
            artifact_from_file(
                project_name=project["name"],
                project_root=root,
                artifact_type="codex_skill",
                path=skill_md,
                registry=registry,
                active=True,
            )
        )
    return artifacts


def scan_claude_runtime(
    project: dict[str, Any],
    registry: dict[str, Any],
    manifest_index: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    root = Path(project["root"])
    base = Path(project["paths"]["claudeCommands"])
    if not base.exists():
        return []
    if not base.is_dir():
        raise ProjectSkillsError(
            "missing_project_paths",
            f"Claude commands path is not a directory: {base}",
            {"project": project["name"], "path": str(base)},
        )

    artifacts: list[dict[str, Any]] = []
    for entry in sorted(base.iterdir(), key=lambda item: item.name.casefold()):
        ensure_runtime_entry_within(
            entry,
            root,
            project=project,
            registry=registry,
            manifest_index=manifest_index,
            artifact_type="claude_command",
        )
        if is_ignored(entry, registry) or is_backup(entry, registry):
            continue
        if entry.suffix != ".md" or not (entry.is_file() or entry.is_symlink()):
            continue
        artifacts.append(
            artifact_from_file(
                project_name=project["name"],
                project_root=root,
                artifact_type="claude_command",
                path=entry,
                registry=registry,
                active=True,
            )
        )
    return artifacts


def manifest_by_id(manifest: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        str(artifact["canonical_id"]): artifact
        for artifact in manifest.get("artifacts", [])
    }


def candidate_manifest_entries(
    manifest: dict[str, Any],
    project: dict[str, Any],
) -> dict[str, list[dict[str, Any]]]:
    raw_project = project["_raw"]
    shared_ids = {
        str(canonical_id)
        for canonical_id in raw_project.get("install_shared_skills", [])
    }
    by_name: dict[str, list[dict[str, Any]]] = defaultdict(list)

    for artifact in manifest.get("artifacts", []):
        scope = artifact.get("scope")
        is_project = scope == "project" and artifact.get("project") == project["name"]
        is_shared = scope == "shared" and artifact.get("canonical_id") in shared_ids
        if not (is_project or is_shared):
            continue
        by_name[normalize_name(artifact.get("name", ""))].append(artifact)

    return by_name


def expected_export_paths(
    manifest: dict[str, Any],
    project: dict[str, Any],
) -> dict[tuple[str, str], Path]:
    paths: dict[tuple[str, str], Path] = {}
    raw_project = project["_raw"]
    shared_ids = {
        str(canonical_id)
        for canonical_id in raw_project.get("install_shared_skills", [])
    }

    for target in ("codex", "claude"):
        for export in expected_shared_exports(
            {"projects": [raw_project]},
            manifest,
            target,
        ):
            if export.get("canonical_id") not in shared_ids:
                continue
            target_name = "codex" if target == "codex" else "claude"
            paths[(str(export["canonical_id"]), target_name)] = Path(export["path"])

    for artifact in manifest.get("artifacts", []):
        if artifact.get("scope") != "project":
            continue
        if artifact.get("project") != project["name"]:
            continue
        canonical_id = str(artifact.get("canonical_id"))
        for export in artifact.get("exports", []):
            target = export.get("target")
            target_name = {
                "codex_skill": "codex",
                "claude_command": "claude",
            }.get(target)
            if target_name and export.get("path"):
                paths[(canonical_id, target_name)] = resolve_path(export["path"])

    return paths


def artifact_by_pair_path(
    artifacts: Iterable[dict[str, Any]],
) -> dict[tuple[str, str], dict[str, Any]]:
    return {
        (artifact["artifact_type"], artifact["path"]): artifact
        for artifact in artifacts
    }


def frontmatter_issues(artifact: dict[str, Any] | None) -> list[dict[str, Any]]:
    if artifact is None:
        return []

    issues = [
        issue
        for issue in artifact.get("issues", [])
        if issue.get("code") in FRONTMATTER_ERROR_CODES
    ]

    path = Path(artifact["absolute_path"])
    expected_name = path.parent.name if artifact["artifact_type"] == "codex_skill" else path.stem
    declared_name = artifact.get("runtime_name")
    if declared_name and normalize_name(declared_name) != normalize_name(expected_name):
        issues.append(
            {
                "severity": "error",
                "code": "runtime_name_mismatch",
                "message": (
                    f"Frontmatter name {declared_name!r} does not match "
                    f"runtime path name {expected_name!r}."
                ),
            }
        )
    return issues


def manifest_issues(
    artifact: dict[str, Any] | None,
    manifest_by_canonical: dict[str, dict[str, Any]],
    project: dict[str, Any],
) -> list[dict[str, Any]]:
    if artifact is None or not artifact.get("manifest_found"):
        return []

    issues: list[dict[str, Any]] = []
    canonical_id = artifact.get("canonical_id")
    entry = manifest_by_canonical.get(str(canonical_id))
    if not entry:
        issues.append(
            {
                "code": "manifest_entry_missing",
                "message": f"Manifest entry not found: {canonical_id}",
            }
        )
        return issues

    if entry.get("status", "active") != "active":
        issues.append(
            {
                "code": "manifest_entry_inactive",
                "message": f"Manifest entry is not active: {canonical_id}",
            }
        )

    if entry.get("scope") == "project":
        if entry.get("project") != project["name"]:
            issues.append(
                {
                    "code": "manifest_project_mismatch",
                    "message": (
                        f"Manifest project {entry.get('project')} does not match "
                        f"{project['name']}."
                    ),
                }
            )
        expected_prefix = f"{normalize_project_slug(project['name'])}."
        if not str(canonical_id).lower().startswith(expected_prefix):
            issues.append(
                {
                    "code": "manifest_canonical_prefix_mismatch",
                    "message": f"Canonical ID does not belong to project: {canonical_id}",
                }
            )

    source = entry.get("source_of_truth")
    if not isinstance(source, str) or not source.strip():
        issues.append(
            {
                "code": "manifest_source_missing",
                "message": f"Manifest source_of_truth is missing: {canonical_id}",
            }
        )
    elif not resolve_path(source).is_file():
        issues.append(
            {
                "code": "canonical_missing",
                "message": f"Canonical source is missing: {source}",
            }
        )

    expected_target = RUNTIME_ARTIFACT_TYPES.get(artifact["artifact_type"])
    if artifact.get("export_target") == "codex_skill":
        actual_target = "codex"
    elif artifact.get("export_target") == "claude_command":
        actual_target = "claude"
    else:
        actual_target = None
    if expected_target and actual_target and expected_target != actual_target:
        issues.append(
            {
                "code": "manifest_export_target_mismatch",
                "message": f"Manifest export target does not match runtime artifact: {canonical_id}",
            }
        )

    return issues


def choose_candidate(
    candidates: dict[str, list[dict[str, Any]]],
    key: str,
) -> tuple[dict[str, Any] | None, list[dict[str, Any]]]:
    entries = candidates.get(key, [])
    if not entries:
        return None, []
    canonical_ids = {str(entry.get("canonical_id")) for entry in entries}
    if len(canonical_ids) > 1:
        return None, [
            {
                "code": "manifest_name_collision",
                "message": f"Multiple manifest canonicals match skill name: {key}",
                "details": {"canonicalIds": sorted(canonical_ids)},
            }
        ]
    return entries[0], []


def exception_payload(
    exception: dict[str, Any] | None,
    *,
    artifact_type: str | None,
    name: str,
) -> dict[str, Any] | None:
    if not exception:
        return None
    return {
        "status": exception.get("expected_status"),
        "reason": exception.get("reason"),
        "artifactType": artifact_type,
        "name": name,
    }


def conflict_payload(issues: list[dict[str, Any]]) -> dict[str, Any] | None:
    if not issues:
        return None
    return {
        "code": issues[0].get("code", "conflict"),
        "message": issues[0].get("message", "Skill metadata conflict."),
        "details": {"issues": issues},
    }


def source_path_for_artifact(artifact: dict[str, Any] | None) -> str | None:
    if not artifact:
        return None
    return str(Path(artifact["absolute_path"]).resolve(strict=False))


def row_status(
    pair_issue: str | None,
    *,
    codex: dict[str, Any] | None,
    claude: dict[str, Any] | None,
    has_candidate: bool,
) -> tuple[str, bool]:
    if pair_issue == "expected_claude_only":
        return "expected_claude_only", False
    if pair_issue == "expected_codex_only":
        return "expected_codex_only", False
    if pair_issue == "ok_same_canonical":
        return ("managed_synced", True) if has_candidate else ("local_both_unmanaged", False)
    if pair_issue == "ok_same_export_hash":
        return "local_both_unmanaged", False
    if pair_issue == "semantic_review_needed":
        return "local_both_unmanaged", False
    if pair_issue == "missing_claude_command":
        return ("missing_claude", True) if codex and codex.get("manifest_found") else ("local_codex_only", False)
    if pair_issue == "missing_codex_skill":
        return ("missing_codex", True) if claude and claude.get("manifest_found") else ("local_claude_only", False)
    if pair_issue and pair_issue.startswith("drift_"):
        if pair_issue == "drift_canonical_id_mismatch":
            return "conflict", False
        return "canonical_drift", True
    return "manifest_error", False


def display_runtime_path(
    artifact: dict[str, Any] | None,
    *,
    candidate: dict[str, Any] | None,
    target: str,
    expected_paths: dict[tuple[str, str], Path],
    project: dict[str, Any],
    name: str,
) -> str | None:
    actual = source_path_for_artifact(artifact)
    if actual:
        return actual

    if candidate:
        canonical_id = str(candidate.get("canonical_id"))
        expected = expected_paths.get((canonical_id, target))
        if expected:
            return str(expected.resolve(strict=False))
        for export in candidate.get("exports", []):
            if export.get("target") == {
                "codex": "codex_skill",
                "claude": "claude_command",
            }.get(target):
                if export.get("path"):
                    return str(resolve_path(export["path"]))

    if target == "codex":
        return str(Path(project["paths"]["codexSkills"]) / name / "SKILL.md")
    return str(Path(project["paths"]["claudeCommands"]) / f"{name}.md")


def build_skill_row(
    *,
    project: dict[str, Any],
    name: str,
    key: str,
    codex: dict[str, Any] | None,
    claude: dict[str, Any] | None,
    pair: dict[str, Any] | None,
    candidate: dict[str, Any] | None,
    candidate_issues: list[dict[str, Any]],
    manifest_by_canonical: dict[str, dict[str, Any]],
    registry: dict[str, Any],
    expected_paths: dict[tuple[str, str], Path],
    duplicate_keys: set[tuple[str, str]],
    shared_targets: set[str],
) -> dict[str, Any]:
    pair_issue = pair.get("issue") if pair else None
    candidate_id = str(candidate.get("canonical_id")) if candidate else None
    codex_id = codex.get("canonical_id") if codex else None
    claude_id = claude.get("canonical_id") if claude else None
    canonical_ids = {str(value) for value in (codex_id, claude_id) if value}

    if len(canonical_ids) == 1:
        canonical_id = next(iter(canonical_ids))
    elif candidate_id and not canonical_ids:
        canonical_id = candidate_id
    else:
        canonical_id = None

    metadata_source = candidate
    if canonical_id:
        metadata_source = manifest_by_canonical.get(canonical_id) or metadata_source

    scope = metadata_source.get("scope") if metadata_source else None
    source_of_truth = metadata_source.get("source_of_truth") if metadata_source else None
    if source_of_truth:
        source_of_truth = str(resolve_path(source_of_truth))

    status, managed = row_status(
        pair_issue,
        codex=codex,
        claude=claude,
        has_candidate=bool(candidate),
    )

    # A shared skill is only expected on the targets the project actually
    # installs (``ai_inventory.project_shared_targets`` is authoritative and
    # defaults to codex-only).  Without this, every project that installs
    # shared skills on Codex alone would report phantom ``missing_claude``
    # actions that ``check-ai-system.sh`` does not consider problems.
    if scope == "shared":
        if status == "missing_claude" and "claude" not in shared_targets:
            status, managed = "managed_synced", True
        elif status == "missing_codex" and "codex" not in shared_targets:
            status, managed = "managed_synced", True

    issues: list[dict[str, Any]] = []
    issues.extend(candidate_issues)
    issues.extend(frontmatter_issues(codex))
    issues.extend(frontmatter_issues(claude))
    issues.extend(manifest_issues(codex, manifest_by_canonical, project))
    issues.extend(manifest_issues(claude, manifest_by_canonical, project))

    if (key, "codex") in duplicate_keys or (key, "claude") in duplicate_keys:
        issues.append(
            {
                "code": "duplicate_runtime_name",
                "message": f"Multiple runtime artifacts match normalized name: {key}",
            }
        )

    exception = None
    if status in {"expected_claude_only", "expected_codex_only"}:
        exception_type = "claude_command" if status == "expected_claude_only" else "codex_skill"
        exception = pairing_exception(
            registry,
            project=project["name"],
            name=name,
            artifact_type=exception_type,
        )
        exception_value = exception_payload(
            exception,
            artifact_type=exception_type,
            name=name,
        )
    else:
        exception_value = None

    if status not in {"expected_claude_only", "expected_codex_only"} and issues:
        if status == "managed_synced" and any(
            issue.get("code") in {"manifest_entry_missing", "manifest_project_mismatch", "manifest_source_missing", "canonical_missing"}
            for issue in issues
        ):
            status = "manifest_error"
            managed = False

    has_frontmatter_error = any(
        issue.get("code") in FRONTMATTER_ERROR_CODES | {"runtime_name_mismatch", "read_error"}
        for issue in issues
    )
    single_unmanaged_source = (codex is not None) ^ (claude is not None)
    importable = (
        status in {"local_codex_only", "local_claude_only"}
        and single_unmanaged_source
        and not candidate_issues
        and not has_frontmatter_error
        and exception_value is None
    )

    if status in {"expected_claude_only", "expected_codex_only"}:
        candidate_id = None
        canonical_id = None
        scope = None
        source_of_truth = None
        issues = []
        managed = False
        importable = False

    if status == "local_both_unmanaged":
        importable = False

    canonical_path = source_of_truth
    if not canonical_path:
        slug = normalize_project_slug(project["name"])
        canonical_path = str(
            AI_SYSTEM_ROOT
            / "skills"
            / "projects"
            / slug
            / key
            / "canonical.md"
        )

    description = None
    for artifact in (codex, claude):
        if artifact and artifact.get("runtime_description"):
            description = artifact["runtime_description"]
            break
    if description is None and metadata_source:
        description = metadata_source.get("description")

    allowed_actions = list(ALLOWED_ACTIONS_BY_STATUS.get(status, []))
    if "import" in allowed_actions and not importable:
        allowed_actions = [action for action in allowed_actions if action != "import"]
        if not allowed_actions:
            allowed_actions = ["review"]

    if status in ACTION_REQUIRED_STATUSES:
        severity = "error" if status in BLOCKING_STATUSES else "attention"
    else:
        severity = None

    return {
        "name": name,
        "canonicalId": canonical_id,
        "candidateCanonicalId": candidate_id or (
            f"{normalize_project_slug(project['name'])}.{key}"
            if status not in {"expected_claude_only", "expected_codex_only"}
            else None
        ),
        "scope": scope,
        "sourceOfTruth": source_of_truth,
        "description": description,
        "managed": managed,
        "importable": importable,
        "presence": {
            "codex": codex is not None,
            "claude": claude is not None,
        },
        "paths": {
            "codex": display_runtime_path(
                codex,
                candidate=candidate,
                target="codex",
                expected_paths=expected_paths,
                project=project,
                name=name,
            ),
            "claude": display_runtime_path(
                claude,
                candidate=candidate,
                target="claude",
                expected_paths=expected_paths,
                project=project,
                name=name,
            ),
            "canonical": canonical_path,
        },
        "status": status,
        "severity": severity,
        "allowedActions": allowed_actions,
        "exception": exception_value,
        "conflict": conflict_payload(issues),
    }


def build_summary(skills: list[dict[str, Any]]) -> dict[str, int]:
    action_required = [
        skill for skill in skills if skill["status"] in ACTION_REQUIRED_STATUSES
    ]
    return {
        "total": len(skills),
        "managed": sum(bool(skill["managed"]) for skill in skills),
        "unmanaged": sum(
            not skill["managed"]
            and skill["status"] not in {"expected_claude_only", "expected_codex_only"}
            for skill in skills
        ),
        "shared": sum(skill.get("scope") == "shared" for skill in skills),
        "projectSpecific": sum(skill.get("scope") == "project" for skill in skills),
        "missingClaude": sum(skill["status"] in {"local_codex_only", "missing_claude"} for skill in skills),
        "missingCodex": sum(skill["status"] in {"local_claude_only", "missing_codex"} for skill in skills),
        "drift": sum(skill["status"] == "canonical_drift" for skill in skills),
        "conflicts": sum(skill["status"] in {"conflict", "manifest_error"} for skill in skills),
        "expectedExceptions": sum(
            skill["status"] in {"expected_claude_only", "expected_codex_only"}
            for skill in skills
        ),
        "actionRequired": len(action_required),
    }


def scan_project(
    registry: dict[str, Any],
    manifest: dict[str, Any],
    project_name: str,
) -> dict[str, Any]:
    validate_registry_shape(registry)
    validate_manifest_shape(manifest)
    project = resolve_project(registry, project_name)
    root = Path(project["root"])
    manifest_index = build_manifest_index(manifest, registry)

    artifacts = scan_codex_runtime(project, registry, manifest_index) + scan_claude_runtime(
        project,
        registry,
        manifest_index,
    )
    artifacts = enrich_artifacts_from_manifest(artifacts, manifest_index)
    artifacts_by_pair_path = artifact_by_pair_path(artifacts)
    manifest_index_by_id = manifest_by_id(manifest)
    candidates = candidate_manifest_entries(manifest, project)
    expected_paths = expected_export_paths(manifest, project)

    duplicate_counts: Counter[tuple[str, str]] = Counter()
    for artifact in artifacts:
        duplicate_counts[(artifact["normalized_name"], artifact["artifact_type"])] += 1
    duplicate_keys = {
        key for key, count in duplicate_counts.items() if count > 1
    }
    shared_targets = project_shared_targets(project["_raw"])

    pairs = build_pairs(artifacts, registry)
    represented: set[str] = set()
    skills: list[dict[str, Any]] = []

    for pair in pairs:
        key = normalize_name(pair["name"])
        codex = artifacts_by_pair_path.get(("codex_skill", pair.get("codex_path")))
        claude = artifacts_by_pair_path.get(("claude_command", pair.get("claude_path")))
        candidate, candidate_issues = choose_candidate(candidates, key)
        display_name = (
            codex.get("name") if codex else None
        ) or (
            claude.get("name") if claude else None
        ) or (
            candidate.get("name") if candidate else None
        ) or pair["name"]

        skills.append(
            build_skill_row(
                project=project,
                name=display_name,
                key=key,
                codex=codex,
                claude=claude,
                pair=pair,
                candidate=candidate,
                candidate_issues=candidate_issues,
                manifest_by_canonical=manifest_index_by_id,
                registry=registry,
                expected_paths=expected_paths,
                duplicate_keys=duplicate_keys,
                shared_targets=shared_targets,
            )
        )
        represented.add(key)

    for key, entries in candidates.items():
        if key in represented:
            continue
        candidate, candidate_issues = choose_candidate(candidates, key)
        if not candidate:
            display_name = key
        else:
            display_name = str(candidate.get("name") or key)
        skills.append(
            build_skill_row(
                project=project,
                name=display_name,
                key=key,
                codex=None,
                claude=None,
                pair=None,
                candidate=candidate,
                candidate_issues=candidate_issues,
                manifest_by_canonical=manifest_index_by_id,
                registry=registry,
                expected_paths=expected_paths,
                duplicate_keys=duplicate_keys,
                shared_targets=shared_targets,
            )
        )

    skills.sort(key=lambda skill: (str(skill["name"]).casefold(), str(skill["name"])))
    return {
        "schemaVersion": SCHEMA_VERSION,
        "status": "ok",
        "generatedAt": generated_at(),
        "project": {
            **{
                key: value
                for key, value in project.items()
                if not key.startswith("_")
            },
            "sharedTargets": sorted(shared_targets),
        },
        "summary": build_summary(skills),
        "skills": skills,
        "error": None,
    }


def project_state(summary: dict[str, int]) -> str:
    """Derive the semantic state of a scanned project.

    ``conflicts`` already aggregates ``conflict`` and ``manifest_error``, the two
    statuses the backend considers blocking.
    """
    if summary.get("conflicts", 0) > 0:
        return "error"
    if summary.get("actionRequired", 0) > 0:
        return "attention"
    return "healthy"


def global_state(project_entries: list[dict[str, Any]]) -> str:
    states = {entry["state"] for entry in project_entries}
    if "error" in states:
        return "error"
    if "attention" in states:
        return "attention"
    if not states:
        return "healthy"
    return "healthy"


def action_items_for_project(
    project_name: str,
    skills: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    for skill in skills:
        status = skill.get("status")
        if status not in ACTION_REQUIRED_STATUSES:
            continue
        actions.append(
            {
                "id": f"{project_name}::{skill['name']}",
                "project": project_name,
                "skill": skill["name"],
                "canonicalId": skill.get("canonicalId"),
                "status": status,
                "severity": skill.get("severity")
                or ("error" if status in BLOCKING_STATUSES else "attention"),
                "importable": bool(skill.get("importable")),
                "allowedActions": skill.get("allowedActions", []),
            }
        )
    return actions


def empty_project_summary() -> dict[str, int]:
    return build_summary([])


def build_overview(
    registry: dict[str, Any],
    manifest: dict[str, Any],
) -> dict[str, Any]:
    """Aggregate every enabled project into a single system-level snapshot.

    A project that fails to scan is reported as an errored entry instead of
    breaking the whole overview: the interface must still be able to describe
    the rest of the system.
    """
    validate_registry_shape(registry)
    validate_manifest_shape(manifest)

    project_entries: list[dict[str, Any]] = []
    actions: list[dict[str, Any]] = []

    totals = {
        "skillsTotal": 0,
        "skillsManaged": 0,
        "actionRequired": 0,
        "expectedExceptions": 0,
        "conflicts": 0,
    }

    for project in registry.get("projects", []):
        if not project.get("enabled"):
            continue

        name = str(project.get("name"))
        try:
            scan = scan_project(registry, manifest, name)
        except ProjectSkillsError as exc:
            project_entries.append(
                {
                    "name": name,
                    "root": project.get("root"),
                    "enabled": True,
                    "state": "error",
                    "summary": empty_project_summary(),
                    "error": {
                        "code": exc.code,
                        "message": exc.message,
                        "details": exc.details,
                    },
                }
            )
            continue

        summary = scan["summary"]
        state = project_state(summary)
        project_entries.append(
            {
                "name": name,
                "root": scan["project"]["root"],
                "enabled": True,
                "state": state,
                "summary": summary,
                "error": None,
            }
        )

        actions.extend(action_items_for_project(name, scan["skills"]))

        totals["skillsTotal"] += summary.get("total", 0)
        totals["skillsManaged"] += summary.get("managed", 0)
        totals["actionRequired"] += summary.get("actionRequired", 0)
        totals["expectedExceptions"] += summary.get("expectedExceptions", 0)
        totals["conflicts"] += summary.get("conflicts", 0)

    project_entries.sort(key=lambda entry: str(entry["name"]).casefold())
    actions.sort(
        key=lambda action: (
            0 if action["severity"] == "error" else 1,
            str(action["project"]).casefold(),
            str(action["skill"]).casefold(),
        )
    )

    return {
        "schemaVersion": SCHEMA_VERSION,
        "status": "ok",
        "generatedAt": generated_at(),
        "state": global_state(project_entries),
        "summary": {
            "projectsTotal": len(project_entries),
            "projectsHealthy": sum(
                entry["state"] == "healthy" for entry in project_entries
            ),
            "projectsAttention": sum(
                entry["state"] == "attention" for entry in project_entries
            ),
            "projectsError": sum(
                entry["state"] == "error" for entry in project_entries
            ),
            "skillsTotal": totals["skillsTotal"],
            "skillsManaged": totals["skillsManaged"],
            "actionRequired": totals["actionRequired"],
            "expectedExceptions": totals["expectedExceptions"],
            "conflicts": totals["conflicts"],
        },
        "projects": project_entries,
        "actions": actions,
        "error": None,
    }


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="List and scan registered AI System projects as JSON."
    )
    parser.add_argument("--registry", default=str(DEFAULT_REGISTRY))
    parser.add_argument(
        "--manifest",
        default=None,
        help="Optional manifest override; otherwise settings.skills_manifest is used.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    list_parser = subparsers.add_parser("list-projects")
    list_parser.add_argument("--json", action="store_true")

    scan_parser = subparsers.add_parser("scan")
    scan_parser.add_argument("--project", required=True)
    scan_parser.add_argument("--json", action="store_true")

    overview_parser = subparsers.add_parser("overview")
    overview_parser.add_argument("--json", action="store_true")

    return parser.parse_args(argv)


def execute(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    try:
        registry_path = resolve_path(args.registry)
        registry = read_yaml_document(registry_path, error_code="invalid_registry")
        validate_registry_shape(registry)

        if args.command == "list-projects":
            payload = {
                "schemaVersion": SCHEMA_VERSION,
                "status": "ok",
                "generatedAt": generated_at(),
                "projects": list_projects(registry),
                "error": None,
            }
            return payload, 0

        manifest_path = load_manifest_path(registry, args.manifest)
        manifest = read_yaml_document(manifest_path, error_code="invalid_manifest")

        if args.command == "overview":
            return build_overview(registry, manifest), 0

        payload = scan_project(registry, manifest, args.project)
        return payload, 0
    except ProjectSkillsError as exc:
        return (
            error_payload(
                code=exc.code,
                message=exc.message,
                details=exc.details,
            ),
            1,
        )
    except Exception as exc:  # pragma: no cover - final fail-closed boundary
        return (
            error_payload(
                code="internal_error",
                message="Unexpected project skills backend error.",
                details={"type": type(exc).__name__, "reason": str(exc)},
            ),
            1,
        )


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    payload, exit_code = execute(args)
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
