# AI Inventory Report

Generated: 2026-06-13T20:46:13

## Summary

| Metric | Count |
|---|---:|
| codex_skills | 21 |
| claude_commands | 21 |
| claude_rules | 4 |
| claude_strategy_profiles | 6 |
| claude_hooks | 3 |
| codex_hooks | 3 |
| root_docs | 4 |
| manifest_covered_artifacts | 42 |
| manifest_declared_exports | 42 |
| manifest_missing_exports | 0 |
| issues | 39 |

## Pair status summary

| Pair status | Count | Meaning |
|---|---:|---|
| ok_same_canonical | 21 | Claude and Codex are linked to the same canonical manifest entry. |

## Claude ↔ Codex pairs

| Name | Claude | Codex | Canonical ID | Version | Same raw hash | Issue |
|---|---|---|---|---|---|---|
| add-indicator | .claude/commands/add-indicator.md | .agents/skills/add-indicator/SKILL.md | aimoto.add-indicator | 1.0.0 | true | ok_same_canonical |
| analyse-signal | .claude/commands/analyse-signal.md | .agents/skills/analyse-signal/SKILL.md | aimoto.analyse-signal | 1.0.0 | true | ok_same_canonical |
| article-review | .claude/commands/article-review.md | .agents/skills/article-review/SKILL.md | aimoto.article-review | 1.0.0 | true | ok_same_canonical |
| bilan | .claude/commands/bilan.md | .agents/skills/bilan/SKILL.md | aimoto.bilan | 1.0.0 | true | ok_same_canonical |
| commit | .claude/commands/commit.md | .agents/skills/commit/SKILL.md | shared.commit | 1.0.0 | true | ok_same_canonical |
| create-doc | .claude/commands/create-doc.md | .agents/skills/create-doc/SKILL.md | shared.create-doc | 1.0.0 | true | ok_same_canonical |
| edit-export-llm-report | .claude/commands/edit-export-llm-report.md | .agents/skills/edit-export-llm-report/SKILL.md | aimoto.edit-export-llm-report | 1.0.0 | true | ok_same_canonical |
| implement | .claude/commands/implement.md | .agents/skills/implement/SKILL.md | shared.implement | 1.0.0 | true | ok_same_canonical |
| implement-remediation-spec | .claude/commands/implement-remediation-spec.md | .agents/skills/implement-remediation-spec/SKILL.md | aimoto.implement-remediation-spec | 1.0.0 | true | ok_same_canonical |
| new-strategy | .claude/commands/new-strategy.md | .agents/skills/new-strategy/SKILL.md | aimoto.new-strategy | 1.0.0 | true | ok_same_canonical |
| next | .claude/commands/next.md | .agents/skills/next/SKILL.md | aimoto.next | 1.0.0 | true | ok_same_canonical |
| optimize-claude-md | .claude/commands/optimize-claude-md.md | .agents/skills/optimize-claude-md/SKILL.md | shared.optimize-claude-md | 1.0.0 | true | ok_same_canonical |
| spec-0-feedback | .claude/commands/spec-0-feedback.md | .agents/skills/spec-0-feedback/SKILL.md | shared.spec-0-feedback | 1.0.0 | true | ok_same_canonical |
| spec-1-intake | .claude/commands/spec-1-intake.md | .agents/skills/spec-1-intake/SKILL.md | shared.spec-1-intake | 1.0.0 | true | ok_same_canonical |
| spec-2-draft | .claude/commands/spec-2-draft.md | .agents/skills/spec-2-draft/SKILL.md | shared.spec-2-draft | 1.0.0 | true | ok_same_canonical |
| spec-3-audit | .claude/commands/spec-3-audit.md | .agents/skills/spec-3-audit/SKILL.md | shared.spec-3-audit | 1.0.0 | true | ok_same_canonical |
| spec-4-challenge | .claude/commands/spec-4-challenge.md | .agents/skills/spec-4-challenge/SKILL.md | shared.spec-4-challenge | 1.0.0 | true | ok_same_canonical |
| spec-5-revise | .claude/commands/spec-5-revise.md | .agents/skills/spec-5-revise/SKILL.md | shared.spec-5-revise | 1.0.0 | true | ok_same_canonical |
| test | .claude/commands/test.md | .agents/skills/test/SKILL.md | shared.test | 1.0.0 | true | ok_same_canonical |
| ui-review | .claude/commands/ui-review.md | .agents/skills/ui-review/SKILL.md | shared.ui-review | 1.0.0 | true | ok_same_canonical |
| update-strategy | .claude/commands/update-strategy.md | .agents/skills/update-strategy/SKILL.md | aimoto.update-strategy | 1.0.0 | true | ok_same_canonical |

