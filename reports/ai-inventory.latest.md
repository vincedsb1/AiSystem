# AI Inventory Report

Generated: 2026-06-15T16:35:36

## Summary

| Metric | Count |
|---|---:|
| codex_skills | 139 |
| claude_commands | 121 |
| claude_rules | 8 |
| claude_strategy_profiles | 6 |
| claude_hooks | 6 |
| codex_hooks | 3 |
| root_docs | 17 |
| manifest_covered_artifacts | 230 |
| manifest_declared_exports | 161 |
| manifest_missing_exports | 0 |
| action_required | 0 |
| accepted_findings | 206 |
| expected_exceptions | 30 |
| doctor_danger | 0 |
| doctor_review | 0 |

**Status: OK.** Accepted findings are retained for transparency but do not require action. Expected pairing exceptions are registry decisions and do not count as warnings.

## Projects summary

| Project | Codex skills | Claude commands | Claude rules | Claude hooks | Codex hooks | Root docs | Action required | Accepted findings | Expected exceptions |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| aimoto | 22 | 22 | 4 | 3 | 3 | 4 | 0 | 39 | 0 |
| InterviewOS | 13 | 12 | 4 | 3 | 0 | 2 | 0 | 17 | 0 |
| intrai | 13 | 0 | 0 | 0 | 0 | 1 | 0 | 8 | 0 |
| linkedin-ia-comments | 13 | 0 | 0 | 0 | 0 | 1 | 0 | 8 | 0 |
| Pylaa | 13 | 18 | 0 | 0 | 0 | 3 | 0 | 28 | 6 |
| Pylot | 13 | 18 | 0 | 0 | 0 | 2 | 0 | 25 | 6 |
| Skriipt | 13 | 15 | 0 | 0 | 0 | 1 | 0 | 23 | 6 |
| Spotter | 13 | 0 | 0 | 0 | 0 | 0 | 0 | 8 | 0 |
| suggst | 13 | 18 | 0 | 0 | 0 | 2 | 0 | 25 | 6 |
| truthify | 13 | 18 | 0 | 0 | 0 | 1 | 0 | 25 | 6 |

## Pair status summary

| Pair status | Count | Meaning |
|---|---:|---|
| expected_claude_only | 30 | Project-specific Claude command intentionally has no Codex skill. |
| ok_same_canonical | 139 | Claude and Codex are linked to the same canonical manifest entry. |

## Claude ↔ Codex pairs

