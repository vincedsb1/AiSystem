#!/usr/bin/env python3

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:
    raise SystemExit(
        "PyYAML est requis. Lance :\n"
        "cd /Users/vincentdesbrosses/Documents/Misc/ai-system\n"
        "python3 -m venv .venv\n"
        "source .venv/bin/activate\n"
        "python -m pip install pyyaml\n"
        "python scripts/ai_inventory.py"
    )


DEFAULT_REGISTRY = "/Users/vincentdesbrosses/Documents/Misc/ai-system/skills-registry.yml"


# ---------------------------------------------------------------------------
# IO
# ---------------------------------------------------------------------------

def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def write_text(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def load_yaml(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}

    loaded = yaml.safe_load(read_text(path))
    return loaded if isinstance(loaded, dict) else {}


def sha256_normalized(content: str) -> str:
    normalized = content.replace("\r\n", "\n").strip()
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


# ---------------------------------------------------------------------------
# Frontmatter
# ---------------------------------------------------------------------------

def extract_frontmatter(content: str) -> dict[str, Any]:
    if not content.startswith("---\n"):
        return {}

    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}

    raw = parts[1].strip()
    if not raw:
        return {}

    try:
        parsed = yaml.safe_load(raw)
        return parsed if isinstance(parsed, dict) else {}
    except Exception:
        return {"__parse_error__": True}


def normalize_name(name: str) -> str:
    value = str(name).strip()

    if value.startswith("/"):
        value = value[1:]

    if value.endswith("/SKILL.md"):
        value = value.removesuffix("/SKILL.md")

    if value.endswith(".md"):
        value = value.removesuffix(".md")

    return value.replace("_", "-").lower()


