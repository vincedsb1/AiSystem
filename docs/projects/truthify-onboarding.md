# truthify - AI System onboarding

## Politique d'installation

truthify installe localement les skills Codex `shared.*` declares dans
`projects[].install_shared_skills` dans `skills-registry.yml`.

Les exports sont generes dans `truthify/.agents/skills/<skill>/SKILL.md` depuis
les canonicals shared existants. Le registre porte la politique d'installation
par projet; le manifest reste la source des metadonnees canoniques.

Le socle installe est identique aux autres projets onboardes:

- `shared.ai-post-task-review`
- `shared.commit`
- `shared.create-doc`
- `shared.implement`
- `shared.optimize-claude-md`
- `shared.spec-0-feedback`
- `shared.spec-1-intake`
- `shared.spec-2-draft`
- `shared.spec-3-audit`
- `shared.spec-4-challenge`
- `shared.spec-5-revise`
- `shared.test`
- `shared.ui-review`

## Paths declares

- Codex skills: `.agents/skills`
- Claude commands: `.claude/commands`
- Claude rules: `.claude/rules`
- Claude strategy profiles: `.claude/strategy-profiles`
- Claude hooks: `.claude/hooks`
- Codex hooks: `.codex/hooks`
- Agent instructions: `AGENTS.md` (absent actuellement)
- Claude instructions: `CLAUDE.md`
- Project config: `.claude/project-config.md` (absent actuellement)
- Architecture: `docs/ARCHITECTURE.md` (absent actuellement)

Le depot contient actuellement `COMPONENT_ARCHITECTURE_REFACTOR.md`, un
document de refactor cible, mais pas de document d'architecture global au path
standard. Les paths absents sont toleres par l'inventaire et pourront etre
crees plus tard si le projet en a besoin.

## Commandes Claude propres au projet

Les commandes suivantes sont propres a truthify et ne sont pas converties
automatiquement en skills Codex:

- `data-slot-add`
- `design-audit-context`
- `landing-review`
- `next-step`
- `ui-fix-global`
- `ui-review-global`

Ces exceptions sont declarees individuellement dans
`skills-registry.yml::pairing_exceptions` et apparaissent comme
`expected_claude_only` dans l'inventaire. Elles ne masquent ni les drifts ni
les erreurs de metadata. Toute canonicalisation future devra utiliser un
canonical `truthify.*` explicite et retirer l'exception correspondante.

## Isolation des projets

truthify ne recoit aucun canonical `aimoto.*`, `interviewos.*`, `intrai.*`,
`pylaa.*`, `pylot.*`, `skriipt.*`, `spotter.*` ou `suggst.*`. Aucun canonical
`truthify.*` n'est cree pendant cet onboarding.

## Synchronisation

Depuis `ai-system`:

```bash
.venv/bin/python scripts/sync_skills.py --apply --no-backup \
  --only shared.ai-post-task-review shared.commit shared.create-doc \
  shared.implement shared.optimize-claude-md shared.spec-0-feedback \
  shared.spec-1-intake shared.spec-2-draft shared.spec-3-audit \
  shared.spec-4-challenge shared.spec-5-revise shared.test shared.ui-review
```

Le filtre `--only` evite de synchroniser des canonicals project-specific sans
rapport avec truthify.

## Validation

Depuis `ai-system`:

```bash
./run-inventory.sh
.venv/bin/python scripts/ai_doctor.py --inventory
```

Depuis `truthify`:

```bash
find .agents/skills -maxdepth 2 -name "SKILL.md" -print | sort
grep -R "aimoto\|AIMOTO\|InterviewOS\|intrai\|Pylaa\|Pylot\|Skriipt\|Spotter\|suggst\|BTC\|backtesting\|forecast\|strategy-loop\|AIMOTO_DATA_DIR" \
  .agents/skills || true
```

Etat attendu:

- 13 shared skills Codex locaux;
- aucun canonical project-specific etranger;
- six `expected_claude_only` pour les commandes truthify listees;
- `missing_codex_skill = 0`;
- aucun drift;
- AI Doctor `OK`.