| Project | Name | Claude project | Claude | Codex project | Codex | Canonical ID | Version | Same raw hash | Issue |
|---|---|---|---|---|---|---|---|---|---|
| InterviewOS | ai-post-task-review | aimoto | .claude/commands/ai-post-task-review.md | InterviewOS | .agents/skills/ai-post-task-review/SKILL.md | shared.ai-post-task-review | 1.0.0 | true | ok_same_canonical |
| InterviewOS | commit | InterviewOS | .claude/commands/commit.md | InterviewOS | .agents/skills/commit/SKILL.md | shared.commit | 1.0.0 | true | ok_same_canonical |
| InterviewOS | create-doc | InterviewOS | .claude/commands/create-doc.md | InterviewOS | .agents/skills/create-doc/SKILL.md | shared.create-doc | 1.0.0 | true | ok_same_canonical |
| InterviewOS | implement | InterviewOS | .claude/commands/implement.md | InterviewOS | .agents/skills/implement/SKILL.md | shared.implement | 1.0.0 | true | ok_same_canonical |
| InterviewOS | optimize-claude-md | InterviewOS | .claude/commands/optimize-claude-md.md | InterviewOS | .agents/skills/optimize-claude-md/SKILL.md | shared.optimize-claude-md | 1.0.0 | true | ok_same_canonical |
| InterviewOS | spec-0-feedback | InterviewOS | .claude/commands/spec-0-feedback.md | InterviewOS | .agents/skills/spec-0-feedback/SKILL.md | shared.spec-0-feedback | 1.0.0 | true | ok_same_canonical |
| InterviewOS | spec-1-intake | InterviewOS | .claude/commands/spec-1-intake.md | InterviewOS | .agents/skills/spec-1-intake/SKILL.md | shared.spec-1-intake | 1.0.0 | true | ok_same_canonical |
| InterviewOS | spec-2-draft | InterviewOS | .claude/commands/spec-2-draft.md | InterviewOS | .agents/skills/spec-2-draft/SKILL.md | shared.spec-2-draft | 1.0.0 | true | ok_same_canonical |
| InterviewOS | spec-3-audit | InterviewOS | .claude/commands/spec-3-audit.md | InterviewOS | .agents/skills/spec-3-audit/SKILL.md | shared.spec-3-audit | 1.0.0 | true | ok_same_canonical |
| InterviewOS | spec-4-challenge | InterviewOS | .claude/commands/spec-4-challenge.md | InterviewOS | .agents/skills/spec-4-challenge/SKILL.md | shared.spec-4-challenge | 1.0.0 | true | ok_same_canonical |
| InterviewOS | spec-5-revise | InterviewOS | .claude/commands/spec-5-revise.md | InterviewOS | .agents/skills/spec-5-revise/SKILL.md | shared.spec-5-revise | 1.0.0 | true | ok_same_canonical |
| InterviewOS | test | InterviewOS | .claude/commands/test.md | InterviewOS | .agents/skills/test/SKILL.md | shared.test | 1.0.0 | true | ok_same_canonical |
| InterviewOS | ui-review | InterviewOS | .claude/commands/ui-review.md | InterviewOS | .agents/skills/ui-review/SKILL.md | shared.ui-review | 1.0.0 | true | ok_same_canonical |
| Pylaa | ai-post-task-review | aimoto | .claude/commands/ai-post-task-review.md | Pylaa | .agents/skills/ai-post-task-review/SKILL.md | shared.ai-post-task-review | 1.0.0 | true | ok_same_canonical |
| Pylaa | commit | Pylaa | .claude/commands/commit.md | Pylaa | .agents/skills/commit/SKILL.md | shared.commit | 1.0.0 | true | ok_same_canonical |
| Pylaa | create-doc | Pylaa | .claude/commands/create-doc.md | Pylaa | .agents/skills/create-doc/SKILL.md | shared.create-doc | 1.0.0 | true | ok_same_canonical |
| Pylaa | data-slot-add | Pylaa | .claude/commands/data-slot-add.md |  |  |  |  |  | expected_claude_only |
| Pylaa | design-audit-context | Pylaa | .claude/commands/design-audit-context.md |  |  |  |  |  | expected_claude_only |
| Pylaa | implement | Pylaa | .claude/commands/implement.md | Pylaa | .agents/skills/implement/SKILL.md | shared.implement | 1.0.0 | true | ok_same_canonical |
| Pylaa | landing-review | Pylaa | .claude/commands/landing-review.md |  |  |  |  |  | expected_claude_only |
| Pylaa | next-step | Pylaa | .claude/commands/next-step.md |  |  |  |  |  | expected_claude_only |
| Pylaa | optimize-claude-md | Pylaa | .claude/commands/optimize-claude-md.md | Pylaa | .agents/skills/optimize-claude-md/SKILL.md | shared.optimize-claude-md | 1.0.0 | true | ok_same_canonical |
| Pylaa | spec-0-feedback | Pylaa | .claude/commands/spec-0-feedback.md | Pylaa | .agents/skills/spec-0-feedback/SKILL.md | shared.spec-0-feedback | 1.0.0 | true | ok_same_canonical |
| Pylaa | spec-1-intake | Pylaa | .claude/commands/spec-1-intake.md | Pylaa | .agents/skills/spec-1-intake/SKILL.md | shared.spec-1-intake | 1.0.0 | true | ok_same_canonical |
| Pylaa | spec-2-draft | Pylaa | .claude/commands/spec-2-draft.md | Pylaa | .agents/skills/spec-2-draft/SKILL.md | shared.spec-2-draft | 1.0.0 | true | ok_same_canonical |
| Pylaa | spec-3-audit | Pylaa | .claude/commands/spec-3-audit.md | Pylaa | .agents/skills/spec-3-audit/SKILL.md | shared.spec-3-audit | 1.0.0 | true | ok_same_canonical |
| Pylaa | spec-4-challenge | Pylaa | .claude/commands/spec-4-challenge.md | Pylaa | .agents/skills/spec-4-challenge/SKILL.md | shared.spec-4-challenge | 1.0.0 | true | ok_same_canonical |
| Pylaa | spec-5-revise | Pylaa | .claude/commands/spec-5-revise.md | Pylaa | .agents/skills/spec-5-revise/SKILL.md | shared.spec-5-revise | 1.0.0 | true | ok_same_canonical |
| Pylaa | test | Pylaa | .claude/commands/test.md | Pylaa | .agents/skills/test/SKILL.md | shared.test | 1.0.0 | true | ok_same_canonical |
| Pylaa | ui-fix-global | Pylaa | .claude/commands/ui-fix-global.md |  |  |  |  |  | expected_claude_only |
| Pylaa | ui-review | Pylaa | .claude/commands/ui-review.md | Pylaa | .agents/skills/ui-review/SKILL.md | shared.ui-review | 1.0.0 | true | ok_same_canonical |
| Pylaa | ui-review-global | Pylaa | .claude/commands/ui-review-global.md |  |  |  |  |  | expected_claude_only |
| Pylot | ai-post-task-review | aimoto | .claude/commands/ai-post-task-review.md | Pylot | .agents/skills/ai-post-task-review/SKILL.md | shared.ai-post-task-review | 1.0.0 | true | ok_same_canonical |
| Pylot | commit | Pylot | .claude/commands/commit.md | Pylot | .agents/skills/commit/SKILL.md | shared.commit | 1.0.0 | true | ok_same_canonical |
| Pylot | create-doc | Pylot | .claude/commands/create-doc.md | Pylot | .agents/skills/create-doc/SKILL.md | shared.create-doc | 1.0.0 | true | ok_same_canonical |
| Pylot | data-slot-add | Pylot | .claude/commands/data-slot-add.md |  |  |  |  |  | expected_claude_only |
| Pylot | design-audit-context | Pylot | .claude/commands/design-audit-context.md |  |  |  |  |  | expected_claude_only |
| Pylot | implement | Pylot | .claude/commands/implement.md | Pylot | .agents/skills/implement/SKILL.md | shared.implement | 1.0.0 | true | ok_same_canonical |
| Pylot | landing-review | Pylot | .claude/commands/landing-review.md |  |  |  |  |  | expected_claude_only |
| Pylot | next-step | Pylot | .claude/commands/next-step.md |  |  |  |  |  | expected_claude_only |
| Pylot | optimize-claude-md | Pylot | .claude/commands/optimize-claude-md.md | Pylot | .agents/skills/optimize-claude-md/SKILL.md | shared.optimize-claude-md | 1.0.0 | true | ok_same_canonical |
| Pylot | spec-0-feedback | Pylot | .claude/commands/spec-0-feedback.md | Pylot | .agents/skills/spec-0-feedback/SKILL.md | shared.spec-0-feedback | 1.0.0 | true | ok_same_canonical |
| Pylot | spec-1-intake | Pylot | .claude/commands/spec-1-intake.md | Pylot | .agents/skills/spec-1-intake/SKILL.md | shared.spec-1-intake | 1.0.0 | true | ok_same_canonical |
| Pylot | spec-2-draft | Pylot | .claude/commands/spec-2-draft.md | Pylot | .agents/skills/spec-2-draft/SKILL.md | shared.spec-2-draft | 1.0.0 | true | ok_same_canonical |
| Pylot | spec-3-audit | Pylot | .claude/commands/spec-3-audit.md | Pylot | .agents/skills/spec-3-audit/SKILL.md | shared.spec-3-audit | 1.0.0 | true | ok_same_canonical |
| Pylot | spec-4-challenge | Pylot | .claude/commands/spec-4-challenge.md | Pylot | .agents/skills/spec-4-challenge/SKILL.md | shared.spec-4-challenge | 1.0.0 | true | ok_same_canonical |
| Pylot | spec-5-revise | Pylot | .claude/commands/spec-5-revise.md | Pylot | .agents/skills/spec-5-revise/SKILL.md | shared.spec-5-revise | 1.0.0 | true | ok_same_canonical |
| Pylot | test | Pylot | .claude/commands/test.md | Pylot | .agents/skills/test/SKILL.md | shared.test | 1.0.0 | true | ok_same_canonical |
| Pylot | ui-fix-global | Pylot | .claude/commands/ui-fix-global.md |  |  |  |  |  | expected_claude_only |
| Pylot | ui-review | Pylot | .claude/commands/ui-review.md | Pylot | .agents/skills/ui-review/SKILL.md | shared.ui-review | 1.0.0 | true | ok_same_canonical |
| Pylot | ui-review-global | Pylot | .claude/commands/ui-review-global.md |  |  |  |  |  | expected_claude_only |
| Skriipt | ai-post-task-review | aimoto | .claude/commands/ai-post-task-review.md | Skriipt | .agents/skills/ai-post-task-review/SKILL.md | shared.ai-post-task-review | 1.0.0 | true | ok_same_canonical |
| Skriipt | commit | Skriipt | .claude/commands/commit.md | Skriipt | .agents/skills/commit/SKILL.md | shared.commit | 1.0.0 | true | ok_same_canonical |
| Skriipt | create-doc | InterviewOS | .claude/commands/create-doc.md | Skriipt | .agents/skills/create-doc/SKILL.md | shared.create-doc | 1.0.0 | true | ok_same_canonical |
| Skriipt | data-slot-add | Skriipt | .claude/commands/data-slot-add.md |  |  |  |  |  | expected_claude_only |
| Skriipt | design-audit-context | Skriipt | .claude/commands/design-audit-context.md |  |  |  |  |  | expected_claude_only |
| Skriipt | implement | Skriipt | .claude/commands/implement.md | Skriipt | .agents/skills/implement/SKILL.md | shared.implement | 1.0.0 | true | ok_same_canonical |
| Skriipt | landing-review | Skriipt | .claude/commands/landing-review.md |  |  |  |  |  | expected_claude_only |
| Skriipt | next-step | Skriipt | .claude/commands/next-step.md |  |  |  |  |  | expected_claude_only |
| Skriipt | optimize-claude-md | InterviewOS | .claude/commands/optimize-claude-md.md | Skriipt | .agents/skills/optimize-claude-md/SKILL.md | shared.optimize-claude-md | 1.0.0 | true | ok_same_canonical |
| Skriipt | spec-0-feedback | Skriipt | .claude/commands/spec-0-feedback.md | Skriipt | .agents/skills/spec-0-feedback/SKILL.md | shared.spec-0-feedback | 1.0.0 | true | ok_same_canonical |
| Skriipt | spec-1-intake | Skriipt | .claude/commands/spec-1-intake.md | Skriipt | .agents/skills/spec-1-intake/SKILL.md | shared.spec-1-intake | 1.0.0 | true | ok_same_canonical |
| Skriipt | spec-2-draft | Skriipt | .claude/commands/spec-2-draft.md | Skriipt | .agents/skills/spec-2-draft/SKILL.md | shared.spec-2-draft | 1.0.0 | true | ok_same_canonical |
| Skriipt | spec-3-audit | Skriipt | .claude/commands/spec-3-audit.md | Skriipt | .agents/skills/spec-3-audit/SKILL.md | shared.spec-3-audit | 1.0.0 | true | ok_same_canonical |
| Skriipt | spec-4-challenge | Skriipt | .claude/commands/spec-4-challenge.md | Skriipt | .agents/skills/spec-4-challenge/SKILL.md | shared.spec-4-challenge | 1.0.0 | true | ok_same_canonical |
| Skriipt | spec-5-revise | Skriipt | .claude/commands/spec-5-revise.md | Skriipt | .agents/skills/spec-5-revise/SKILL.md | shared.spec-5-revise | 1.0.0 | true | ok_same_canonical |
| Skriipt | test | InterviewOS | .claude/commands/test.md | Skriipt | .agents/skills/test/SKILL.md | shared.test | 1.0.0 | true | ok_same_canonical |
| Skriipt | ui-fix-global | Skriipt | .claude/commands/ui-fix-global.md |  |  |  |  |  | expected_claude_only |
| Skriipt | ui-review | Skriipt | .claude/commands/ui-review.md | Skriipt | .agents/skills/ui-review/SKILL.md | shared.ui-review | 1.0.0 | true | ok_same_canonical |
| Skriipt | ui-review-global | Skriipt | .claude/commands/ui-review-global.md |  |  |  |  |  | expected_claude_only |
| Spotter | ai-post-task-review | aimoto | .claude/commands/ai-post-task-review.md | Spotter | .agents/skills/ai-post-task-review/SKILL.md | shared.ai-post-task-review | 1.0.0 | true | ok_same_canonical |
| Spotter | commit | InterviewOS | .claude/commands/commit.md | Spotter | .agents/skills/commit/SKILL.md | shared.commit | 1.0.0 | true | ok_same_canonical |
| Spotter | create-doc | InterviewOS | .claude/commands/create-doc.md | Spotter | .agents/skills/create-doc/SKILL.md | shared.create-doc | 1.0.0 | true | ok_same_canonical |
| Spotter | implement | InterviewOS | .claude/commands/implement.md | Spotter | .agents/skills/implement/SKILL.md | shared.implement | 1.0.0 | true | ok_same_canonical |
| Spotter | optimize-claude-md | InterviewOS | .claude/commands/optimize-claude-md.md | Spotter | .agents/skills/optimize-claude-md/SKILL.md | shared.optimize-claude-md | 1.0.0 | true | ok_same_canonical |
| Spotter | spec-0-feedback | InterviewOS | .claude/commands/spec-0-feedback.md | Spotter | .agents/skills/spec-0-feedback/SKILL.md | shared.spec-0-feedback | 1.0.0 | true | ok_same_canonical |
| Spotter | spec-1-intake | InterviewOS | .claude/commands/spec-1-intake.md | Spotter | .agents/skills/spec-1-intake/SKILL.md | shared.spec-1-intake | 1.0.0 | true | ok_same_canonical |
| Spotter | spec-2-draft | InterviewOS | .claude/commands/spec-2-draft.md | Spotter | .agents/skills/spec-2-draft/SKILL.md | shared.spec-2-draft | 1.0.0 | true | ok_same_canonical |
| Spotter | spec-3-audit | InterviewOS | .claude/commands/spec-3-audit.md | Spotter | .agents/skills/spec-3-audit/SKILL.md | shared.spec-3-audit | 1.0.0 | true | ok_same_canonical |
| Spotter | spec-4-challenge | InterviewOS | .claude/commands/spec-4-challenge.md | Spotter | .agents/skills/spec-4-challenge/SKILL.md | shared.spec-4-challenge | 1.0.0 | true | ok_same_canonical |
| Spotter | spec-5-revise | InterviewOS | .claude/commands/spec-5-revise.md | Spotter | .agents/skills/spec-5-revise/SKILL.md | shared.spec-5-revise | 1.0.0 | true | ok_same_canonical |
| Spotter | test | InterviewOS | .claude/commands/test.md | Spotter | .agents/skills/test/SKILL.md | shared.test | 1.0.0 | true | ok_same_canonical |
| Spotter | ui-review | InterviewOS | .claude/commands/ui-review.md | Spotter | .agents/skills/ui-review/SKILL.md | shared.ui-review | 1.0.0 | true | ok_same_canonical |
| aimoto | add-indicator | aimoto | .claude/commands/add-indicator.md | aimoto | .agents/skills/add-indicator/SKILL.md | aimoto.add-indicator | 1.0.0 | true | ok_same_canonical |
| aimoto | ai-post-task-review | aimoto | .claude/commands/ai-post-task-review.md | aimoto | .agents/skills/ai-post-task-review/SKILL.md | shared.ai-post-task-review | 1.0.0 | true | ok_same_canonical |
| aimoto | analyse-signal | aimoto | .claude/commands/analyse-signal.md | aimoto | .agents/skills/analyse-signal/SKILL.md | aimoto.analyse-signal | 1.0.0 | true | ok_same_canonical |
| aimoto | article-review | aimoto | .claude/commands/article-review.md | aimoto | .agents/skills/article-review/SKILL.md | aimoto.article-review | 1.0.0 | true | ok_same_canonical |
| aimoto | bilan | aimoto | .claude/commands/bilan.md | aimoto | .agents/skills/bilan/SKILL.md | aimoto.bilan | 1.0.0 | true | ok_same_canonical |
| aimoto | commit | aimoto | .claude/commands/commit.md | aimoto | .agents/skills/commit/SKILL.md | shared.commit | 1.0.0 | true | ok_same_canonical |
| aimoto | create-doc | aimoto | .claude/commands/create-doc.md | aimoto | .agents/skills/create-doc/SKILL.md | shared.create-doc | 1.0.0 | true | ok_same_canonical |
| aimoto | edit-export-llm-report | aimoto | .claude/commands/edit-export-llm-report.md | aimoto | .agents/skills/edit-export-llm-report/SKILL.md | aimoto.edit-export-llm-report | 1.0.0 | true | ok_same_canonical |
| aimoto | implement | aimoto | .claude/commands/implement.md | aimoto | .agents/skills/implement/SKILL.md | shared.implement | 1.0.0 | true | ok_same_canonical |
| aimoto | implement-remediation-spec | aimoto | .claude/commands/implement-remediation-spec.md | aimoto | .agents/skills/implement-remediation-spec/SKILL.md | aimoto.implement-remediation-spec | 1.0.0 | true | ok_same_canonical |
| aimoto | new-strategy | aimoto | .claude/commands/new-strategy.md | aimoto | .agents/skills/new-strategy/SKILL.md | aimoto.new-strategy | 1.0.0 | true | ok_same_canonical |
| aimoto | next | aimoto | .claude/commands/next.md | aimoto | .agents/skills/next/SKILL.md | aimoto.next | 1.0.0 | true | ok_same_canonical |
| aimoto | optimize-claude-md | aimoto | .claude/commands/optimize-claude-md.md | aimoto | .agents/skills/optimize-claude-md/SKILL.md | shared.optimize-claude-md | 1.0.0 | true | ok_same_canonical |
| aimoto | spec-0-feedback | aimoto | .claude/commands/spec-0-feedback.md | aimoto | .agents/skills/spec-0-feedback/SKILL.md | shared.spec-0-feedback | 1.0.0 | true | ok_same_canonical |
| aimoto | spec-1-intake | aimoto | .claude/commands/spec-1-intake.md | aimoto | .agents/skills/spec-1-intake/SKILL.md | shared.spec-1-intake | 1.0.0 | true | ok_same_canonical |
| aimoto | spec-2-draft | aimoto | .claude/commands/spec-2-draft.md | aimoto | .agents/skills/spec-2-draft/SKILL.md | shared.spec-2-draft | 1.0.0 | true | ok_same_canonical |
| aimoto | spec-3-audit | aimoto | .claude/commands/spec-3-audit.md | aimoto | .agents/skills/spec-3-audit/SKILL.md | shared.spec-3-audit | 1.0.0 | true | ok_same_canonical |
| aimoto | spec-4-challenge | aimoto | .claude/commands/spec-4-challenge.md | aimoto | .agents/skills/spec-4-challenge/SKILL.md | shared.spec-4-challenge | 1.0.0 | true | ok_same_canonical |
| aimoto | spec-5-revise | aimoto | .claude/commands/spec-5-revise.md | aimoto | .agents/skills/spec-5-revise/SKILL.md | shared.spec-5-revise | 1.0.0 | true | ok_same_canonical |
| aimoto | test | aimoto | .claude/commands/test.md | aimoto | .agents/skills/test/SKILL.md | shared.test | 1.0.0 | true | ok_same_canonical |
| aimoto | ui-review | aimoto | .claude/commands/ui-review.md | aimoto | .agents/skills/ui-review/SKILL.md | shared.ui-review | 1.0.0 | true | ok_same_canonical |
| aimoto | update-strategy | aimoto | .claude/commands/update-strategy.md | aimoto | .agents/skills/update-strategy/SKILL.md | aimoto.update-strategy | 1.0.0 | true | ok_same_canonical |
| intrai | ai-post-task-review | aimoto | .claude/commands/ai-post-task-review.md | intrai | .agents/skills/ai-post-task-review/SKILL.md | shared.ai-post-task-review | 1.0.0 | true | ok_same_canonical |
| intrai | commit | InterviewOS | .claude/commands/commit.md | intrai | .agents/skills/commit/SKILL.md | shared.commit | 1.0.0 | true | ok_same_canonical |
| intrai | create-doc | InterviewOS | .claude/commands/create-doc.md | intrai | .agents/skills/create-doc/SKILL.md | shared.create-doc | 1.0.0 | true | ok_same_canonical |
| intrai | implement | InterviewOS | .claude/commands/implement.md | intrai | .agents/skills/implement/SKILL.md | shared.implement | 1.0.0 | true | ok_same_canonical |
| intrai | optimize-claude-md | InterviewOS | .claude/commands/optimize-claude-md.md | intrai | .agents/skills/optimize-claude-md/SKILL.md | shared.optimize-claude-md | 1.0.0 | true | ok_same_canonical |
| intrai | spec-0-feedback | InterviewOS | .claude/commands/spec-0-feedback.md | intrai | .agents/skills/spec-0-feedback/SKILL.md | shared.spec-0-feedback | 1.0.0 | true | ok_same_canonical |
| intrai | spec-1-intake | InterviewOS | .claude/commands/spec-1-intake.md | intrai | .agents/skills/spec-1-intake/SKILL.md | shared.spec-1-intake | 1.0.0 | true | ok_same_canonical |
| intrai | spec-2-draft | InterviewOS | .claude/commands/spec-2-draft.md | intrai | .agents/skills/spec-2-draft/SKILL.md | shared.spec-2-draft | 1.0.0 | true | ok_same_canonical |
| intrai | spec-3-audit | InterviewOS | .claude/commands/spec-3-audit.md | intrai | .agents/skills/spec-3-audit/SKILL.md | shared.spec-3-audit | 1.0.0 | true | ok_same_canonical |
| intrai | spec-4-challenge | InterviewOS | .claude/commands/spec-4-challenge.md | intrai | .agents/skills/spec-4-challenge/SKILL.md | shared.spec-4-challenge | 1.0.0 | true | ok_same_canonical |
| intrai | spec-5-revise | InterviewOS | .claude/commands/spec-5-revise.md | intrai | .agents/skills/spec-5-revise/SKILL.md | shared.spec-5-revise | 1.0.0 | true | ok_same_canonical |
| intrai | test | InterviewOS | .claude/commands/test.md | intrai | .agents/skills/test/SKILL.md | shared.test | 1.0.0 | true | ok_same_canonical |
| intrai | ui-review | InterviewOS | .claude/commands/ui-review.md | intrai | .agents/skills/ui-review/SKILL.md | shared.ui-review | 1.0.0 | true | ok_same_canonical |
| linkedin-ia-comments | ai-post-task-review | aimoto | .claude/commands/ai-post-task-review.md | linkedin-ia-comments | .agents/skills/ai-post-task-review/SKILL.md | shared.ai-post-task-review | 1.0.0 | true | ok_same_canonical |
| linkedin-ia-comments | commit | InterviewOS | .claude/commands/commit.md | linkedin-ia-comments | .agents/skills/commit/SKILL.md | shared.commit | 1.0.0 | true | ok_same_canonical |
| linkedin-ia-comments | create-doc | InterviewOS | .claude/commands/create-doc.md | linkedin-ia-comments | .agents/skills/create-doc/SKILL.md | shared.create-doc | 1.0.0 | true | ok_same_canonical |
| linkedin-ia-comments | implement | InterviewOS | .claude/commands/implement.md | linkedin-ia-comments | .agents/skills/implement/SKILL.md | shared.implement | 1.0.0 | true | ok_same_canonical |
| linkedin-ia-comments | optimize-claude-md | InterviewOS | .claude/commands/optimize-claude-md.md | linkedin-ia-comments | .agents/skills/optimize-claude-md/SKILL.md | shared.optimize-claude-md | 1.0.0 | true | ok_same_canonical |
| linkedin-ia-comments | spec-0-feedback | InterviewOS | .claude/commands/spec-0-feedback.md | linkedin-ia-comments | .agents/skills/spec-0-feedback/SKILL.md | shared.spec-0-feedback | 1.0.0 | true | ok_same_canonical |
| linkedin-ia-comments | spec-1-intake | InterviewOS | .claude/commands/spec-1-intake.md | linkedin-ia-comments | .agents/skills/spec-1-intake/SKILL.md | shared.spec-1-intake | 1.0.0 | true | ok_same_canonical |
| linkedin-ia-comments | spec-2-draft | InterviewOS | .claude/commands/spec-2-draft.md | linkedin-ia-comments | .agents/skills/spec-2-draft/SKILL.md | shared.spec-2-draft | 1.0.0 | true | ok_same_canonical |
| linkedin-ia-comments | spec-3-audit | InterviewOS | .claude/commands/spec-3-audit.md | linkedin-ia-comments | .agents/skills/spec-3-audit/SKILL.md | shared.spec-3-audit | 1.0.0 | true | ok_same_canonical |
| linkedin-ia-comments | spec-4-challenge | InterviewOS | .claude/commands/spec-4-challenge.md | linkedin-ia-comments | .agents/skills/spec-4-challenge/SKILL.md | shared.spec-4-challenge | 1.0.0 | true | ok_same_canonical |
| linkedin-ia-comments | spec-5-revise | InterviewOS | .claude/commands/spec-5-revise.md | linkedin-ia-comments | .agents/skills/spec-5-revise/SKILL.md | shared.spec-5-revise | 1.0.0 | true | ok_same_canonical |
| linkedin-ia-comments | test | InterviewOS | .claude/commands/test.md | linkedin-ia-comments | .agents/skills/test/SKILL.md | shared.test | 1.0.0 | true | ok_same_canonical |
| linkedin-ia-comments | ui-review | InterviewOS | .claude/commands/ui-review.md | linkedin-ia-comments | .agents/skills/ui-review/SKILL.md | shared.ui-review | 1.0.0 | true | ok_same_canonical |
| suggst | ai-post-task-review | aimoto | .claude/commands/ai-post-task-review.md | suggst | .agents/skills/ai-post-task-review/SKILL.md | shared.ai-post-task-review | 1.0.0 | true | ok_same_canonical |
| suggst | commit | suggst | .claude/commands/commit.md | suggst | .agents/skills/commit/SKILL.md | shared.commit | 1.0.0 | true | ok_same_canonical |
| suggst | create-doc | suggst | .claude/commands/create-doc.md | suggst | .agents/skills/create-doc/SKILL.md | shared.create-doc | 1.0.0 | true | ok_same_canonical |
| suggst | data-slot-add | suggst | .claude/commands/data-slot-add.md |  |  |  |  |  | expected_claude_only |
| suggst | design-audit-context | suggst | .claude/commands/design-audit-context.md |  |  |  |  |  | expected_claude_only |
| suggst | implement | suggst | .claude/commands/implement.md | suggst | .agents/skills/implement/SKILL.md | shared.implement | 1.0.0 | true | ok_same_canonical |
| suggst | landing-review | suggst | .claude/commands/landing-review.md |  |  |  |  |  | expected_claude_only |
| suggst | next-step | suggst | .claude/commands/next-step.md |  |  |  |  |  | expected_claude_only |
| suggst | optimize-claude-md | suggst | .claude/commands/optimize-claude-md.md | suggst | .agents/skills/optimize-claude-md/SKILL.md | shared.optimize-claude-md | 1.0.0 | true | ok_same_canonical |
| suggst | spec-0-feedback | suggst | .claude/commands/spec-0-feedback.md | suggst | .agents/skills/spec-0-feedback/SKILL.md | shared.spec-0-feedback | 1.0.0 | true | ok_same_canonical |
| suggst | spec-1-intake | suggst | .claude/commands/spec-1-intake.md | suggst | .agents/skills/spec-1-intake/SKILL.md | shared.spec-1-intake | 1.0.0 | true | ok_same_canonical |
| suggst | spec-2-draft | suggst | .claude/commands/spec-2-draft.md | suggst | .agents/skills/spec-2-draft/SKILL.md | shared.spec-2-draft | 1.0.0 | true | ok_same_canonical |
| suggst | spec-3-audit | suggst | .claude/commands/spec-3-audit.md | suggst | .agents/skills/spec-3-audit/SKILL.md | shared.spec-3-audit | 1.0.0 | true | ok_same_canonical |
| suggst | spec-4-challenge | suggst | .claude/commands/spec-4-challenge.md | suggst | .agents/skills/spec-4-challenge/SKILL.md | shared.spec-4-challenge | 1.0.0 | true | ok_same_canonical |
| suggst | spec-5-revise | suggst | .claude/commands/spec-5-revise.md | suggst | .agents/skills/spec-5-revise/SKILL.md | shared.spec-5-revise | 1.0.0 | true | ok_same_canonical |
| suggst | test | suggst | .claude/commands/test.md | suggst | .agents/skills/test/SKILL.md | shared.test | 1.0.0 | true | ok_same_canonical |
| suggst | ui-fix-global | suggst | .claude/commands/ui-fix-global.md |  |  |  |  |  | expected_claude_only |
| suggst | ui-review | suggst | .claude/commands/ui-review.md | suggst | .agents/skills/ui-review/SKILL.md | shared.ui-review | 1.0.0 | true | ok_same_canonical |
| suggst | ui-review-global | suggst | .claude/commands/ui-review-global.md |  |  |  |  |  | expected_claude_only |
| truthify | ai-post-task-review | aimoto | .claude/commands/ai-post-task-review.md | truthify | .agents/skills/ai-post-task-review/SKILL.md | shared.ai-post-task-review | 1.0.0 | true | ok_same_canonical |
| truthify | commit | truthify | .claude/commands/commit.md | truthify | .agents/skills/commit/SKILL.md | shared.commit | 1.0.0 | true | ok_same_canonical |
| truthify | create-doc | truthify | .claude/commands/create-doc.md | truthify | .agents/skills/create-doc/SKILL.md | shared.create-doc | 1.0.0 | true | ok_same_canonical |
| truthify | data-slot-add | truthify | .claude/commands/data-slot-add.md |  |  |  |  |  | expected_claude_only |
| truthify | design-audit-context | truthify | .claude/commands/design-audit-context.md |  |  |  |  |  | expected_claude_only |
| truthify | implement | truthify | .claude/commands/implement.md | truthify | .agents/skills/implement/SKILL.md | shared.implement | 1.0.0 | true | ok_same_canonical |
| truthify | landing-review | truthify | .claude/commands/landing-review.md |  |  |  |  |  | expected_claude_only |
| truthify | next-step | truthify | .claude/commands/next-step.md |  |  |  |  |  | expected_claude_only |
| truthify | optimize-claude-md | truthify | .claude/commands/optimize-claude-md.md | truthify | .agents/skills/optimize-claude-md/SKILL.md | shared.optimize-claude-md | 1.0.0 | true | ok_same_canonical |
| truthify | spec-0-feedback | truthify | .claude/commands/spec-0-feedback.md | truthify | .agents/skills/spec-0-feedback/SKILL.md | shared.spec-0-feedback | 1.0.0 | true | ok_same_canonical |
| truthify | spec-1-intake | truthify | .claude/commands/spec-1-intake.md | truthify | .agents/skills/spec-1-intake/SKILL.md | shared.spec-1-intake | 1.0.0 | true | ok_same_canonical |
| truthify | spec-2-draft | truthify | .claude/commands/spec-2-draft.md | truthify | .agents/skills/spec-2-draft/SKILL.md | shared.spec-2-draft | 1.0.0 | true | ok_same_canonical |
| truthify | spec-3-audit | truthify | .claude/commands/spec-3-audit.md | truthify | .agents/skills/spec-3-audit/SKILL.md | shared.spec-3-audit | 1.0.0 | true | ok_same_canonical |
| truthify | spec-4-challenge | truthify | .claude/commands/spec-4-challenge.md | truthify | .agents/skills/spec-4-challenge/SKILL.md | shared.spec-4-challenge | 1.0.0 | true | ok_same_canonical |
| truthify | spec-5-revise | truthify | .claude/commands/spec-5-revise.md | truthify | .agents/skills/spec-5-revise/SKILL.md | shared.spec-5-revise | 1.0.0 | true | ok_same_canonical |
| truthify | test | truthify | .claude/commands/test.md | truthify | .agents/skills/test/SKILL.md | shared.test | 1.0.0 | true | ok_same_canonical |
| truthify | ui-fix-global | truthify | .claude/commands/ui-fix-global.md |  |  |  |  |  | expected_claude_only |
| truthify | ui-review | truthify | .claude/commands/ui-review.md | truthify | .agents/skills/ui-review/SKILL.md | shared.ui-review | 1.0.0 | true | ok_same_canonical |
| truthify | ui-review-global | truthify | .claude/commands/ui-review-global.md |  |  |  |  |  | expected_claude_only |

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
| shared.ai-post-task-review | claude_command | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ai-post-task-review.md | true |
| shared.ai-post-task-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/aimoto/.agents/skills/ai-post-task-review/SKILL.md | true |
| shared.ai-post-task-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/InterviewOS/.agents/skills/ai-post-task-review/SKILL.md | true |
| shared.commit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/InterviewOS/.agents/skills/commit/SKILL.md | true |
| shared.create-doc | codex_skill | /Users/vincentdesbrosses/Documents/Misc/InterviewOS/.agents/skills/create-doc/SKILL.md | true |
| shared.implement | codex_skill | /Users/vincentdesbrosses/Documents/Misc/InterviewOS/.agents/skills/implement/SKILL.md | true |
| shared.optimize-claude-md | codex_skill | /Users/vincentdesbrosses/Documents/Misc/InterviewOS/.agents/skills/optimize-claude-md/SKILL.md | true |
| shared.spec-0-feedback | codex_skill | /Users/vincentdesbrosses/Documents/Misc/InterviewOS/.agents/skills/spec-0-feedback/SKILL.md | true |
| shared.spec-1-intake | codex_skill | /Users/vincentdesbrosses/Documents/Misc/InterviewOS/.agents/skills/spec-1-intake/SKILL.md | true |
| shared.spec-2-draft | codex_skill | /Users/vincentdesbrosses/Documents/Misc/InterviewOS/.agents/skills/spec-2-draft/SKILL.md | true |
| shared.spec-3-audit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/InterviewOS/.agents/skills/spec-3-audit/SKILL.md | true |
| shared.spec-4-challenge | codex_skill | /Users/vincentdesbrosses/Documents/Misc/InterviewOS/.agents/skills/spec-4-challenge/SKILL.md | true |
| shared.spec-5-revise | codex_skill | /Users/vincentdesbrosses/Documents/Misc/InterviewOS/.agents/skills/spec-5-revise/SKILL.md | true |
| shared.test | codex_skill | /Users/vincentdesbrosses/Documents/Misc/InterviewOS/.agents/skills/test/SKILL.md | true |
| shared.ui-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/InterviewOS/.agents/skills/ui-review/SKILL.md | true |
| shared.ai-post-task-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/intrai/.agents/skills/ai-post-task-review/SKILL.md | true |
| shared.commit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/intrai/.agents/skills/commit/SKILL.md | true |
| shared.create-doc | codex_skill | /Users/vincentdesbrosses/Documents/Misc/intrai/.agents/skills/create-doc/SKILL.md | true |
| shared.implement | codex_skill | /Users/vincentdesbrosses/Documents/Misc/intrai/.agents/skills/implement/SKILL.md | true |
| shared.optimize-claude-md | codex_skill | /Users/vincentdesbrosses/Documents/Misc/intrai/.agents/skills/optimize-claude-md/SKILL.md | true |
| shared.spec-0-feedback | codex_skill | /Users/vincentdesbrosses/Documents/Misc/intrai/.agents/skills/spec-0-feedback/SKILL.md | true |
| shared.spec-1-intake | codex_skill | /Users/vincentdesbrosses/Documents/Misc/intrai/.agents/skills/spec-1-intake/SKILL.md | true |
| shared.spec-2-draft | codex_skill | /Users/vincentdesbrosses/Documents/Misc/intrai/.agents/skills/spec-2-draft/SKILL.md | true |
| shared.spec-3-audit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/intrai/.agents/skills/spec-3-audit/SKILL.md | true |
| shared.spec-4-challenge | codex_skill | /Users/vincentdesbrosses/Documents/Misc/intrai/.agents/skills/spec-4-challenge/SKILL.md | true |
| shared.spec-5-revise | codex_skill | /Users/vincentdesbrosses/Documents/Misc/intrai/.agents/skills/spec-5-revise/SKILL.md | true |
| shared.test | codex_skill | /Users/vincentdesbrosses/Documents/Misc/intrai/.agents/skills/test/SKILL.md | true |
| shared.ui-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/intrai/.agents/skills/ui-review/SKILL.md | true |
| shared.ai-post-task-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/linkedin-ia-comments/.agents/skills/ai-post-task-review/SKILL.md | true |
| shared.commit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/linkedin-ia-comments/.agents/skills/commit/SKILL.md | true |
| shared.create-doc | codex_skill | /Users/vincentdesbrosses/Documents/Misc/linkedin-ia-comments/.agents/skills/create-doc/SKILL.md | true |
| shared.implement | codex_skill | /Users/vincentdesbrosses/Documents/Misc/linkedin-ia-comments/.agents/skills/implement/SKILL.md | true |
| shared.optimize-claude-md | codex_skill | /Users/vincentdesbrosses/Documents/Misc/linkedin-ia-comments/.agents/skills/optimize-claude-md/SKILL.md | true |
| shared.spec-0-feedback | codex_skill | /Users/vincentdesbrosses/Documents/Misc/linkedin-ia-comments/.agents/skills/spec-0-feedback/SKILL.md | true |
| shared.spec-1-intake | codex_skill | /Users/vincentdesbrosses/Documents/Misc/linkedin-ia-comments/.agents/skills/spec-1-intake/SKILL.md | true |
| shared.spec-2-draft | codex_skill | /Users/vincentdesbrosses/Documents/Misc/linkedin-ia-comments/.agents/skills/spec-2-draft/SKILL.md | true |
| shared.spec-3-audit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/linkedin-ia-comments/.agents/skills/spec-3-audit/SKILL.md | true |
| shared.spec-4-challenge | codex_skill | /Users/vincentdesbrosses/Documents/Misc/linkedin-ia-comments/.agents/skills/spec-4-challenge/SKILL.md | true |
| shared.spec-5-revise | codex_skill | /Users/vincentdesbrosses/Documents/Misc/linkedin-ia-comments/.agents/skills/spec-5-revise/SKILL.md | true |
| shared.test | codex_skill | /Users/vincentdesbrosses/Documents/Misc/linkedin-ia-comments/.agents/skills/test/SKILL.md | true |
| shared.ui-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/linkedin-ia-comments/.agents/skills/ui-review/SKILL.md | true |
| shared.ai-post-task-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylaa/.agents/skills/ai-post-task-review/SKILL.md | true |
| shared.commit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylaa/.agents/skills/commit/SKILL.md | true |
| shared.create-doc | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylaa/.agents/skills/create-doc/SKILL.md | true |
| shared.implement | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylaa/.agents/skills/implement/SKILL.md | true |
| shared.optimize-claude-md | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylaa/.agents/skills/optimize-claude-md/SKILL.md | true |
| shared.spec-0-feedback | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylaa/.agents/skills/spec-0-feedback/SKILL.md | true |
| shared.spec-1-intake | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylaa/.agents/skills/spec-1-intake/SKILL.md | true |
| shared.spec-2-draft | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylaa/.agents/skills/spec-2-draft/SKILL.md | true |
| shared.spec-3-audit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylaa/.agents/skills/spec-3-audit/SKILL.md | true |
| shared.spec-4-challenge | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylaa/.agents/skills/spec-4-challenge/SKILL.md | true |
| shared.spec-5-revise | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylaa/.agents/skills/spec-5-revise/SKILL.md | true |
| shared.test | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylaa/.agents/skills/test/SKILL.md | true |
| shared.ui-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylaa/.agents/skills/ui-review/SKILL.md | true |
| shared.ai-post-task-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylot/.agents/skills/ai-post-task-review/SKILL.md | true |
| shared.commit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylot/.agents/skills/commit/SKILL.md | true |
| shared.create-doc | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylot/.agents/skills/create-doc/SKILL.md | true |
| shared.implement | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylot/.agents/skills/implement/SKILL.md | true |
| shared.optimize-claude-md | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylot/.agents/skills/optimize-claude-md/SKILL.md | true |
| shared.spec-0-feedback | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylot/.agents/skills/spec-0-feedback/SKILL.md | true |
| shared.spec-1-intake | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylot/.agents/skills/spec-1-intake/SKILL.md | true |
| shared.spec-2-draft | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylot/.agents/skills/spec-2-draft/SKILL.md | true |
| shared.spec-3-audit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylot/.agents/skills/spec-3-audit/SKILL.md | true |
| shared.spec-4-challenge | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylot/.agents/skills/spec-4-challenge/SKILL.md | true |
| shared.spec-5-revise | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylot/.agents/skills/spec-5-revise/SKILL.md | true |
| shared.test | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylot/.agents/skills/test/SKILL.md | true |
| shared.ui-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Pylot/.agents/skills/ui-review/SKILL.md | true |
| shared.ai-post-task-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Skriipt/.agents/skills/ai-post-task-review/SKILL.md | true |
| shared.commit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Skriipt/.agents/skills/commit/SKILL.md | true |
| shared.create-doc | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Skriipt/.agents/skills/create-doc/SKILL.md | true |
| shared.implement | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Skriipt/.agents/skills/implement/SKILL.md | true |
| shared.optimize-claude-md | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Skriipt/.agents/skills/optimize-claude-md/SKILL.md | true |
| shared.spec-0-feedback | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Skriipt/.agents/skills/spec-0-feedback/SKILL.md | true |
| shared.spec-1-intake | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Skriipt/.agents/skills/spec-1-intake/SKILL.md | true |
| shared.spec-2-draft | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Skriipt/.agents/skills/spec-2-draft/SKILL.md | true |
| shared.spec-3-audit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Skriipt/.agents/skills/spec-3-audit/SKILL.md | true |
| shared.spec-4-challenge | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Skriipt/.agents/skills/spec-4-challenge/SKILL.md | true |
| shared.spec-5-revise | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Skriipt/.agents/skills/spec-5-revise/SKILL.md | true |
| shared.test | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Skriipt/.agents/skills/test/SKILL.md | true |
| shared.ui-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Skriipt/.agents/skills/ui-review/SKILL.md | true |
| shared.ai-post-task-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Spotter/.agents/skills/ai-post-task-review/SKILL.md | true |
| shared.commit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Spotter/.agents/skills/commit/SKILL.md | true |
| shared.create-doc | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Spotter/.agents/skills/create-doc/SKILL.md | true |
| shared.implement | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Spotter/.agents/skills/implement/SKILL.md | true |
| shared.optimize-claude-md | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Spotter/.agents/skills/optimize-claude-md/SKILL.md | true |
| shared.spec-0-feedback | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Spotter/.agents/skills/spec-0-feedback/SKILL.md | true |
| shared.spec-1-intake | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Spotter/.agents/skills/spec-1-intake/SKILL.md | true |
| shared.spec-2-draft | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Spotter/.agents/skills/spec-2-draft/SKILL.md | true |
| shared.spec-3-audit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Spotter/.agents/skills/spec-3-audit/SKILL.md | true |
| shared.spec-4-challenge | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Spotter/.agents/skills/spec-4-challenge/SKILL.md | true |
| shared.spec-5-revise | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Spotter/.agents/skills/spec-5-revise/SKILL.md | true |
| shared.test | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Spotter/.agents/skills/test/SKILL.md | true |
| shared.ui-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/Spotter/.agents/skills/ui-review/SKILL.md | true |
| shared.ai-post-task-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/suggst/.agents/skills/ai-post-task-review/SKILL.md | true |
| shared.commit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/suggst/.agents/skills/commit/SKILL.md | true |
| shared.create-doc | codex_skill | /Users/vincentdesbrosses/Documents/Misc/suggst/.agents/skills/create-doc/SKILL.md | true |
| shared.implement | codex_skill | /Users/vincentdesbrosses/Documents/Misc/suggst/.agents/skills/implement/SKILL.md | true |
| shared.optimize-claude-md | codex_skill | /Users/vincentdesbrosses/Documents/Misc/suggst/.agents/skills/optimize-claude-md/SKILL.md | true |
| shared.spec-0-feedback | codex_skill | /Users/vincentdesbrosses/Documents/Misc/suggst/.agents/skills/spec-0-feedback/SKILL.md | true |
| shared.spec-1-intake | codex_skill | /Users/vincentdesbrosses/Documents/Misc/suggst/.agents/skills/spec-1-intake/SKILL.md | true |
| shared.spec-2-draft | codex_skill | /Users/vincentdesbrosses/Documents/Misc/suggst/.agents/skills/spec-2-draft/SKILL.md | true |
| shared.spec-3-audit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/suggst/.agents/skills/spec-3-audit/SKILL.md | true |
| shared.spec-4-challenge | codex_skill | /Users/vincentdesbrosses/Documents/Misc/suggst/.agents/skills/spec-4-challenge/SKILL.md | true |
| shared.spec-5-revise | codex_skill | /Users/vincentdesbrosses/Documents/Misc/suggst/.agents/skills/spec-5-revise/SKILL.md | true |
| shared.test | codex_skill | /Users/vincentdesbrosses/Documents/Misc/suggst/.agents/skills/test/SKILL.md | true |
| shared.ui-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/suggst/.agents/skills/ui-review/SKILL.md | true |
| shared.ai-post-task-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/truthify/.agents/skills/ai-post-task-review/SKILL.md | true |
| shared.commit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/truthify/.agents/skills/commit/SKILL.md | true |
| shared.create-doc | codex_skill | /Users/vincentdesbrosses/Documents/Misc/truthify/.agents/skills/create-doc/SKILL.md | true |
| shared.implement | codex_skill | /Users/vincentdesbrosses/Documents/Misc/truthify/.agents/skills/implement/SKILL.md | true |
| shared.optimize-claude-md | codex_skill | /Users/vincentdesbrosses/Documents/Misc/truthify/.agents/skills/optimize-claude-md/SKILL.md | true |
| shared.spec-0-feedback | codex_skill | /Users/vincentdesbrosses/Documents/Misc/truthify/.agents/skills/spec-0-feedback/SKILL.md | true |
| shared.spec-1-intake | codex_skill | /Users/vincentdesbrosses/Documents/Misc/truthify/.agents/skills/spec-1-intake/SKILL.md | true |
| shared.spec-2-draft | codex_skill | /Users/vincentdesbrosses/Documents/Misc/truthify/.agents/skills/spec-2-draft/SKILL.md | true |
| shared.spec-3-audit | codex_skill | /Users/vincentdesbrosses/Documents/Misc/truthify/.agents/skills/spec-3-audit/SKILL.md | true |
| shared.spec-4-challenge | codex_skill | /Users/vincentdesbrosses/Documents/Misc/truthify/.agents/skills/spec-4-challenge/SKILL.md | true |
| shared.spec-5-revise | codex_skill | /Users/vincentdesbrosses/Documents/Misc/truthify/.agents/skills/spec-5-revise/SKILL.md | true |
| shared.test | codex_skill | /Users/vincentdesbrosses/Documents/Misc/truthify/.agents/skills/test/SKILL.md | true |
| shared.ui-review | codex_skill | /Users/vincentdesbrosses/Documents/Misc/truthify/.agents/skills/ui-review/SKILL.md | true |