def rel_path(path: Path, root: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


# ---------------------------------------------------------------------------
# Registry helpers
# ---------------------------------------------------------------------------

def registry_ignore_names(registry: dict[str, Any]) -> list[str]:
    return registry.get("quality_rules", {}).get("ignore_names", [])


def registry_backup_patterns(registry: dict[str, Any]) -> list[str]:
    return registry.get("quality_rules", {}).get("backup_patterns", [])


def metadata_required_types(registry: dict[str, Any]) -> set[str]:
    return set(registry.get("quality_rules", {}).get("metadata_required_for", []))


def required_frontmatter_fields(registry: dict[str, Any]) -> list[str]:
    return registry.get("quality_rules", {}).get("required_frontmatter_fields", [])


def recommended_frontmatter_fields(registry: dict[str, Any]) -> list[str]:
    return registry.get("quality_rules", {}).get("recommended_frontmatter_fields", [])


def fallback_patterns(registry: dict[str, Any]) -> list[str]:
    return registry.get("quality_rules", {}).get("forbidden_silent_fallback_patterns", [])


def registry_project_path(registry: dict[str, Any], project_name: str, key: str) -> str | None:
    for project in registry.get("projects", []):
        if project.get("name") == project_name:
            return project.get("paths", {}).get(key)
    return None


def registry_project(registry: dict[str, Any], project_name: str) -> dict[str, Any] | None:
    for project in registry.get("projects", []):
        if project.get("name") == project_name:
            return project
    return None


def is_ignored(path: Path, registry: dict[str, Any]) -> bool:
    return path.name in registry_ignore_names(registry)


def is_backup(path: Path, registry: dict[str, Any]) -> bool:
    name = path.name
    return any(pattern in name for pattern in registry_backup_patterns(registry))


def artifact_requires_metadata(artifact_type: str, registry: dict[str, Any]) -> bool:
    return artifact_type in metadata_required_types(registry)


# ---------------------------------------------------------------------------
# Manifest helpers
# ---------------------------------------------------------------------------

def get_manifest_path(registry: dict[str, Any]) -> Path | None:
    raw = registry.get("settings", {}).get("skills_manifest")
    if not raw:
        return None
    return Path(raw)


def path_index_keys(path: Path) -> set[str]:
    keys = {str(path)}

    try:
        keys.add(str(path.resolve(strict=False)))
    except Exception:
        pass

    return keys


def manifest_payload(
    artifact: dict[str, Any],
    *,
    export_target: str,
    export_path: Path,
) -> dict[str, Any]:
    return {
        "manifest_found": True,
        "manifest_canonical_id": artifact.get("canonical_id"),
        "manifest_name": artifact.get("name"),
        "manifest_description": artifact.get("description"),
        "manifest_version": artifact.get("version"),
        "manifest_scope": artifact.get("scope"),
        "manifest_project": artifact.get("project"),
        "manifest_domain": artifact.get("domain"),
        "manifest_status": artifact.get("status"),
        "manifest_source_of_truth": artifact.get("source_of_truth"),
        "manifest_compatibility": artifact.get("compatibility"),
        "manifest_guards": artifact.get("guards"),
        "manifest_export_target": export_target,
        "manifest_export_path": str(export_path),
    }


def expected_shared_codex_exports(
    registry: dict[str, Any],
    manifest: dict[str, Any],
) -> list[dict[str, Any]]:
    artifacts_by_id = {
        artifact.get("canonical_id"): artifact
        for artifact in manifest.get("artifacts", [])
        if artifact.get("canonical_id")
    }
    exports: list[dict[str, Any]] = []

    for project in registry.get("projects", []):
        if not project.get("enabled"):
            continue

        project_name = project.get("name")
        project_root = project.get("root")
        codex_skills_path = project.get("paths", {}).get("codex_skills")

        for canonical_id in project.get("install_shared_skills", []):
            artifact = artifacts_by_id.get(canonical_id)
            valid = (
                str(canonical_id).startswith("shared.")
                and artifact
                and artifact.get("scope") == "shared"
                and artifact.get("compatibility", {}).get("codex")
                and project_root
                and codex_skills_path
            )

            if not valid:
                exports.append({
                    "canonical_id": canonical_id,
                    "name": artifact.get("name") if artifact else canonical_id,
                    "version": artifact.get("version") if artifact else None,
                    "target": "codex_skill",
                    "project": project_name,
                    "path": None,
                    "exists": False,
                    "policy_error": "invalid_install_shared_skill",
                })
                continue

            export_path = (
                Path(project_root)
                / codex_skills_path
                / artifact["name"]
                / "SKILL.md"
            )
            exports.append({
                "canonical_id": canonical_id,
                "name": artifact.get("name"),
                "version": artifact.get("version"),
                "target": "codex_skill",
                "project": project_name,
                "path": str(export_path),
                "exists": export_path.exists(),
                "artifact": artifact,
            })

    return exports


def build_manifest_index(
    manifest: dict[str, Any],
    registry: dict[str, Any],
) -> dict[str, dict[str, Any]]:
    """
    Indexe chaque export déclaré dans skills-manifest.yml par chemin absolu
    et par realpath résolu.

    Objectif :
    - matcher les fichiers directs ;
    - matcher aussi les symlinks Claude vers /Users/.../claude-commands/*.md.
    """
    index: dict[str, dict[str, Any]] = {}

    for artifact in manifest.get("artifacts", []):
        canonical_id = artifact.get("canonical_id")
        exports = artifact.get("exports", [])

        for export in exports:
            raw_path = export.get("path")
            if not raw_path:
                continue

            export_path = Path(raw_path).expanduser()

            payload = manifest_payload(
                artifact,
                export_target=export.get("target"),
                export_path=export_path,
            )

            for key in path_index_keys(export_path):
                index[key] = payload

    for export in expected_shared_codex_exports(registry, manifest):
        artifact = export.get("artifact")
        raw_path = export.get("path")
        if not artifact or not raw_path:
            continue

        export_path = Path(raw_path)
        payload = manifest_payload(
            artifact,
            export_target="codex_skill",
            export_path=export_path,
        )
        for key in path_index_keys(export_path):
            index[key] = payload

    return index


def enrich_artifacts_from_manifest(
    artifacts: list[dict[str, Any]],
    manifest_index: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    enriched: list[dict[str, Any]] = []

    for artifact in artifacts:
        candidates = set()

        absolute_path = artifact.get("absolute_path")
        realpath = artifact.get("realpath")

        if absolute_path:
            candidates.update(path_index_keys(Path(absolute_path)))

        if realpath:
            candidates.update(path_index_keys(Path(realpath)))

        manifest_payload = None
        for candidate in candidates:
            if candidate in manifest_index:
                manifest_payload = manifest_index[candidate]
                break

        if manifest_payload:
            artifact = {
                **artifact,
                **manifest_payload,

                # Champs canoniques utilisés par la comparaison Claude ↔ Codex.
                "canonical_id": manifest_payload.get("manifest_canonical_id"),
                "version": manifest_payload.get("manifest_version"),
                "scope": manifest_payload.get("manifest_scope"),
                "status": manifest_payload.get("manifest_status"),
                "domain": manifest_payload.get("manifest_domain"),
                "project_declared": manifest_payload.get("manifest_project"),
                "source_of_truth": manifest_payload.get("manifest_source_of_truth"),
                "export_target": manifest_payload.get("manifest_export_target"),
            }
        else:
            artifact = {
                **artifact,
                "manifest_found": False,
            }

        enriched.append(artifact)

    return enriched


def manifest_declared_exports(
    manifest: dict[str, Any],
    registry: dict[str, Any],
) -> list[dict[str, Any]]:
    exports: list[dict[str, Any]] = []

    for artifact in manifest.get("artifacts", []):
        for export in artifact.get("exports", []):
            exports.append(
                {
                    "canonical_id": artifact.get("canonical_id"),
                    "name": artifact.get("name"),
                    "version": artifact.get("version"),
                    "target": export.get("target"),
                    "project": artifact.get("project"),
                    "path": export.get("path"),
                    "exists": Path(export.get("path", "")).expanduser().exists()
                    if export.get("path")
                    else False,
                }
            )

    existing_paths = {
        export.get("path")
        for export in exports
        if export.get("path")
    }
    for export in expected_shared_codex_exports(registry, manifest):
        if export.get("path") in existing_paths:
            continue
        exports.append({
            key: value
            for key, value in export.items()
            if key != "artifact"
        })

    return exports


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

def detect_fallback_candidates(content: str, registry: dict[str, Any]) -> list[dict[str, str]]:
    issues: list[dict[str, str]] = []
    lowered = content.lower()

    for pattern in fallback_patterns(registry):
        if pattern.lower() in lowered:
            issues.append(
                {
                    "severity": "warning",
                    "code": "fallback_candidate",
                    "message": f"Pattern suspect détecté : {pattern}",
                }
            )

    return issues


def validate_frontmatter(
    *,
    frontmatter: dict[str, Any],
    artifact_type: str,
    active: bool,
    path: Path,
    registry: dict[str, Any],
) -> list[dict[str, str]]:
    issues: list[dict[str, str]] = []

    if not active:
        return issues

    if path.suffix != ".md":
        return issues

    if not artifact_requires_metadata(artifact_type, registry):
        return issues

    if not frontmatter:
        issues.append(
            {
                "severity": "warning",
                "code": "missing_frontmatter",
                "message": "Frontmatter YAML absent.",
            }
        )
        return issues

    if frontmatter.get("__parse_error__"):
        issues.append(
            {
                "severity": "error",
                "code": "frontmatter_parse_error",
                "message": "Frontmatter YAML invalide.",
            }
        )
        return issues

    for field in required_frontmatter_fields(registry):
        if field not in frontmatter:
            issues.append(
                {
                    "severity": "warning",
                    "code": f"missing_{field}",
                    "message": f"Champ frontmatter manquant : {field}",
                }
            )

    for field in recommended_frontmatter_fields(registry):
        if field not in frontmatter:
            issues.append(
                {
                    "severity": "info",
                    "code": f"missing_recommended_{field}",
                    "message": f"Champ frontmatter recommandé manquant : {field}",
                }
            )

    return issues


def validate_manifest_exports(manifest_exports: list[dict[str, Any]]) -> list[dict[str, Any]]:
    issues: list[dict[str, Any]] = []

    for export in manifest_exports:
        if export.get("policy_error"):
            issues.append(
                {
                    "project": export.get("project"),
                    "artifact": export.get("name"),
                    "artifact_type": "shared_skill_policy",
                    "path": export.get("path"),
                    "severity": "error",
                    "code": export["policy_error"],
                    "message": (
                        f"Invalid install_shared_skills entry: "
                        f"{export.get('canonical_id')}"
                    ),
                }
            )
            continue

        if not export.get("exists"):
            issues.append(
                {
                    "project": export.get("project"),
                    "artifact": export.get("name"),
                    "artifact_type": "manifest_export",
                    "path": export.get("path"),
                    "severity": "warning",
                    "code": "manifest_export_missing",
                    "message": f"Export déclaré dans le manifest introuvable : {export.get('path')}",
                }
            )

    return issues


# ---------------------------------------------------------------------------
# Artifact extraction
# ---------------------------------------------------------------------------

def artifact_from_file(
    *,
    project_name: str,
    project_root: Path,
    artifact_type: str,
    path: Path,
    registry: dict[str, Any],
    active: bool = True,
) -> dict[str, Any]:
    exists = path.exists() or path.is_symlink()
    issues: list[dict[str, str]] = []

    content = ""
    frontmatter: dict[str, Any] = {}
    sha = None
    line_count = 0
    size = 0

    if exists and path.is_file():
        try:
            content = read_text(path)
            frontmatter = extract_frontmatter(content)
            sha = sha256_normalized(content)
            line_count = len(content.splitlines())
            size = path.stat().st_size
        except Exception as exc:
            issues.append(
                {
                    "severity": "error",
                    "code": "read_error",
                    "message": str(exc),
                }
            )

    issues.extend(
        validate_frontmatter(
            frontmatter=frontmatter,
            artifact_type=artifact_type,
            active=active,
            path=path,
            registry=registry,
        )
    )

    if active and content:
        issues.extend(detect_fallback_candidates(content, registry))

    symlink_target = None
    symlink_exists = None

    if path.is_symlink():
        try:
            symlink_target = os.readlink(path)
            symlink_exists = path.resolve(strict=False).exists()
            if not symlink_exists:
                issues.append(
                    {
                        "severity": "error",
                        "code": "broken_symlink",
                        "message": f"Symlink cassé : {symlink_target}",
                    }
                )
        except OSError as exc:
            issues.append(
                {
                    "severity": "error",
                    "code": "symlink_read_error",
                    "message": str(exc),
                }
            )

    declared_name = frontmatter.get("name")
    fallback_name = path.parent.name if path.name == "SKILL.md" else path.stem
    name = declared_name or fallback_name

    return {
        "project": project_name,
        "name": name,
        "normalized_name": normalize_name(name),
        "artifact_type": artifact_type,
        "declared_artifact_type": frontmatter.get("artifact_type"),
        "path": rel_path(path, project_root),
        "absolute_path": str(path),
        "exists": exists,
        "active": active,
        "is_symlink": path.is_symlink(),
        "symlink_target": symlink_target,
        "symlink_exists": symlink_exists,
        "realpath": str(path.resolve(strict=False)) if exists else None,

        # Runtime frontmatter.
        "runtime_name": frontmatter.get("name"),
        "runtime_description": frontmatter.get("description"),
        "frontmatter": frontmatter,

        # Canonical metadata — initially empty, filled from skills-manifest.yml.
        "version": None,
        "scope": None,
        "status": None,
        "domain": None,
        "project_declared": None,
        "canonical_id": None,
        "source_of_truth": None,
        "canonical_hash": None,
        "export_target": None,
        "export_hash": None,

        "sha256": sha,
        "size": size,
        "line_count": line_count,
        "issues": issues,
    }


# ---------------------------------------------------------------------------
# Scanners
# ---------------------------------------------------------------------------

def scan_codex_skills(
    project_name: str,
    root: Path,
    registry: dict[str, Any],
) -> list[dict[str, Any]]:
    base_rel = registry_project_path(registry, project_name, "codex_skills")
    if not base_rel:
        return []

    base = root / base_rel
    if not base.exists():
        return []

    artifacts = []
    for skill_md in sorted(base.glob("*/SKILL.md")):
        if is_ignored(skill_md, registry):
            continue

        artifacts.append(
            artifact_from_file(
                project_name=project_name,
                project_root=root,
                artifact_type="codex_skill",
                path=skill_md,
                registry=registry,
                active=True,
            )
        )

    return artifacts


def scan_claude_commands(
    project_name: str,
    root: Path,
    registry: dict[str, Any],
) -> list[dict[str, Any]]:
    base_rel = registry_project_path(registry, project_name, "claude_commands")
    if not base_rel:
        return []

    base = root / base_rel
    if not base.exists():
        return []

    artifacts = []

    for command in sorted(base.glob("*.md*")):
        if is_ignored(command, registry):
            continue

        active = command.suffix == ".md" and not is_backup(command, registry)

        artifacts.append(
            artifact_from_file(
                project_name=project_name,
                project_root=root,
                artifact_type="claude_command",
                path=command,
                registry=registry,
                active=active,
            )
        )

    return artifacts


def scan_simple_dir(
    project_name: str,
    root: Path,
    registry: dict[str, Any],
    path_key: str,
    artifact_type: str,
    pattern: str = "*.md",
) -> list[dict[str, Any]]:
    base_rel = registry_project_path(registry, project_name, path_key)
    if not base_rel:
        return []

    base = root / base_rel
    if not base.exists():
        return []

    artifacts = []
    for path in sorted(base.glob(pattern)):
        if path.is_dir():
            continue
        if is_ignored(path, registry):
            continue

        artifacts.append(
            artifact_from_file(
                project_name=project_name,
                project_root=root,
                artifact_type=artifact_type,
                path=path,
                registry=registry,
                active=True,
            )
        )

    return artifacts


def scan_root_file(
    project_name: str,
    root: Path,
    registry: dict[str, Any],
    path_key: str,
    artifact_type: str,
) -> list[dict[str, Any]]:
    rel = registry_project_path(registry, project_name, path_key)
    if not rel:
        return []

    path = root / rel
    if not path.exists():
        return []

    return [
        artifact_from_file(
            project_name=project_name,
            project_root=root,
            artifact_type=artifact_type,
            path=path,
            registry=registry,
            active=True,
        )
    ]


# ---------------------------------------------------------------------------
# Pairing
# ---------------------------------------------------------------------------

def pair_issue_from_metadata(
    claude: dict[str, Any] | None,
    codex: dict[str, Any] | None,
) -> str:
    if claude and not codex:
        return "missing_codex_skill"

    if codex and not claude:
        return "missing_claude_command"

    if not claude or not codex:
        return "unknown_pair_state"

    claude_canonical = claude.get("canonical_id")
    codex_canonical = codex.get("canonical_id")

    claude_version = claude.get("version")
    codex_version = codex.get("version")

    claude_source = claude.get("source_of_truth")
    codex_source = codex.get("source_of_truth")

    if not claude_canonical and not codex_canonical:
        if claude.get("sha256") == codex.get("sha256"):
            return "ok_same_export_hash"
        return "semantic_review_needed"

    if claude_canonical != codex_canonical:
        return "drift_canonical_id_mismatch"

    if claude_version != codex_version:
        return "drift_version_mismatch"

    if claude_source != codex_source:
        return "drift_source_mismatch"

    return "ok_same_canonical"


def is_explicitly_shared(artifact: dict[str, Any] | None) -> bool:
    if not artifact:
        return False

    canonical_id = str(artifact.get("canonical_id") or "")
    return canonical_id.startswith("shared.") or artifact.get("scope") == "shared"


def shared_cross_project_match(
    artifact: dict[str, Any],
    candidates: list[dict[str, Any]],
) -> dict[str, Any] | None:
    if not is_explicitly_shared(artifact):
        return None

    shared_candidates = [
        candidate
        for candidate in candidates
        if candidate.get("project") != artifact.get("project")
        and is_explicitly_shared(candidate)
    ]

    canonical_id = artifact.get("canonical_id")
    if canonical_id:
        same_canonical = [
            candidate
            for candidate in shared_candidates
            if candidate.get("canonical_id") == canonical_id
        ]
        if same_canonical:
            shared_candidates = same_canonical

    if not shared_candidates:
        return None

    return sorted(
        shared_candidates,
        key=lambda candidate: (
            str(candidate.get("project") or ""),
            str(candidate.get("path") or ""),
        ),
    )[0]


def pairing_exception(
    registry: dict[str, Any],
    *,
    project: str,
    name: str,
    artifact_type: str,
) -> dict[str, Any] | None:
    normalized_name = normalize_name(name)

    for exception in registry.get("pairing_exceptions", []):
        if (
            exception.get("project") == project
            and exception.get("artifact_type") == artifact_type
            and normalize_name(exception.get("name", "")) == normalized_name
        ):
            return exception

    return None


def apply_pairing_exception(
    *,
    registry: dict[str, Any],
    project: str,
    name: str,
    claude: dict[str, Any] | None,
    codex: dict[str, Any] | None,
    issue: str,
) -> tuple[str, dict[str, Any] | None]:
    if issue == "missing_codex_skill" and claude and not is_explicitly_shared(claude):
        exception = pairing_exception(
            registry,
            project=project,
            name=name,
            artifact_type="claude_command",
        )
        if exception and exception.get("expected_status") in {
            "claude_only_project_command",
            "expected_claude_only",
        }:
            return "expected_claude_only", exception

    if issue == "missing_claude_command" and codex and not is_explicitly_shared(codex):
        exception = pairing_exception(
            registry,
            project=project,
            name=name,
            artifact_type="codex_skill",
        )
        if exception and exception.get("expected_status") in {
            "codex_only_project_skill",
            "expected_codex_only",
        }:
            return "expected_codex_only", exception

    return issue, None


def build_pairs(
    artifacts: list[dict[str, Any]],
    registry: dict[str, Any] | None = None,
) -> list[dict[str, Any]]:
    registry = registry or {}
    claude = [
        a
        for a in artifacts
        if a["artifact_type"] == "claude_command" and a["active"]
    ]

    codex = [
        a
        for a in artifacts
        if a["artifact_type"] == "codex_skill" and a["active"]
    ]

    by_codex_key = {
        (a["project"], a["normalized_name"]): a
        for a in codex
    }
    by_claude_key = {
        (a["project"], a["normalized_name"]): a
        for a in claude
    }
    codex_by_name: dict[str, list[dict[str, Any]]] = {}
    claude_by_name: dict[str, list[dict[str, Any]]] = {}

    for artifact in codex:
        codex_by_name.setdefault(artifact["normalized_name"], []).append(artifact)

    for artifact in claude:
        claude_by_name.setdefault(artifact["normalized_name"], []).append(artifact)

    pairs = []
    all_keys = sorted(set(by_claude_key) | set(by_codex_key))

    for project, name in all_keys:
        c = by_claude_key.get((project, name))
        x = by_codex_key.get((project, name))

        if c and not x:
            x = shared_cross_project_match(c, codex_by_name.get(name, []))
        elif x and not c:
            c = shared_cross_project_match(x, claude_by_name.get(name, []))

        raw_issue = pair_issue_from_metadata(c, x)
        issue, exception = apply_pairing_exception(
            registry=registry,
            project=project,
            name=name,
            claude=c,
            codex=x,
            issue=raw_issue,
        )

        pairs.append(
            {
                "project": project,
                "name": name,
                "claude_project": c.get("project") if c else None,
                "codex_project": x.get("project") if x else None,
                "claude_path": c["path"] if c else None,
                "codex_path": x["path"] if x else None,
                "claude_version": c.get("version") if c else None,
                "codex_version": x.get("version") if x else None,
                "claude_canonical_id": c.get("canonical_id") if c else None,
                "codex_canonical_id": x.get("canonical_id") if x else None,
                "claude_source_of_truth": c.get("source_of_truth") if c else None,
                "codex_source_of_truth": x.get("source_of_truth") if x else None,
                "claude_manifest_found": c.get("manifest_found") if c else None,
                "codex_manifest_found": x.get("manifest_found") if x else None,
                "claude_sha256": c.get("sha256") if c else None,
                "codex_sha256": x.get("sha256") if x else None,
                "same_raw_hash": (
                    c.get("sha256") == x.get("sha256")
                    if c and x
                    else None
                ),
                "raw_issue": raw_issue,
                "issue": issue,
                "exception_reason": exception.get("reason") if exception else None,
            }
        )

    return pairs


def pair_severity(issue: str) -> str:
    if issue in {"ok_same_canonical", "ok_same_export_hash"}:
        return "ok"

    if issue in {"expected_claude_only", "expected_codex_only"}:
        return "expected"

    if issue in {"semantic_review_needed"}:
        return "info"

    if issue in {"missing_codex_skill", "missing_claude_command"}:
        return "warning"

    if issue.startswith("drift_"):
        return "error"

    return "warning"


# ---------------------------------------------------------------------------
# Summary / reporting
# ---------------------------------------------------------------------------

def summarize(
    artifacts: list[dict[str, Any]],
    pairs: list[dict[str, Any]],
    manifest_exports: list[dict[str, Any]],
    project_names: list[str],
) -> dict[str, Any]:
    def count_type(t: str) -> int:
        return len(
            [
                a
                for a in artifacts
                if a["artifact_type"] == t and a["active"]
            ]
        )

    issues = []

    for artifact in artifacts:
        for issue in artifact.get("issues", []):
            issues.append(
                {
                    "project": artifact["project"],
                    "artifact": artifact["name"],
                    "artifact_type": artifact["artifact_type"],
                    "path": artifact["path"],
                    **issue,
                }
            )

    for issue in validate_manifest_exports(manifest_exports):
        issues.append(issue)

    for pair in pairs:
        severity = pair_severity(pair["issue"])
        if severity in {"ok", "expected"}:
            continue

        issues.append(
            {
                "project": pair.get("project"),
                "artifact": pair["name"],
                "artifact_type": "pair",
                "path": pair["claude_path"] or pair["codex_path"],
                "severity": severity,
                "code": pair["issue"],
                "message": pair["issue"],
            }
        )

    pair_counts: dict[str, int] = {}
    for pair in pairs:
        pair_counts[pair["issue"]] = pair_counts.get(pair["issue"], 0) + 1

    manifest_covered = len([a for a in artifacts if a.get("manifest_found")])
    manifest_exports_missing = len([e for e in manifest_exports if not e.get("exists")])
    project_summaries: dict[str, dict[str, int]] = {}
    root_doc_types = {
        "agents_file",
        "claude_file",
        "project_config",
        "architecture_file",
    }

    for project_name in project_names:
        project_artifacts = [
            artifact
            for artifact in artifacts
            if artifact.get("project") == project_name and artifact.get("active")
        ]

        def project_count(artifact_type: str) -> int:
            return sum(
                artifact["artifact_type"] == artifact_type
                for artifact in project_artifacts
            )

        project_summaries[project_name] = {
            "artifacts": len(project_artifacts),
            "codex_skills": project_count("codex_skill"),
            "claude_commands": project_count("claude_command"),
            "claude_rules": project_count("claude_rule"),
            "claude_hooks": project_count("claude_hook"),
            "codex_hooks": project_count("codex_hook"),
            "root_docs": sum(
                artifact["artifact_type"] in root_doc_types
                for artifact in project_artifacts
            ),
            "issues": sum(
                issue.get("project") == project_name
                for issue in issues
            ),
        }

    return {
        "counts": {
            "codex_skills": count_type("codex_skill"),
            "claude_commands": count_type("claude_command"),
            "claude_rules": count_type("claude_rule"),
            "claude_strategy_profiles": count_type("claude_strategy_profile"),
            "claude_hooks": count_type("claude_hook"),
            "codex_hooks": count_type("codex_hook"),
            "root_docs": len(
                [
                    a
                    for a in artifacts
                    if a["artifact_type"]
                    in {
                        "agents_file",
                        "claude_file",
                        "project_config",
                        "architecture_file",
                    }
                ]
            ),
            "manifest_covered_artifacts": manifest_covered,
            "manifest_declared_exports": len(manifest_exports),
            "manifest_missing_exports": manifest_exports_missing,
        },
        "pair_counts": pair_counts,
        "projects": project_summaries,
        "issues_count": len(issues),
        "issues": issues,
    }


def write_markdown_report(report: dict[str, Any], output_path: Path) -> None:
    summary = report["summary"]
    artifacts = report["artifacts"]
    pairs = report["pairs"]
    manifest_exports = report["manifest_exports"]

    lines: list[str] = []

    lines.append("# AI Inventory Report")
    lines.append("")
    lines.append(f"Generated: {report['generated_at']}")
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append("| Metric | Count |")
    lines.append("|---|---:|")
    for key, value in summary["counts"].items():
        lines.append(f"| {key} | {value} |")
    lines.append(f"| issues | {summary['issues_count']} |")
    lines.append("")

    lines.append("## Projects summary")
    lines.append("")
    lines.append(
        "| Project | Codex skills | Claude commands | Claude rules | Claude hooks | Codex hooks | Root docs | Issues |"
    )
    lines.append("|---|---:|---:|---:|---:|---:|---:|---:|")
    for project, counts in summary["projects"].items():
        lines.append(
            "| {project} | {codex_skills} | {claude_commands} | {claude_rules} | {claude_hooks} | {codex_hooks} | {root_docs} | {issues} |".format(
                project=project,
                **counts,
            )
        )
    lines.append("")

    lines.append("## Pair status summary")
    lines.append("")
    lines.append("| Pair status | Count | Meaning |")
    lines.append("|---|---:|---|")

    meanings = {
        "ok_same_canonical": "Claude and Codex are linked to the same canonical manifest entry.",
        "ok_same_export_hash": "Claude and Codex exports are byte-identical after normalization.",
        "semantic_review_needed": "Claude and Codex share a name but are not yet linked to canonical metadata.",
        "missing_codex_skill": "Claude command exists, Codex skill is missing.",
        "missing_claude_command": "Codex skill exists, Claude command is missing.",
        "expected_claude_only": "Project-specific Claude command intentionally has no Codex skill.",
        "expected_codex_only": "Project-specific Codex skill intentionally has no Claude command.",
        "drift_canonical_id_mismatch": "Claude and Codex declare different canonical IDs.",
        "drift_version_mismatch": "Claude and Codex declare different versions.",
        "drift_source_mismatch": "Claude and Codex declare different source_of_truth paths.",
    }

    for status, count in sorted(summary["pair_counts"].items()):
        lines.append(f"| {status} | {count} | {meanings.get(status, '')} |")
    lines.append("")

    lines.append("## Claude ↔ Codex pairs")
    lines.append("")
    lines.append(
        "| Project | Name | Claude project | Claude | Codex project | Codex | Canonical ID | Version | Same raw hash | Issue |"
    )
    lines.append("|---|---|---|---|---|---|---|---|---|---|")

    for pair in pairs:
        canonical_id = pair.get("claude_canonical_id") or pair.get("codex_canonical_id") or ""
        version = pair.get("claude_version") or pair.get("codex_version") or ""
        same_raw_hash = pair.get("same_raw_hash")
        same_raw_hash_label = "" if same_raw_hash is None else str(same_raw_hash).lower()

        lines.append(
            "| {project} | {name} | {claude_project} | {claude} | {codex_project} | {codex} | {canonical} | {version} | {same_hash} | {issue} |".format(
                project=pair["project"],
                name=pair["name"],
                claude_project=pair.get("claude_project") or "",
                claude=pair["claude_path"] or "",
                codex_project=pair.get("codex_project") or "",
                codex=pair["codex_path"] or "",
                canonical=canonical_id,
                version=version,
                same_hash=same_raw_hash_label,
                issue=pair["issue"] or "",
            )
        )

    lines.append("")
    lines.append("## Manifest exports")
    lines.append("")
    lines.append("| Canonical ID | Target | Path | Exists |")
    lines.append("|---|---|---|---|")

    for export in manifest_exports:
        lines.append(
            "| {canonical_id} | {target} | {path} | {exists} |".format(
                canonical_id=export.get("canonical_id") or "",
                target=export.get("target") or "",
                path=export.get("path") or "",
                exists=str(export.get("exists")).lower(),
            )
        )

    lines.append("")
    lines.append("## Issues")
    lines.append("")
    lines.append("| Severity | Code | Artifact | Path | Message |")
    lines.append("|---|---|---|---|---|")

    for issue in summary["issues"]:
        lines.append(
            "| {severity} | {code} | {artifact} | {path} | {message} |".format(
                severity=issue.get("severity", ""),
                code=issue.get("code", ""),
                artifact=issue.get("artifact", ""),
                path=issue.get("path", ""),
                message=str(issue.get("message", "")).replace("|", "\\|"),
            )
        )

    lines.append("")
    lines.append("## Symlinks")
    lines.append("")
    lines.append("| Artifact | Type | Path | Target | Status |")
    lines.append("|---|---|---|---|---|")

    for artifact in artifacts:
        if artifact.get("is_symlink"):
            lines.append(
                "| {name} | {artifact_type} | {path} | {target} | {status} |".format(
                    name=artifact["name"],
                    artifact_type=artifact["artifact_type"],
                    path=artifact["path"],
                    target=artifact.get("symlink_target") or "",
                    status="ok" if artifact.get("symlink_exists") else "broken",
                )
            )

    lines.append("")
    lines.append("## Recommended next actions")
    lines.append("")
    lines.append("1. Vérifier que `implement`, `new-strategy` et `update-strategy` sont en `ok_same_canonical`.")
    lines.append("2. Ajouter le frontmatter runtime minimal aux exports encore actifs sans `name` / `description`.")
    lines.append("3. Corriger `update-strategy` pour supprimer les fallbacks implicites.")
    lines.append("4. Créer ensuite `sync_skills.py` pour générer les exports depuis `canonical.md`.")
    lines.append("")

    write_text(output_path, "\n".join(lines))


def console_path(path: Path) -> str:
    try:
        return str(path.relative_to(Path.cwd()))
    except ValueError:
        return str(path)


def inventory_status(summary: dict[str, Any]) -> str:
    if any(issue.get("severity") == "error" for issue in summary["issues"]):
        return "FAIL"
    if summary["issues_count"] > 0:
        return "WARN"
    return "OK"


def print_inventory_dashboard(
    report: dict[str, Any],
    *,
    json_path: Path,
    markdown_path: Path,
) -> None:
    summary = report["summary"]
    status = inventory_status(summary)

    print(f"AI Inventory — {status}")
    print()
    print("Projects")
    headers = (
        "project",
        "artifacts",
        "issues",
        "claude_commands",
        "codex_skills",
        "claude_rules",
        "claude_hooks",
        "codex_hooks",
        "root_docs",
    )
    rows = [
        (project, *(str(counts[header]) for header in headers[1:]))
        for project, counts in summary["projects"].items()
    ]
    widths = [
        max(len(headers[index]), *(len(row[index]) for row in rows))
        for index in range(len(headers))
    ]
    print("  " + "  ".join(
        header.ljust(widths[index])
        for index, header in enumerate(headers)
    ))
    print("  " + "  ".join("-" * width for width in widths))
    for row in rows:
        print("  " + "  ".join(
            value.ljust(widths[index]) if index == 0 else value.rjust(widths[index])
            for index, value in enumerate(row)
        ))

    print()
    print("Pairing")
    preferred_statuses = [
        "ok_same_canonical",
        "ok_same_export_hash",
        "missing_codex_skill",
        "missing_claude_command",
        "expected_claude_only",
        "expected_codex_only",
        "semantic_review_needed",
        "drift_canonical_id_mismatch",
        "drift_version_mismatch",
        "drift_source_mismatch",
    ]
    drift_statuses = sorted(
        status
        for status in summary["pair_counts"]
        if status.startswith("drift_") and status not in preferred_statuses
    )
    other_statuses = sorted(
        status
        for status in summary["pair_counts"]
        if status not in preferred_statuses and status not in drift_statuses
    )
    for pair_status in preferred_statuses + drift_statuses + other_statuses:
        print(f"  {pair_status:<32} {summary['pair_counts'].get(pair_status, 0):>4}")

    expected_pairs = [
        pair
        for pair in report["pairs"]
        if pair_severity(pair["issue"]) == "expected"
    ]
    problem_pairs = [
        pair
        for pair in report["pairs"]
        if pair_severity(pair["issue"]) not in {"ok", "expected"}
    ]
    if expected_pairs:
        print()
        print("Pairing exceptions")
        current_project = None
        for pair in expected_pairs:
            if pair["project"] != current_project:
                current_project = pair["project"]
                print(f"  {current_project}")
            path = pair["claude_path"] or pair["codex_path"] or ""
            reason = pair.get("exception_reason") or ""
            print(f"    {pair['name']} | {pair['issue']} | {path}")
            if reason:
                print(f"      {reason}")

    if problem_pairs:
        print()
        print("Pairing problems")
        current_project = None
        for pair in problem_pairs:
            if pair["project"] != current_project:
                current_project = pair["project"]
                print(f"  {current_project}")
            path = pair["claude_path"] or pair["codex_path"] or ""
            print(f"    {pair['name']} | {pair['issue']} | {path}")

    print()
    print("Reports")
    print(f"  Markdown  {console_path(markdown_path)}")
    print(f"  JSON      {console_path(json_path)}")

    next_actions: list[str] = []
    error_issues = [
        issue for issue in summary["issues"] if issue.get("severity") == "error"
    ]
    if error_issues:
        first = error_issues[0]
        next_actions.append(
            f"Fix {first.get('project') or 'global'}: "
            f"{first.get('code')} in {first.get('path')}"
        )
    if problem_pairs:
        affected_projects = sorted({
            str(pair.get("project") or "global")
            for pair in problem_pairs
        })
        next_actions.append(
            "Review non-OK pairing for " + ", ".join(affected_projects)
        )
    if summary["issues_count"] > 0:
        next_actions.append(f"Open {console_path(markdown_path)} for all issues")
    if not next_actions:
        next_actions.append("No action required")

    print()
    print("Next")
    for index, action in enumerate(next_actions[:3], start=1):
        print(f"  {index}. {action}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--registry", default=DEFAULT_REGISTRY)
    args = parser.parse_args()

    registry_path = Path(args.registry)
    registry = load_yaml(registry_path)

    report_dir = Path(registry["settings"]["report_dir"])
    report_dir.mkdir(parents=True, exist_ok=True)

    manifest_path = get_manifest_path(registry)
    manifest = load_yaml(manifest_path) if manifest_path else {}
    manifest_index = build_manifest_index(manifest, registry)
    manifest_exports = manifest_declared_exports(manifest, registry)

    artifacts: list[dict[str, Any]] = []
    project_names: list[str] = []

    for project in registry.get("projects", []):
        if not project.get("enabled"):
            continue

        project_name = project["name"]
        project_names.append(project_name)
        root = Path(project["root"])

        artifacts.extend(scan_codex_skills(project_name, root, registry))
        artifacts.extend(scan_claude_commands(project_name, root, registry))
        artifacts.extend(
            scan_simple_dir(
                project_name,
                root,
                registry,
                "claude_rules",
                "claude_rule",
            )
        )
        artifacts.extend(
            scan_simple_dir(
                project_name,
                root,
                registry,
                "claude_strategy_profiles",
                "claude_strategy_profile",
            )
        )
        artifacts.extend(
            scan_simple_dir(
                project_name,
                root,
                registry,
                "claude_hooks",
                "claude_hook",
                pattern="*",
            )
        )
        artifacts.extend(
            scan_simple_dir(
                project_name,
                root,
                registry,
                "codex_hooks",
                "codex_hook",
                pattern="*",
            )
        )
        artifacts.extend(
            scan_root_file(
                project_name,
                root,
                registry,
                "agents_file",
                "agents_file",
            )
        )
        artifacts.extend(
            scan_root_file(
                project_name,
                root,
                registry,
                "claude_file",
                "claude_file",
            )
        )
        artifacts.extend(
            scan_root_file(
                project_name,
                root,
                registry,
                "project_config",
                "project_config",
            )
        )
        artifacts.extend(
            scan_root_file(
                project_name,
                root,
                registry,
                "architecture_file",
                "architecture_file",
            )
        )

    artifacts = enrich_artifacts_from_manifest(artifacts, manifest_index)

    pairs = build_pairs(artifacts, registry)
    summary = summarize(artifacts, pairs, manifest_exports, project_names)

    report = {
        "generated_at": dt.datetime.now().isoformat(timespec="seconds"),
        "registry": str(registry_path),
        "manifest": str(manifest_path) if manifest_path else None,
        "artifacts": artifacts,
        "manifest_exports": manifest_exports,
        "pairs": pairs,
        "summary": summary,
    }

    json_path = report_dir / "ai-inventory.latest.json"
    md_path = report_dir / "ai-inventory.latest.md"

    write_text(
        json_path,
        json.dumps(report, indent=2, ensure_ascii=False),
    )

    write_markdown_report(report, md_path)

    print_inventory_dashboard(
        report,
        json_path=json_path,
        markdown_path=md_path,
    )


if __name__ == "__main__":
    main()
