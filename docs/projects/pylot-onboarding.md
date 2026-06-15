# Pylot - AI System onboarding

## Politique d'installation

Pylot installe localement les skills Codex `shared.*` declares dans
`projects[].install_shared_skills` dans `skills-registry.yml`.

Les exports sont generes dans `Pylot/.agents/skills/<skill>/SKILL.md` depuis
les canonicals shared existants. Le registre porte la politique d'installation
par projet; le manifest reste la source des metadonnees canoniques.

Le socle installe est identique a InterviewOS, intrai et Pylaa:

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
- Architecture: `docs/ARCHITECTURE.md`

Les paths absents sont toleres par l'inventaire et pourront etre crees plus
tard si le projet en a besoin.

## Isolation des projets

Pylot ne recoit aucun canonical `aimoto.*`, `interviewos.*`, `intrai.*` ou
`pylaa.*`. Aucun canonical `pylot.*` n'est cree tant qu'un besoin projet
explicite ne le justifie pas.

Les commandes Claude suivantes sont propres au projet et ne sont pas
converties automatiquement en skills Codex:

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
canonical `pylot.*` explicite et retirer l'exception correspondante.

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
rapport avec Pylot.

## Validation

Depuis `ai-system`:

```bash
./run-inventory.sh
.venv/bin/python scripts/ai_doctor.py --inventory
```

Depuis `Pylot`:

```bash
find .agents/skills -maxdepth 2 -name "SKILL.md" -print | sort
grep -R "aimoto\|AIMOTO\|InterviewOS\|intrai\|Pylaa\|BTC\|backtesting\|forecast\|strategy-loop\|AIMOTO_DATA_DIR" \
  .agents/skills || true
```

Etat attendu:

- 13 shared skills Codex locaux;
- aucun canonical project-specific etranger;
- six `expected_claude_only` pour les commandes Pylot listees;
- `missing_codex_skill = 0`;
- aucun drift;
- AI Doctor `OK`.
