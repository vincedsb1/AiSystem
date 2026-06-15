# Spotter - AI System onboarding

## Politique d'installation

Spotter installe localement les skills Codex `shared.*` declares dans
`projects[].install_shared_skills` dans `skills-registry.yml`.

Les exports sont generes dans `Spotter/.agents/skills/<skill>/SKILL.md` depuis
les canonicals shared existants. Le registre porte la politique d'installation
par projet; le manifest reste la source des metadonnees canoniques.

Le socle installe est identique a InterviewOS, intrai, Pylaa, Pylot et Skriipt:

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
- Claude instructions: `CLAUDE.md` (absent actuellement)
- Project config: `.claude/project-config.md` (absent actuellement)
- Architecture: `docs/ARCHITECTURE.md` (absent actuellement)

Les paths absents sont toleres par l'inventaire et pourront etre crees plus
tard si le projet en a besoin. Les documents actuels `README.md` et
`GEMINI.md` ne sont pas assimiles a des instructions Claude ou Codex.

## Commandes Claude propres au projet

Spotter ne contient actuellement aucun repertoire `.claude/commands` et
aucune commande Claude project-specific. Aucune `pairing_exception` n'est
donc declaree.

Si une commande propre a Spotter est ajoutee plus tard, elle devra soit:

- rester Claude-only avec une exception explicite par commande;
- devenir un canonical `spotter.*` apres validation d'un besoin metier clair.

## Isolation des projets

Spotter ne recoit aucun canonical `aimoto.*`, `interviewos.*`, `intrai.*`,
`pylaa.*`, `pylot.*` ou `skriipt.*`. Aucun canonical `spotter.*` n'est cree
pendant cet onboarding.

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
rapport avec Spotter.

## Validation

Depuis `ai-system`:

```bash
./run-inventory.sh
.venv/bin/python scripts/ai_doctor.py --inventory
```

Depuis `Spotter`:

```bash
find .agents/skills -maxdepth 2 -name "SKILL.md" -print | sort
grep -R "aimoto\|AIMOTO\|InterviewOS\|intrai\|Pylaa\|Pylot\|Skriipt\|BTC\|backtesting\|forecast\|strategy-loop\|AIMOTO_DATA_DIR" \
  .agents/skills || true
```

Etat attendu:

- 13 shared skills Codex locaux;
- aucun canonical project-specific etranger;
- aucune exception de pairing tant que Spotter n'a pas de commande locale;
- `missing_codex_skill = 0`;
- aucun drift;
- AI Doctor `OK`.
