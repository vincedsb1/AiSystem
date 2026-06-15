# AI Doctor Report

Generated: 2026-06-15T11:13:16

## Inputs

- Registry: `/Users/vincentdesbrosses/Documents/Misc/ai-system/skills-registry.yml`
- Inventory: `/Users/vincentdesbrosses/Documents/Misc/ai-system/reports/ai-inventory.latest.json`
- JSON output: `/Users/vincentdesbrosses/Documents/Misc/ai-system/reports/ai-doctor.latest.json`

## Summary

| Metric | Count |
|---|---:|
| total | 4 |
| danger | 3 |
| review | 1 |
| acceptable | 0 |

## By artifact type

| Artifact type | Count |
|---|---:|
| architecture_file | 1 |
| claude_command | 3 |

## By pattern

| Pattern | Count |
|---|---:|
| `fallback` | 3 |
| `par défaut` | 1 |

## Findings

| Classification | Artifact | Type | Pattern | Location | Text |
|---|---|---|---|---|---|
| DANGER | update-strategy | claude_command | `fallback` | .claude/commands/update-strategy.md:126 | 3. **Fallback `_next_minor_ver(STRATEGY_VERSION_actuel)`** (calcul local) → |
| DANGER | update-strategy | claude_command | `fallback` | .claude/commands/update-strategy.md:158 | Valeurs possibles pour `source` : `arguments_override` \| `llm_report.target_version` \| `fallback_next_minor_ver`. |
| DANGER | update-strategy | claude_command | `fallback` | .claude/commands/update-strategy.md:411 | - STRATEGY_VERSION : v{ANCIEN} → v{X.Y.Z} (source: {arguments_override\|llm_report.target_version\|fallback_next_minor_ver}) |
| REVIEW | ARCHITECTURE | architecture_file | `par défaut` | docs/ARCHITECTURE.md:62 | - Création : `title = deriveTitleFromSlug(slug)` (seuls `slug` + `title` sont requis ; les autres champs restent vides / par défaut). |

