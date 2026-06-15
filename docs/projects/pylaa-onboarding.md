# Pylaa - AI System onboarding

## Etat valide

- Codex skills: 13
- Claude commands: 18
- Pairing shared: `ok_same_canonical`
- `missing_codex_skill`: 6 ecarts projet justifies
- `missing_claude_command`: 0
- Tous les compteurs `drift_*`: 0
- AI Doctor: `OK`

## Politique d'installation

Pylaa installe localement les skills Codex `shared.*` declares dans
`projects[].install_shared_skills` dans `skills-registry.yml`.

Les exports sont generes dans `Pylaa/.agents/skills/<skill>/SKILL.md` depuis
les canonicals shared existants. Le registre porte la politique d'installation
par projet; le manifest reste la source des metadonnees canoniques.

Le socle installe est identique a InterviewOS et intrai:

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
- Agent instructions: `AGENTS.md`
- Claude instructions: `CLAUDE.md`
- Project config: `.claude/project-config.md` (absent actuellement)
- Architecture: `docs/ARCHITECTURE.md`

Les paths absents sont toleres par l'inventaire et pourront etre crees plus
tard si le projet en a besoin.

## Isolation des projets

Pylaa ne recoit aucun canonical `aimoto.*`, `interviewos.*` ou `intrai.*`.
Aucun canonical `pylaa.*` n'est cree tant qu'un besoin projet explicite ne le
justifie pas.

Les commandes Claude suivantes sont propres au projet et ne sont pas
converties automatiquement en skills Codex:

- `data-slot-add`
- `design-audit-context`
- `landing-review`
- `next-step`
- `ui-fix-global`
- `ui-review-global`

Leurs `missing_codex_skill` sont des ecarts connus et justifies. Toute
canonicalisation future devra utiliser un canonical `pylaa.*` explicite.

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
rapport avec Pylaa.

## Validation

Depuis `ai-system`:

```bash
./run-inventory.sh
.venv/bin/python scripts/ai_doctor.py --inventory
```

Depuis `Pylaa`:

```bash
find .agents/skills -maxdepth 2 -name "SKILL.md" -print | sort
grep -R "aimoto\|AIMOTO\|InterviewOS\|intrai\|BTC\|backtesting\|forecast\|strategy-loop\|AIMOTO_DATA_DIR" \
  .agents/skills || true
```

Etat attendu:

- 13 shared skills Codex locaux;
- aucun canonical project-specific etranger;
- aucun drift;
- six `missing_codex_skill` justifies pour les commandes Pylaa listees;
- AI Doctor `OK`.
