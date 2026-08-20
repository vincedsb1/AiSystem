# ÉTAPE UX-05 — Import et synchronisation des skills

**Statut :** Terminée
**Dépend de :** UX-04, routes import/sync

## Backend (`scripts/project_actions.py`)

Nouveau module dédié aux deux chemins d'écriture.

### `import --project P --skill S --source codex|claude`

- Écrit le canonical et ajoute **une** entrée manifest.
- Idempotent : un import répété renvoie `already_managed` avec
  `writeState=no_changes`, sans canonical ni entrée dupliqués.
- Un canonical existant au contenu différent est un `canonical_conflict`,
  jamais un écrasement silencieux (§23.2).
- Si l'écriture du manifest échoue après celle du canonical, le canonical est
  retiré et `writeState=rolled_back`.

### `sync --project P [--dry-run]`

- Reconstruit les exports manquants ou dérivés depuis les canonicals, en
  réutilisant `sync_skills.build_export_content` déjà éprouvé.
- Seuls les statuts jugés sûrs par le backend sont réparés. `conflict` et
  `manifest_error` sont rapportés, jamais résolus automatiquement.
- `--dry-run` est une vraie prévisualisation (§12.3) : compte les changements
  et n'écrit rien.

Toutes les écritures sont atomiques (`tempfile` + `os.replace` + `fsync`).
Chaque réponse porte `writeState`.

### Défaut d'isolation trouvé et corrigé

Le premier passage des tests a écrit deux canonicals dans le **vrai** dépôt :
`canonical_target_path` résolvait contre la constante `AI_SYSTEM_ROOT` alors que
la fixture s'appelle aussi « Suggst ».

La racine des sources gérées dérive désormais du chemin de manifest fourni par
l'appelant. Deux tests-gardes échouent si cela régresse. Les fichiers parasites
ont été supprimés.

## Swift

| Fichier | Rôle |
|---|---|
| `Models/ProjectActionModels.swift` | contrat d'action, `ActionWriteState`, état d'opération par skill |
| `Features/Projects/ImportSkillSheet.swift` | confirmation en langage métier, détails repliés |
| `Features/Projects/ProjectsViewModel.swift` | orchestration import/sync, rescan, anti-double-soumission |
| `Features/Projects/ProjectsView.swift` | action par ligne, bouton Synchroniser, feedback inline |
| `Services/ProjectSkillsService.swift` | routes `importSkill` et `syncProject` |

## Règles respectées

- §11.2 — Importer n'est visible que si `importable == true` **et** que le
  backend liste `import` dans `allowedActions`.
- §11.3 — la sheet décrit la conséquence, pas le mécanisme ; les chemins sont
  dans une section repliée.
- §11.4 — double soumission bloquée au view model et au bouton.
- §11.5 — succès : confirmation inline, rescan, compteurs à jour.
- §11.6 — échec : cause lisible + phrase sur l'état d'écriture ; `stderr` n'est
  jamais le message principal.
- §11.7 — idempotence vérifiée côté backend et côté UI.
- §12.2 — la cible n'est pas demandée : le backend la détermine.
- §12.4 — pas de confirmation pour une synchronisation idempotente.
- §12.5 — résumé compact ; les éléments inchangés ne produisent pas de liste.
- §17.1 — aucune alerte modale pour un succès ordinaire.
- §22.3 — seule la ligne concernée montre sa progression.

## Validation

- Tests backend : 56 → **77** (21 nouveaux)
- Tests Swift : 30 → **46** (16 nouveaux)
- `./check-ai-system.sh` — OK
- `scripts/build_swift_app.sh` — OK
- Aucune mutation parasite du dépôt

Réserve inchangée : la cible `AI SystemUITests` échoue à l'initialisation du
runner (environnemental, préexistant).

## Non couvert volontairement

La synchronisation globale de tous les projets (§12.1) n'est pas exposée : elle
n'a de sens qu'accompagnée d'une confirmation multi-projets, et la Vue
d'ensemble ne l'affiche que si elle est « compréhensible et pertinente »
(FR-OV-03). À rouvrir si le besoin se confirme.
