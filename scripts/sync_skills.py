#!/usr/bin/env python3

from __future__ import annotations

import argparse
import difflib
import shutil
from pathlib import Path
from typing import Any

import yaml


DEFAULT_MANIFEST = "/Users/vincentdesbrosses/Documents/Misc/ai-system/skills-manifest.yml"
DEFAULT_REGISTRY = "/Users/vincentdesbrosses/Documents/Misc/ai-system/skills-registry.yml"


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


def manifest_by_canonical_id(manifest: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        artifact["canonical_id"]: artifact
        for artifact in manifest.get("artifacts", [])
        if artifact.get("canonical_id")
    }


def normalize_shared_targets(targets: Any) -> set[str]:
    if targets is None:
        return set()

    if isinstance(targets, str):
        raw = targets.replace(",", " ").split()
    else:
        raw = list(targets)

    normalized = set()
    for target in raw:
        value = str(target).strip().lower()
        if not value:
            continue
        if value == "both":
            return {"claude", "codex"}
        if value in {"claude", "codex"}:
            normalized.add(value)
    return normalized


def project_shared_targets(project: dict[str, Any]) -> set[str]:
    targets = normalize_shared_targets(project.get("install_shared_targets"))
    return targets or {"codex"}


def shared_export_descriptor(
    *,
    project: dict[str, Any],
    artifact: dict[str, Any],
    target: str,
) -> dict[str, Any] | None:
    project_root = project.get("root")
    project_name = project.get("name")
    project_paths = project.get("paths", {})

    if target == "codex":
        target_path = project_paths.get("codex_skills")
        if not project_root or not target_path:
            return {
                "status": "error",
                "canonical_id": artifact.get("canonical_id"),
                "target": "codex_skill",
                "path": "",
                "message": f"{project_name}: missing root or paths.codex_skills",
            }

        return {
            "canonical_id": artifact.get("canonical_id"),
            "artifact": artifact,
            "project": project_name,
            "target": "codex_skill",
            "path": str(
                Path(project_root)
                / target_path
                / artifact["name"]
                / "SKILL.md"
            ),
        }

    if target == "claude":
        target_path = project_paths.get("claude_commands")
        if not project_root or not target_path:
            return {
                "status": "error",
                "canonical_id": artifact.get("canonical_id"),
                "target": "claude_command",
                "path": "",
                "message": f"{project_name}: missing root or paths.claude_commands",
            }

        return {
            "canonical_id": artifact.get("canonical_id"),
            "artifact": artifact,
            "project": project_name,
            "target": "claude_command",
            "path": str(Path(project_root) / target_path / f"{artifact['name']}.md"),
        }

    return {
        "status": "error",
        "canonical_id": artifact.get("canonical_id"),
        "target": target,
        "path": "",
        "message": f"{project_name}: unsupported shared target {target}",
    }


