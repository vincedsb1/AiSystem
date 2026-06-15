# intrai - AI System onboarding

## Etat actuel

- Codex skills: 13
- Claude commands: 0
- Pairing: 13 `ok_same_canonical`
- `missing_codex_skill`: 0
- Tous les compteurs `drift_*`: 0
- AI Doctor: `OK`

## Politique d'installation

intrai installe localement les skills Codex `shared.*` declares dans
`projects[].install_shared_skills` dans `skills-registry.yml`.

Les exports sont generes dans `intrai/.agents/skills/<skill>/SKILL.md` depuis
les canonicals shared existants. Le registre porte la politique d'installation
par projet; le manifest reste la source des metadonnees canoniques.

Le socle installe est identique a InterviewOS:

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

## Isolation des projets

intrai ne recoit aucun canonical `aimoto.*` ou `interviewos.*`. Aucun
canonical `intrai.*` n'est cree tant qu'un besoin projet explicite ne le
justifie pas.

Les commandes projet non partagees doivent etre signalees pour revue au lieu
d'etre converties automatiquement en Codex skills.

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
rapport avec intrai.

## Validation

Depuis `ai-system`:

```bash
./run-inventory.sh
.venv/bin/python scripts/ai_doctor.py --inventory
```

Depuis `intrai`:

```bash
grep -R "aimoto\|AIMOTO\|InterviewOS\|BTC\|backtesting\|forecast\|strategy-loop\|AIMOTO_DATA_DIR" \
  .agents/skills || true
```

Les avertissements `fallback_candidate` du dashboard proviennent du contenu
shared. Ils sont acceptables uniquement tant que AI Doctor ne remonte aucun
finding `danger` ou `review`.
