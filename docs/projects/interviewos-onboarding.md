# InterviewOS - AI System onboarding

## État actuel

- Claude commands: 18
- Codex skills: 0
- Claude rules: 4
- Claude hooks: 3
- Codex hooks: 0
- Root docs: 2

## Décisions actées

### Commandes AIMOTO-only détectées dans InterviewOS

Ces commandes ne doivent pas être portées vers InterviewOS et ne doivent pas recevoir de skill Codex local InterviewOS :

- `analyse-signal`
- `article-review`
- `bilan`
- `edit-export-llm-report`
- `next`
- `update-strategy`

Décision : les retirer de `InterviewOS/.claude/commands`.

Raison : commandes spécifiques à AIMOTO, non partagées, non adaptées au domaine InterviewOS.

## Problèmes détectés

### Pairing Claude ↔ Codex

Les `missing_codex_skill` actuels viennent des commandes AIMOTO-only exposées par erreur dans InterviewOS :

- `analyse-signal`
- `article-review`
- `bilan`
- `edit-export-llm-report`
- `next`
- `update-strategy`

Ces commandes ne doivent pas être corrigées par création de skills Codex locaux. Elles doivent être retirées du projet InterviewOS.

### AI Doctor

Les dangers actuels viennent de la commande AIMOTO-only suivante :

- `InterviewOS/.claude/commands/update-strategy.md`
  - fallback `_next_minor_ver(...)`
  - `fallback_next_minor_ver`
  - source de version implicite

Décision : ne pas corriger cette commande dans InterviewOS. La retirer du projet, car elle ne doit pas être exposée dans InterviewOS.

Review restante :

- `docs/ARCHITECTURE.md`
  - mention `par défaut` sur la création de champ

Cette review est secondaire. Elle peut être traitée après retrait des commandes AIMOTO-only.

## Actions interdites pour cette phase

- Ne pas créer de skills Codex InterviewOS pour les commandes AIMOTO-only.
- Ne pas canonicaliser les commandes AIMOTO-only sous `skills/projects/interviewos`.
- Ne pas ajouter ces commandes au `skills-manifest.yml` pour InterviewOS.
- Ne pas lancer `sync_skills.py` pour créer des exports InterviewOS à partir de ces commandes.
- Ne pas modifier les canonicals AIMOTO.
- Ne pas modifier les exports AIMOTO.
- Ne pas corriger `update-strategy.md` dans InterviewOS : le fichier doit être retiré du périmètre InterviewOS.

## Plan d'action

1. Retirer les commandes AIMOTO-only de `InterviewOS/.claude/commands` :
   - `analyse-signal.md`
   - `article-review.md`
   - `bilan.md`
   - `edit-export-llm-report.md`
   - `next.md`
   - `update-strategy.md`

2. Relancer l’inventaire :

   `./run-inventory.sh`

3. Relancer le doctor :

   `.venv/bin/python scripts/ai_doctor.py --inventory`

4. Vérifier que les problèmes suivants disparaissent :
   - `missing_codex_skill` pour les commandes AIMOTO-only ;
   - `danger` sur `InterviewOS/.claude/commands/update-strategy.md`.

5. Vérifier que les commandes shared utiles restent exposées dans InterviewOS :
   - `commit`
   - `create-doc`
   - `implement`
   - `optimize-claude-md`
   - `spec-0-feedback`
   - `spec-1-intake`
   - `spec-2-draft`
   - `spec-3-audit`
   - `spec-4-challenge`
   - `spec-5-revise`
   - `test`
   - `ui-review`

6. Traiter ensuite la review secondaire dans `InterviewOS/docs/ARCHITECTURE.md` si elle reste signalée.

## État attendu après retrait

### Inventory

- `InterviewOS` reste scanné.
- `InterviewOS` ne contient plus les commandes AIMOTO-only.
- `missing_codex_skill = 0` pour les commandes AIMOTO-only.
- Aucun drift inter-projets artificiel.

### Doctor

- `danger = 0`
- `review` peut rester à `1` si `docs/ARCHITECTURE.md` contient encore la mention `par défaut`.

## Validation finale

Commandes à lancer depuis `ai-system` :

```bash
cd /Users/vincentdesbrosses/Documents/Misc/ai-system

./run-inventory.sh
.venv/bin/python scripts/ai_doctor.py --inventory