## Action required

| Severity | Code | Artifact | Path | Message |
|---|---|---|---|---|
|  |  |  |  | No action required. |

## Accepted findings

These findings remain visible for auditability. Fallback candidates in this section were classified `acceptable` by the same rules as `ai_doctor.py`; advisory metadata findings are non-blocking.

| Code | Artifact | Path | Classification | Message |
|---|---|---|---|---|
| fallback_candidate | add-indicator | .agents/skills/add-indicator/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | add-indicator | .agents/skills/add-indicator/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | edit-export-llm-report | .agents/skills/edit-export-llm-report/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | edit-export-llm-report | .agents/skills/edit-export-llm-report/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | implement | .agents/skills/implement/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | implement-remediation-spec | .agents/skills/implement-remediation-spec/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | next | .agents/skills/next/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .agents/skills/spec-1-intake/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .agents/skills/spec-3-audit/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .agents/skills/spec-5-revise/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | update-strategy | .agents/skills/update-strategy/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | update-strategy | .agents/skills/update-strategy/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | update-strategy | .agents/skills/update-strategy/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | add-indicator | .claude/commands/add-indicator.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | add-indicator | .claude/commands/add-indicator.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | edit-export-llm-report | .claude/commands/edit-export-llm-report.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | edit-export-llm-report | .claude/commands/edit-export-llm-report.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | implement-remediation-spec | .claude/commands/implement-remediation-spec.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | implement | .claude/commands/implement.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | next | .claude/commands/next.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .claude/commands/spec-1-intake.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .claude/commands/spec-3-audit.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .claude/commands/spec-5-revise.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | update-strategy | .claude/commands/update-strategy.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | update-strategy | .claude/commands/update-strategy.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | update-strategy | .claude/commands/update-strategy.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | _template | .claude/strategy-profiles/_template.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | forecast_signal_driven_long_only | .claude/strategy-profiles/forecast_signal_driven_long_only.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | AGENTS | AGENTS.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | CLAUDE | CLAUDE.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | project-config | .claude/project-config.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | implement | .agents/skills/implement/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .agents/skills/spec-1-intake/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .agents/skills/spec-3-audit/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .agents/skills/spec-5-revise/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | implement | .claude/commands/implement.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .claude/commands/spec-1-intake.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .claude/commands/spec-3-audit.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .claude/commands/spec-5-revise.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | project-config | .claude/project-config.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | implement | .agents/skills/implement/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .agents/skills/spec-1-intake/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .agents/skills/spec-3-audit/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .agents/skills/spec-5-revise/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | implement | .agents/skills/implement/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .agents/skills/spec-1-intake/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .agents/skills/spec-3-audit/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .agents/skills/spec-5-revise/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | implement | .agents/skills/implement/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .agents/skills/spec-1-intake/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .agents/skills/spec-3-audit/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .agents/skills/spec-5-revise/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| missing_frontmatter | data-slot-add | .claude/commands/data-slot-add.md | advisory | Frontmatter YAML absent. |
| missing_name | design-audit-context | .claude/commands/design-audit-context.md | advisory | Champ frontmatter manquant : name |
| missing_description | design-audit-context | .claude/commands/design-audit-context.md | advisory | Champ frontmatter manquant : description |
| fallback_candidate | implement | .claude/commands/implement.md | acceptable | Pattern suspect détecté : fallback |
| missing_frontmatter | landing-review | .claude/commands/landing-review.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | landing-review | .claude/commands/landing-review.md | acceptable | Pattern suspect détecté : si absent |
| missing_frontmatter | next-step | .claude/commands/next-step.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .claude/commands/spec-1-intake.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .claude/commands/spec-3-audit.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .claude/commands/spec-5-revise.md | acceptable | Pattern suspect détecté : par défaut |
| missing_frontmatter | ui-fix-global | .claude/commands/ui-fix-global.md | advisory | Frontmatter YAML absent. |
| missing_frontmatter | ui-review-global | .claude/commands/ui-review-global.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | AGENTS | AGENTS.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | CLAUDE | CLAUDE.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | ARCHITECTURE | docs/ARCHITECTURE.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | ARCHITECTURE | docs/ARCHITECTURE.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | implement | .agents/skills/implement/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .agents/skills/spec-1-intake/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .agents/skills/spec-3-audit/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .agents/skills/spec-5-revise/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| missing_frontmatter | data-slot-add | .claude/commands/data-slot-add.md | advisory | Frontmatter YAML absent. |
| missing_name | design-audit-context | .claude/commands/design-audit-context.md | advisory | Champ frontmatter manquant : name |
| missing_description | design-audit-context | .claude/commands/design-audit-context.md | advisory | Champ frontmatter manquant : description |
| fallback_candidate | implement | .claude/commands/implement.md | acceptable | Pattern suspect détecté : fallback |
| missing_frontmatter | landing-review | .claude/commands/landing-review.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | landing-review | .claude/commands/landing-review.md | acceptable | Pattern suspect détecté : si absent |
| missing_frontmatter | next-step | .claude/commands/next-step.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .claude/commands/spec-1-intake.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .claude/commands/spec-3-audit.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .claude/commands/spec-5-revise.md | acceptable | Pattern suspect détecté : par défaut |
| missing_frontmatter | ui-fix-global | .claude/commands/ui-fix-global.md | advisory | Frontmatter YAML absent. |
| missing_frontmatter | ui-review-global | .claude/commands/ui-review-global.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | ARCHITECTURE | docs/ARCHITECTURE.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | implement | .agents/skills/implement/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .agents/skills/spec-1-intake/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .agents/skills/spec-3-audit/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .agents/skills/spec-5-revise/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| missing_frontmatter | data-slot-add | .claude/commands/data-slot-add.md | advisory | Frontmatter YAML absent. |
| missing_name | design-audit-context | .claude/commands/design-audit-context.md | advisory | Champ frontmatter manquant : name |
| missing_description | design-audit-context | .claude/commands/design-audit-context.md | advisory | Champ frontmatter manquant : description |
| fallback_candidate | implement | .claude/commands/implement.md | acceptable | Pattern suspect détecté : fallback |
| missing_frontmatter | landing-review | .claude/commands/landing-review.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | landing-review | .claude/commands/landing-review.md | acceptable | Pattern suspect détecté : si absent |
| missing_frontmatter | next-step | .claude/commands/next-step.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | spec-1-intake | .claude/commands/spec-1-intake.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .claude/commands/spec-3-audit.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .claude/commands/spec-5-revise.md | acceptable | Pattern suspect détecté : par défaut |
| missing_frontmatter | ui-fix-global | .claude/commands/ui-fix-global.md | advisory | Frontmatter YAML absent. |
| missing_frontmatter | ui-review-global | .claude/commands/ui-review-global.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | ARCHITECTURE | docs/ARCHITECTURE.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | implement | .agents/skills/implement/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .agents/skills/spec-1-intake/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .agents/skills/spec-3-audit/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .agents/skills/spec-5-revise/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | implement | .agents/skills/implement/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .agents/skills/spec-1-intake/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .agents/skills/spec-3-audit/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .agents/skills/spec-5-revise/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| missing_frontmatter | data-slot-add | .claude/commands/data-slot-add.md | advisory | Frontmatter YAML absent. |
| missing_name | design-audit-context | .claude/commands/design-audit-context.md | advisory | Champ frontmatter manquant : name |
| missing_description | design-audit-context | .claude/commands/design-audit-context.md | advisory | Champ frontmatter manquant : description |
| fallback_candidate | implement | .claude/commands/implement.md | acceptable | Pattern suspect détecté : fallback |
| missing_frontmatter | landing-review | .claude/commands/landing-review.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | landing-review | .claude/commands/landing-review.md | acceptable | Pattern suspect détecté : si absent |
| missing_frontmatter | next-step | .claude/commands/next-step.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .claude/commands/spec-1-intake.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .claude/commands/spec-3-audit.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .claude/commands/spec-5-revise.md | acceptable | Pattern suspect détecté : par défaut |
| missing_frontmatter | ui-fix-global | .claude/commands/ui-fix-global.md | advisory | Frontmatter YAML absent. |
| missing_frontmatter | ui-review-global | .claude/commands/ui-review-global.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | ARCHITECTURE | docs/ARCHITECTURE.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | implement | .agents/skills/implement/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .agents/skills/optimize-claude-md/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .agents/skills/spec-1-intake/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .agents/skills/spec-3-audit/SKILL.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .agents/skills/spec-5-revise/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .agents/skills/ui-review/SKILL.md | acceptable | Pattern suspect détecté : fallback |
| missing_frontmatter | data-slot-add | .claude/commands/data-slot-add.md | advisory | Frontmatter YAML absent. |
| missing_name | design-audit-context | .claude/commands/design-audit-context.md | advisory | Champ frontmatter manquant : name |
| missing_description | design-audit-context | .claude/commands/design-audit-context.md | advisory | Champ frontmatter manquant : description |
| fallback_candidate | implement | .claude/commands/implement.md | acceptable | Pattern suspect détecté : fallback |
| missing_frontmatter | landing-review | .claude/commands/landing-review.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | landing-review | .claude/commands/landing-review.md | acceptable | Pattern suspect détecté : si absent |
| missing_frontmatter | next-step | .claude/commands/next-step.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | optimize-claude-md | .claude/commands/optimize-claude-md.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-1-intake | .claude/commands/spec-1-intake.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | spec-3-audit | .claude/commands/spec-3-audit.md | acceptable | Pattern suspect détecté : si absent |
| fallback_candidate | spec-5-revise | .claude/commands/spec-5-revise.md | acceptable | Pattern suspect détecté : par défaut |
| missing_frontmatter | ui-fix-global | .claude/commands/ui-fix-global.md | advisory | Frontmatter YAML absent. |
| missing_frontmatter | ui-review-global | .claude/commands/ui-review-global.md | advisory | Frontmatter YAML absent. |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : par défaut |
| fallback_candidate | ui-review | .claude/commands/ui-review.md | acceptable | Pattern suspect détecté : fallback |
| fallback_candidate | CLAUDE | CLAUDE.md | acceptable | Pattern suspect détecté : fallback |