## Manifest exports

| Canonical ID | Target | Path | Exists |
|---|---|---|---|
| shared.implement | claude_command | /Users/vincentdesbrosses/Documents/Misc/claude-commands/implement.md | true |
| shared.implement | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/implement/SKILL.md | true |
| aimoto.new-strategy | claude_command | /Users/vincentdesbrosses/Documents/Misc/aimoto/.claude/commands/new-strategy.md | true |
| aimoto.new-strategy | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/new-strategy/SKILL.md | true |
| aimoto.update-strategy | claude_command | /Users/vincentdesbrosses/Documents/Misc/aimoto/.claude/commands/update-strategy.md | true |
| aimoto.update-strategy | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/update-strategy/SKILL.md | true |
| aimoto.add-indicator | claude_command | /Users/vincentdesbrosses/Documents/Misc/aimoto/.claude/commands/add-indicator.md | true |
| aimoto.add-indicator | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/add-indicator/SKILL.md | true |
| aimoto.analyse-signal | claude_command | /Users/vincentdesbrosses/Documents/Misc/aimoto/.claude/commands/analyse-signal.md | true |
| aimoto.analyse-signal | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/analyse-signal/SKILL.md | true |
| aimoto.article-review | claude_command | /Users/vincentdesbrosses/Documents/Misc/aimoto/.claude/commands/article-review.md | true |
| aimoto.article-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/article-review/SKILL.md | true |
| aimoto.bilan | claude_command | /Users/vincentdesbrosses/Documents/Misc/aimoto/.claude/commands/bilan.md | true |
| aimoto.bilan | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/bilan/SKILL.md | true |
| aimoto.edit-export-llm-report | claude_command | /Users/vincentdesbrosses/Documents/Misc/aimoto/.claude/commands/edit-export-llm-report.md | true |
| aimoto.edit-export-llm-report | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/edit-export-llm-report/SKILL.md | true |
| aimoto.next | claude_command | /Users/vincentdesbrosses/Documents/Misc/aimoto/.claude/commands/next.md | true |
| aimoto.next | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/next/SKILL.md | true |
| aimoto.implement-remediation-spec | claude_command | /Users/vincentdesbrosses/Documents/Misc/aimoto/.claude/commands/implement-remediation-spec.md | true |
| aimoto.implement-remediation-spec | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/implement-remediation-spec/SKILL.md | true |
| shared.commit | claude_command | /Users/vincentdesbrosses/Documents/Misc/claude-commands/commit.md | true |
| shared.commit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/commit/SKILL.md | true |
| shared.create-doc | claude_command | /Users/vincentdesbrosses/Documents/Misc/claude-commands/create-doc.md | true |
| shared.create-doc | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/create-doc/SKILL.md | true |
| shared.optimize-claude-md | claude_command | /Users/vincentdesbrosses/Documents/Misc/claude-commands/optimize-claude-md.md | true |
| shared.optimize-claude-md | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/optimize-claude-md/SKILL.md | true |
| shared.spec-0-feedback | claude_command | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-0-feedback.md | true |
| shared.spec-0-feedback | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/spec-0-feedback/SKILL.md | true |
| shared.spec-1-intake | claude_command | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-1-intake.md | true |
| shared.spec-1-intake | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/spec-1-intake/SKILL.md | true |
| shared.spec-2-draft | claude_command | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-2-draft.md | true |
| shared.spec-2-draft | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/spec-2-draft/SKILL.md | true |
| shared.spec-3-audit | claude_command | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-3-audit.md | true |
| shared.spec-3-audit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/spec-3-audit/SKILL.md | true |
| shared.spec-4-challenge | claude_command | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-4-challenge.md | true |
| shared.spec-4-challenge | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/spec-4-challenge/SKILL.md | true |
| shared.spec-5-revise | claude_command | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-5-revise.md | true |
| shared.spec-5-revise | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/spec-5-revise/SKILL.md | true |
| shared.test | claude_command | /Users/vincentdesbrosses/Documents/Misc/claude-commands/test.md | true |
| shared.test | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/test/SKILL.md | true |
| shared.ui-review | claude_command | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-review.md | true |
| shared.ui-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/ui-review/SKILL.md | true |

