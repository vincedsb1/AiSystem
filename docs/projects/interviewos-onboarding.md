# InterviewOS - AI System onboarding

## État actuel

- Claude commands: 12
- Codex skills: 13
- Claude rules: 4
- Claude hooks: 3
- Codex hooks: 0
- Root docs: 2
- Pairing: 13 `ok_same_canonical`, aucun missing ou drift
- AI Doctor: `OK`

## Politique d'installation

InterviewOS installe localement les skills Codex `shared.*` déclarés dans
`projects[].install_shared_skills` dans `skills-registry.yml`.

Les exports sont générés dans
`InterviewOS/.agents/skills/<skill>/SKILL.md` depuis les canonicals shared
existants. Le registre porte la politique d'installation par projet; le
manifest reste la source des métadonnées canoniques.

La politique actuelle installe :

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

InterviewOS ne reçoit aucun canonical `aimoto.*`. Réciproquement, AIMOTO ne
reçoit aucun canonical `interviewos.*`.

Les commandes AIMOTO-only suivantes ont été retirées d'InterviewOS et ne
doivent pas être recréées sous forme de skills locaux :

- `analyse-signal`
- `article-review`
- `bilan`
- `edit-export-llm-report`
- `next`
- `update-strategy`

Les futurs skills project `interviewos.*` seront créés uniquement lorsqu'un
besoin métier clair le justifiera.

## Synchronisation

Depuis `ai-system` :

```bash
.venv/bin/python scripts/sync_skills.py --apply --no-backup
```

Le synchroniseur :

- accepte uniquement des canonicals `shared.*` dans
  `install_shared_skills` ;
- vérifie que le canonical existe, est `scope: shared` et compatible Codex ;
- génère les exports vers le chemin `codex_skills` du projet cible ;
- conserve les skills project strictement liés à leur projet.

## Contrôle d'inventaire

`ai_inventory.py` dérive les exports attendus depuis la même politique. Un
shared skill déclaré mais absent est signalé comme export manquant pour le
projet concerné.

## Validation

```bash
./run-inventory.sh
.venv/bin/python scripts/ai_doctor.py --inventory
```

Résultat validé :

- `InterviewOS codex_skills = 13`
- `missing_codex_skill = 0`
- `missing_claude_command = 0`
- tous les compteurs `drift_* = 0`
- aucun canonical `aimoto.*` exporté dans InterviewOS
- `AI Doctor — OK`