## Expected pairing exceptions

| Project | Name | Status | Path | Reason |
|---|---|---|---|---|
| Pylaa | data-slot-add | expected_claude_only | .claude/commands/data-slot-add.md | Commande projet Pylaa non convertie automatiquement en Codex skill. |
| Pylaa | design-audit-context | expected_claude_only | .claude/commands/design-audit-context.md | Commande projet Pylaa non convertie automatiquement en Codex skill. |
| Pylaa | landing-review | expected_claude_only | .claude/commands/landing-review.md | Commande projet Pylaa non convertie automatiquement en Codex skill. |
| Pylaa | next-step | expected_claude_only | .claude/commands/next-step.md | Commande projet Pylaa non convertie automatiquement en Codex skill. |
| Pylaa | ui-fix-global | expected_claude_only | .claude/commands/ui-fix-global.md | Commande projet Pylaa non convertie automatiquement en Codex skill. |
| Pylaa | ui-review-global | expected_claude_only | .claude/commands/ui-review-global.md | Commande projet Pylaa non convertie automatiquement en Codex skill. |
| Pylot | data-slot-add | expected_claude_only | .claude/commands/data-slot-add.md | Commande projet Pylot non convertie automatiquement en Codex skill. |
| Pylot | design-audit-context | expected_claude_only | .claude/commands/design-audit-context.md | Commande projet Pylot non convertie automatiquement en Codex skill. |
| Pylot | landing-review | expected_claude_only | .claude/commands/landing-review.md | Commande projet Pylot non convertie automatiquement en Codex skill. |
| Pylot | next-step | expected_claude_only | .claude/commands/next-step.md | Commande projet Pylot non convertie automatiquement en Codex skill. |
| Pylot | ui-fix-global | expected_claude_only | .claude/commands/ui-fix-global.md | Commande projet Pylot non convertie automatiquement en Codex skill. |
| Pylot | ui-review-global | expected_claude_only | .claude/commands/ui-review-global.md | Commande projet Pylot non convertie automatiquement en Codex skill. |
| Skriipt | data-slot-add | expected_claude_only | .claude/commands/data-slot-add.md | Commande projet Skriipt non convertie automatiquement en Codex skill. |
| Skriipt | design-audit-context | expected_claude_only | .claude/commands/design-audit-context.md | Commande projet Skriipt non convertie automatiquement en Codex skill. |
| Skriipt | landing-review | expected_claude_only | .claude/commands/landing-review.md | Commande projet Skriipt non convertie automatiquement en Codex skill. |
| Skriipt | next-step | expected_claude_only | .claude/commands/next-step.md | Commande projet Skriipt non convertie automatiquement en Codex skill. |
| Skriipt | ui-fix-global | expected_claude_only | .claude/commands/ui-fix-global.md | Commande projet Skriipt non convertie automatiquement en Codex skill. |
| Skriipt | ui-review-global | expected_claude_only | .claude/commands/ui-review-global.md | Commande projet Skriipt non convertie automatiquement en Codex skill. |
| suggst | data-slot-add | expected_claude_only | .claude/commands/data-slot-add.md | Commande projet suggst non convertie automatiquement en Codex skill. |
| suggst | design-audit-context | expected_claude_only | .claude/commands/design-audit-context.md | Commande projet suggst non convertie automatiquement en Codex skill. |
| suggst | landing-review | expected_claude_only | .claude/commands/landing-review.md | Commande projet suggst non convertie automatiquement en Codex skill. |
| suggst | next-step | expected_claude_only | .claude/commands/next-step.md | Commande projet suggst non convertie automatiquement en Codex skill. |
| suggst | ui-fix-global | expected_claude_only | .claude/commands/ui-fix-global.md | Commande projet suggst non convertie automatiquement en Codex skill. |
| suggst | ui-review-global | expected_claude_only | .claude/commands/ui-review-global.md | Commande projet suggst non convertie automatiquement en Codex skill. |
| truthify | data-slot-add | expected_claude_only | .claude/commands/data-slot-add.md | Commande projet truthify non convertie automatiquement en Codex skill. |
| truthify | design-audit-context | expected_claude_only | .claude/commands/design-audit-context.md | Commande projet truthify non convertie automatiquement en Codex skill. |
| truthify | landing-review | expected_claude_only | .claude/commands/landing-review.md | Commande projet truthify non convertie automatiquement en Codex skill. |
| truthify | next-step | expected_claude_only | .claude/commands/next-step.md | Commande projet truthify non convertie automatiquement en Codex skill. |
| truthify | ui-fix-global | expected_claude_only | .claude/commands/ui-fix-global.md | Commande projet truthify non convertie automatiquement en Codex skill. |
| truthify | ui-review-global | expected_claude_only | .claude/commands/ui-review-global.md | Commande projet truthify non convertie automatiquement en Codex skill. |