## Issues

| Severity | Code | Artifact | Path | Message |
|---|---|---|---|---|
| warning | fallback_candidate | add-indicator | .agents/skills/add-indicator/SKILL.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | add-indicator | .agents/skills/add-indicator/SKILL.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | edit-export-llm-report | .agents/skills/edit-export-llm-report/SKILL.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | edit-export-llm-report | .agents/skills/edit-export-llm-report/SKILL.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | implement | .agents/skills/implement/SKILL.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | implement-remediation-spec | .agents/skills/implement-remediation-spec/SKILL.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | next | .agents/skills/next/SKILL.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | Pattern suspect détecté : si absent |
| warning | fallback_candidate | spec-1-intake | .agents/skills/spec-1-intake/SKILL.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | spec-3-audit | .agents/skills/spec-3-audit/SKILL.md | Pattern suspect détecté : si absent |
| warning | fallback_candidate | spec-5-revise | .agents/skills/spec-5-revise/SKILL.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | update-strategy | .agents/skills/update-strategy/SKILL.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | update-strategy | .agents/skills/update-strategy/SKILL.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | update-strategy | .agents/skills/update-strategy/SKILL.md | Pattern suspect détecté : si absent |
| warning | fallback_candidate | add-indicator | .claude/commands/add-indicator.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | add-indicator | .claude/commands/add-indicator.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | edit-export-llm-report | .claude/commands/edit-export-llm-report.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | edit-export-llm-report | .claude/commands/edit-export-llm-report.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | implement-remediation-spec | .claude/commands/implement-remediation-spec.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | implement | .claude/commands/implement.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | next | .claude/commands/next.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | Pattern suspect détecté : si absent |
| warning | fallback_candidate | spec-1-intake | .claude/commands/spec-1-intake.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | spec-3-audit | .claude/commands/spec-3-audit.md | Pattern suspect détecté : si absent |
| warning | fallback_candidate | spec-5-revise | .claude/commands/spec-5-revise.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | ui-review | .claude/commands/ui-review.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | ui-review | .claude/commands/ui-review.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | update-strategy | .claude/commands/update-strategy.md | Pattern suspect détecté : par défaut |
| warning | fallback_candidate | update-strategy | .claude/commands/update-strategy.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | update-strategy | .claude/commands/update-strategy.md | Pattern suspect détecté : si absent |
| warning | fallback_candidate | _template | .claude/strategy-profiles/_template.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | forecast_signal_driven_long_only | .claude/strategy-profiles/forecast_signal_driven_long_only.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | AGENTS | AGENTS.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | CLAUDE | CLAUDE.md | Pattern suspect détecté : fallback |
| warning | fallback_candidate | project-config | .claude/project-config.md | Pattern suspect détecté : fallback |

## Symlinks

| Artifact | Type | Path | Target | Status |
|---|---|---|---|---|
| commit | claude_command | .claude/commands/commit.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/commit.md | ok |
| create-doc | claude_command | .claude/commands/create-doc.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/create-doc.md | ok |
| implement | claude_command | .claude/commands/implement.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/implement.md | ok |
| optimize-claude-md | claude_command | .claude/commands/optimize-claude-md.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/optimize-claude-md.md | ok |
| spec-0-feedback | claude_command | .claude/commands/spec-0-feedback.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-0-feedback.md | ok |
| spec-1-intake | claude_command | .claude/commands/spec-1-intake.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-1-intake.md | ok |
| spec-2-draft | claude_command | .claude/commands/spec-2-draft.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-2-draft.md | ok |
| spec-3-audit | claude_command | .claude/commands/spec-3-audit.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-3-audit.md | ok |
| spec-4-challenge | claude_command | .claude/commands/spec-4-challenge.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-4-challenge.md | ok |
| spec-5-revise | claude_command | .claude/commands/spec-5-revise.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-5-revise.md | ok |
| test | claude_command | .claude/commands/test.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/test.md | ok |
| ui-review | claude_command | .claude/commands/ui-review.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-review.md | ok |

## Recommended next actions

1. Vérifier que `implement`, `new-strategy` et `update-strategy` sont en `ok_same_canonical`.
2. Ajouter le frontmatter runtime minimal aux exports encore actifs sans `name` / `description`.
3. Corriger `update-strategy` pour supprimer les fallbacks implicites.
4. Créer ensuite `sync_skills.py` pour générer les exports depuis `canonical.md`.