def registry_shared_exports(
    registry: dict[str, Any],
    manifest: dict[str, Any],
    *,
    project_name: str | None = None,
    targets: Any = None,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    artifacts_by_id = manifest_by_canonical_id(manifest)
    exports: list[dict[str, Any]] = []
    errors: list[dict[str, Any]] = []
    requested_targets = normalize_shared_targets(targets) or {"codex"}

    for project in registry.get("projects", []):
        if not project.get("enabled"):
            continue
        if project_name and project.get("name") != project_name:
            continue
        project_label = project.get("name")

        for canonical_id in project.get("install_shared_skills", []):
            artifact = artifacts_by_id.get(canonical_id)

            if not str(canonical_id).startswith("shared."):
                errors.append({
                    "status": "error",
                    "canonical_id": canonical_id,
                    "target": "shared_export",
                    "path": "",
                    "message": (
                        f"{project_label}: install_shared_skills only accepts shared.* canonicals"
                    ),
                })
                continue

            if not artifact:
                errors.append({
                    "status": "error",
                    "canonical_id": canonical_id,
                    "target": "shared_export",
                    "path": "",
                    "message": f"{project_label}: canonical not found in manifest",
                })
                continue

            if artifact.get("scope") != "shared":
                errors.append({
                    "status": "error",
                    "canonical_id": canonical_id,
                    "target": "shared_export",
                    "path": "",
                    "message": f"{project_label}: canonical scope is not shared",
                })
                continue

            allowed_targets = project_shared_targets(project)
            for target in sorted(requested_targets & allowed_targets):
                if target == "codex" and not artifact.get("compatibility", {}).get("codex"):
                    errors.append({
                        "status": "error",
                        "canonical_id": canonical_id,
                        "target": "codex_skill",
                        "path": "",
                        "message": f"{project_label}: canonical is not Codex-compatible",
                    })
                    continue

                if target == "claude" and not artifact.get("compatibility", {}).get("claude_code"):
                    errors.append({
                        "status": "error",
                        "canonical_id": canonical_id,
                        "target": "claude_command",
                        "path": "",
                        "message": f"{project_label}: canonical is not Claude-compatible",
                    })
                    continue

                descriptor = shared_export_descriptor(
                    project=project,
                    artifact=artifact,
                    target=target,
                )
                if descriptor and descriptor.get("status") == "error":
                    errors.append(descriptor)
                    continue
                if descriptor:
                    exports.append(descriptor)

    return exports, errors


def registry_shared_codex_exports(
    registry: dict[str, Any],
    manifest: dict[str, Any],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    return registry_shared_exports(registry, manifest, targets={"codex"})


def registry_shared_claude_exports(
    registry: dict[str, Any],
    manifest: dict[str, Any],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    return registry_shared_exports(registry, manifest, targets={"claude"})


def path_is_within(path: Path, root: Path) -> bool:
    try:
        path.resolve(strict=False).relative_to(root.resolve(strict=False))
        return True
    except ValueError:
        return False


def manifest_codex_export_policy_error(
    *,
    artifact: dict[str, Any],
    export_path: Path,
    registry: dict[str, Any],
    allowed_shared_paths: set[str],
) -> str | None:
    scope = artifact.get("scope")
    canonical_id = str(artifact.get("canonical_id") or "")

    if scope == "shared":
        if str(export_path) not in allowed_shared_paths:
            return (
                f"{canonical_id}: local Codex export is not allowed by "
                "install_shared_skills"
            )
        return None

    if scope != "project":
        return f"{canonical_id}: unsupported scope for Codex export: {scope}"

    project_name = artifact.get("project")
    project = next(
        (
            candidate
            for candidate in registry.get("projects", [])
            if candidate.get("name") == project_name
        ),
        None,
    )
    if not project or not project.get("root"):
        return f"{canonical_id}: declared project is missing from registry"

    expected_prefix = f"{str(project_name).lower()}."
    if not canonical_id.lower().startswith(expected_prefix):
        return (
            f"{canonical_id}: canonical prefix does not match project "
            f"{project_name}"
        )

    if not path_is_within(export_path, Path(project["root"])):
        return (
            f"{canonical_id}: project export must stay inside "
            f"{project['root']}"
        )

    return None


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default=DEFAULT_MANIFEST)
    parser.add_argument("--registry", default=DEFAULT_REGISTRY)
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
    registry = load_yaml(Path(args.registry))
    only = set(args.only)

    results: list[dict[str, Any]] = []
    registry_exports, registry_errors = registry_shared_codex_exports(
        registry,
        manifest,
    )
    results.extend(registry_errors)
    registry_export_paths = {
        export["path"]
        for export in registry_exports
    }

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
            if str(export_path) in registry_export_paths:
                continue
            if export.get("target") == "codex_skill":
                policy_error = manifest_codex_export_policy_error(
                    artifact=artifact,
                    export_path=export_path,
                    registry=registry,
                    allowed_shared_paths=registry_export_paths,
                )
                if policy_error:
                    results.append({
                        "status": "error",
                        "canonical_id": canonical_id,
                        "target": export.get("target"),
                        "path": str(export_path),
                        "message": policy_error,
                    })
                    continue

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

    for export in registry_exports:
        canonical_id = export["canonical_id"]
        if only and canonical_id not in only:
            continue

        artifact = export["artifact"]
        description = artifact.get("description")
        source_of_truth = artifact.get("source_of_truth")

        if not description or not source_of_truth:
            results.append({
                "status": "error",
                "canonical_id": canonical_id,
                "target": export["target"],
                "path": export["path"],
                "message": (
                    "Missing description"
                    if not description
                    else "Missing source_of_truth"
                ),
            })
            continue

        result = sync_export(
            canonical_path=Path(source_of_truth),
            export_path=Path(export["path"]),
            name=artifact["name"],
            description=description,
            apply=args.apply,
            backup=not args.no_backup,
            show_diff=args.diff,
        )
        result["canonical_id"] = canonical_id
        result["target"] = export["target"]
        result["project"] = export["project"]
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
