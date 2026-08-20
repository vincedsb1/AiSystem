#!/usr/bin/env python3
"""
Add a new project to skills-registry.yml

Usage:
  python scripts/add_project.py --project <name> --path <path> --targets <codex|claude|both>
"""

import sys
import argparse
import os
from pathlib import Path

try:
    import yaml
except ImportError:
    print("Error: pyyaml required. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)


def load_registry(registry_path):
    """Load YAML registry"""
    with open(registry_path, 'r') as f:
        return yaml.safe_load(f) or {}


def save_registry(registry, registry_path):
    """Save YAML registry"""
    with open(registry_path, 'w') as f:
        yaml.dump(registry, f, default_flow_style=False, sort_keys=False)


def project_exists(registry, project_name, project_path=None):
    """Check if project already exists (case-insensitive name or same path)"""
    if 'projects' not in registry:
        return False
    for proj in registry['projects']:
        # Check case-insensitive name match
        if proj.get('name', '').lower() == project_name.lower():
            return True
        # Check if same path (prevents duplicates with different names)
        if project_path and proj.get('root') == os.path.abspath(project_path):
            return True
    return False


def get_install_shared_targets(targets):
    """Get install_shared_targets based on target selection"""
    if targets == 'codex':
        return ['codex']
    elif targets == 'claude':
        return ['claude']
    elif targets == 'both':
        return ['codex', 'claude']
    else:
        raise ValueError(f"Invalid targets: {targets}")


def get_install_shared_skills():
    """Get standard shared skills list"""
    return [
        'shared.ai-post-task-review',
        'shared.commit',
        'shared.create-doc',
        'shared.implement',
        'shared.optimize-claude-md',
        'shared.spec-0-feedback',
        'shared.spec-1-intake',
        'shared.spec-2-draft',
        'shared.spec-3-audit',
        'shared.spec-4-challenge',
        'shared.spec-5-revise',
        'shared.test',
        'shared.ui-review'
    ]


def get_default_paths():
    """Get default path structure for a project"""
    return {
        'codex_skills': '.agents/skills',
        'claude_commands': '.claude/commands',
        'claude_rules': '.claude/rules',
        'claude_strategy_profiles': '.claude/strategy-profiles',
        'claude_hooks': '.claude/hooks',
        'codex_hooks': '.codex/hooks',
        'agents_file': 'AGENTS.md',
        'claude_file': 'CLAUDE.md',
        'project_config': '.claude/project-config.md',
        'architecture_file': 'docs/ARCHITECTURE.md'
    }


def add_project(registry, project_name, project_path, targets):
    """Add project to registry"""
    if not os.path.isdir(project_path):
        raise FileNotFoundError(f"Project path does not exist: {project_path}")

    if project_exists(registry, project_name, project_path):
        raise ValueError(f"Project already exists: {project_name}")

    # Create projects list if it doesn't exist
    if 'projects' not in registry:
        registry['projects'] = []

    # Create new project entry
    new_project = {
        'name': project_name,
        'root': project_path,
        'enabled': True,
        'install_shared_targets': get_install_shared_targets(targets),
        'install_shared_skills': get_install_shared_skills(),
        'paths': get_default_paths()
    }

    # Add to projects list
    registry['projects'].append(new_project)

    return registry


def main():
    parser = argparse.ArgumentParser(description='Add a new project to skills-registry.yml')
    parser.add_argument('--project', required=True, help='Project name')
    parser.add_argument('--path', required=True, help='Project path (absolute)')
    parser.add_argument('--targets', required=True, choices=['codex', 'claude', 'both'],
                       help='Installation targets')

    args = parser.parse_args()

    # Get registry path
    ai_system_root = Path(__file__).parent.parent
    registry_path = ai_system_root / 'skills-registry.yml'

    if not registry_path.exists():
        print(f"Error: Registry not found at {registry_path}", file=sys.stderr)
        sys.exit(1)

    try:
        # Load registry
        registry = load_registry(str(registry_path))

        # Add project
        registry = add_project(registry, args.project, args.path, args.targets)

        # Save registry
        save_registry(registry, str(registry_path))

        print(f"✓ Project '{args.project}' added successfully")
        print(f"  Path: {args.path}")
        print(f"  Targets: {args.targets}")
        print(f"  Shared skills: {len(get_install_shared_skills())} installed")

    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