## Symlinks

| Artifact | Type | Path | Target | Status |
|---|---|---|---|---|
| ai-post-task-review | claude_command | .claude/commands/ai-post-task-review.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ai-post-task-review.md | ok |
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
| commit | claude_command | .claude/commands/commit.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/commit.md | ok |
| create-doc | claude_command | .claude/commands/create-doc.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/create-doc.md | ok |
| data-slot-add | claude_command | .claude/commands/data-slot-add.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/data-slot-add.md | ok |
| design-audit-context | claude_command | .claude/commands/design-audit-context.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/design-audit-context.md | ok |
| implement | claude_command | .claude/commands/implement.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/implement.md | ok |
| landing-review | claude_command | .claude/commands/landing-review.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/landing-review.md | ok |
| next-step | claude_command | .claude/commands/next-step.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/next-step.md | ok |
| optimize-claude-md | claude_command | .claude/commands/optimize-claude-md.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/optimize-claude-md.md | ok |
| spec-0-feedback | claude_command | .claude/commands/spec-0-feedback.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-0-feedback.md | ok |
| spec-1-intake | claude_command | .claude/commands/spec-1-intake.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-1-intake.md | ok |
| spec-2-draft | claude_command | .claude/commands/spec-2-draft.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-2-draft.md | ok |
| spec-3-audit | claude_command | .claude/commands/spec-3-audit.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-3-audit.md | ok |
| spec-4-challenge | claude_command | .claude/commands/spec-4-challenge.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-4-challenge.md | ok |
| spec-5-revise | claude_command | .claude/commands/spec-5-revise.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-5-revise.md | ok |
| test | claude_command | .claude/commands/test.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/test.md | ok |
| ui-fix-global | claude_command | .claude/commands/ui-fix-global.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-fix-global.md | ok |
| ui-review-global | claude_command | .claude/commands/ui-review-global.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-review-global.md | ok |
| ui-review | claude_command | .claude/commands/ui-review.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-review.md | ok |
| commit | claude_command | .claude/commands/commit.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/commit.md | ok |
| create-doc | claude_command | .claude/commands/create-doc.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/create-doc.md | ok |
| data-slot-add | claude_command | .claude/commands/data-slot-add.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/data-slot-add.md | ok |
| design-audit-context | claude_command | .claude/commands/design-audit-context.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/design-audit-context.md | ok |
| implement | claude_command | .claude/commands/implement.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/implement.md | ok |
| landing-review | claude_command | .claude/commands/landing-review.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/landing-review.md | ok |
| next-step | claude_command | .claude/commands/next-step.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/next-step.md | ok |
| optimize-claude-md | claude_command | .claude/commands/optimize-claude-md.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/optimize-claude-md.md | ok |
| spec-0-feedback | claude_command | .claude/commands/spec-0-feedback.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-0-feedback.md | ok |
| spec-1-intake | claude_command | .claude/commands/spec-1-intake.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-1-intake.md | ok |
| spec-2-draft | claude_command | .claude/commands/spec-2-draft.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-2-draft.md | ok |
| spec-3-audit | claude_command | .claude/commands/spec-3-audit.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-3-audit.md | ok |
| spec-4-challenge | claude_command | .claude/commands/spec-4-challenge.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-4-challenge.md | ok |
| spec-5-revise | claude_command | .claude/commands/spec-5-revise.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-5-revise.md | ok |
| test | claude_command | .claude/commands/test.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/test.md | ok |
| ui-fix-global | claude_command | .claude/commands/ui-fix-global.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-fix-global.md | ok |
| ui-review-global | claude_command | .claude/commands/ui-review-global.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-review-global.md | ok |
| ui-review | claude_command | .claude/commands/ui-review.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-review.md | ok |
| commit | claude_command | .claude/commands/commit.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/commit.md | ok |
| data-slot-add | claude_command | .claude/commands/data-slot-add.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/data-slot-add.md | ok |
| design-audit-context | claude_command | .claude/commands/design-audit-context.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/design-audit-context.md | ok |
| implement | claude_command | .claude/commands/implement.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/implement.md | ok |
| landing-review | claude_command | .claude/commands/landing-review.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/landing-review.md | ok |
| next-step | claude_command | .claude/commands/next-step.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/next-step.md | ok |
| spec-0-feedback | claude_command | .claude/commands/spec-0-feedback.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-0-feedback.md | ok |
| spec-1-intake | claude_command | .claude/commands/spec-1-intake.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-1-intake.md | ok |
| spec-2-draft | claude_command | .claude/commands/spec-2-draft.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-2-draft.md | ok |
| spec-3-audit | claude_command | .claude/commands/spec-3-audit.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-3-audit.md | ok |
| spec-4-challenge | claude_command | .claude/commands/spec-4-challenge.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-4-challenge.md | ok |
| spec-5-revise | claude_command | .claude/commands/spec-5-revise.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-5-revise.md | ok |
| ui-fix-global | claude_command | .claude/commands/ui-fix-global.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-fix-global.md | ok |
| ui-review-global | claude_command | .claude/commands/ui-review-global.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-review-global.md | ok |
| ui-review | claude_command | .claude/commands/ui-review.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-review.md | ok |
| commit | claude_command | .claude/commands/commit.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/commit.md | ok |
| create-doc | claude_command | .claude/commands/create-doc.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/create-doc.md | ok |
| data-slot-add | claude_command | .claude/commands/data-slot-add.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/data-slot-add.md | ok |
| design-audit-context | claude_command | .claude/commands/design-audit-context.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/design-audit-context.md | ok |
| implement | claude_command | .claude/commands/implement.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/implement.md | ok |
| landing-review | claude_command | .claude/commands/landing-review.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/landing-review.md | ok |
| next-step | claude_command | .claude/commands/next-step.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/next-step.md | ok |
| optimize-claude-md | claude_command | .claude/commands/optimize-claude-md.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/optimize-claude-md.md | ok |
| spec-0-feedback | claude_command | .claude/commands/spec-0-feedback.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-0-feedback.md | ok |
| spec-1-intake | claude_command | .claude/commands/spec-1-intake.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-1-intake.md | ok |
| spec-2-draft | claude_command | .claude/commands/spec-2-draft.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-2-draft.md | ok |
| spec-3-audit | claude_command | .claude/commands/spec-3-audit.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-3-audit.md | ok |
| spec-4-challenge | claude_command | .claude/commands/spec-4-challenge.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-4-challenge.md | ok |
| spec-5-revise | claude_command | .claude/commands/spec-5-revise.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-5-revise.md | ok |
| test | claude_command | .claude/commands/test.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/test.md | ok |
| ui-fix-global | claude_command | .claude/commands/ui-fix-global.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-fix-global.md | ok |
| ui-review-global | claude_command | .claude/commands/ui-review-global.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-review-global.md | ok |
| ui-review | claude_command | .claude/commands/ui-review.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-review.md | ok |
| commit | claude_command | .claude/commands/commit.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/commit.md | ok |
| create-doc | claude_command | .claude/commands/create-doc.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/create-doc.md | ok |
| data-slot-add | claude_command | .claude/commands/data-slot-add.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/data-slot-add.md | ok |
| design-audit-context | claude_command | .claude/commands/design-audit-context.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/design-audit-context.md | ok |
| implement | claude_command | .claude/commands/implement.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/implement.md | ok |
| landing-review | claude_command | .claude/commands/landing-review.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/landing-review.md | ok |
| next-step | claude_command | .claude/commands/next-step.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/next-step.md | ok |
| optimize-claude-md | claude_command | .claude/commands/optimize-claude-md.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/optimize-claude-md.md | ok |
| spec-0-feedback | claude_command | .claude/commands/spec-0-feedback.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-0-feedback.md | ok |
| spec-1-intake | claude_command | .claude/commands/spec-1-intake.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-1-intake.md | ok |
| spec-2-draft | claude_command | .claude/commands/spec-2-draft.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-2-draft.md | ok |
| spec-3-audit | claude_command | .claude/commands/spec-3-audit.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-3-audit.md | ok |
| spec-4-challenge | claude_command | .claude/commands/spec-4-challenge.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-4-challenge.md | ok |
| spec-5-revise | claude_command | .claude/commands/spec-5-revise.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/spec-5-revise.md | ok |
| test | claude_command | .claude/commands/test.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/test.md | ok |
| ui-fix-global | claude_command | .claude/commands/ui-fix-global.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-fix-global.md | ok |
| ui-review-global | claude_command | .claude/commands/ui-review-global.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-review-global.md | ok |
| ui-review | claude_command | .claude/commands/ui-review.md | /Users/vincentdesbrosses/Documents/Misc/claude-commands/ui-review.md | ok |

## Recommended next actions

1. Vérifier que `implement`, `new-strategy` et `update-strategy` sont en `ok_same_canonical`.
2. Ajouter le frontmatter runtime minimal aux exports encore actifs sans `name` / `description`.
3. Corriger `update-strategy` pour supprimer les fallbacks implicites.
4. Créer ensuite `sync_skills.py` pour générer les exports depuis `canonical.md`.
