# ÉTAPE UX-04 — Projets en lecture seule

**Statut :** Terminée
**Dépend de :** UX-01, UX-02, UX-03

## Objectif

Créer l'expérience de consultation des projets et des skills avant d'activer
les mutations (UX-05).

## Décisions

### La liste est alimentée par `overview`, pas par `list-projects`

La spec (§UX-04, travaux 1) indique « charger `list-projects` ». Cette route ne
renvoie pas l'état des projets : la liste n'aurait affiché que `unknown` et le
tri par gravité (§10.2) aurait été inopérant.

`overview` fournit la liste **et** l'état de chaque projet, avec exactement les
mêmes valeurs que la Vue d'ensemble — ce qui évite deux vérités divergentes
dans l'application. Coût mesuré : 0,5 s pour 10 projets. La §21.2 autorise
« une composition équivalente fiable ».

`list-projects` reste exposée par le service pour les usages futurs.

### Vues supprimées

`Views/DashboardView.swift` et `Views/ProjectsView.swift` ont été retirées :
leurs fonctions ont désormais une destination effective (`OverviewView` en
UX-03, `Features/Projects/ProjectsView` en UX-04). Une collision de nom de
fichier rendait par ailleurs le build impossible.

Les vues héritées Diffusion, Reports, Documentation, Tools, Logs et Sidebar
sont **conservées** jusqu'à ce qu'UX-05/07/08 relogent leurs fonctions
(règle « reloger avant supprimer »).

## Livré

| Fichier | Rôle |
|---|---|
| `Features/Projects/ProjectsViewModel.swift` | liste, tri, sélection, scan, filtres, recherche |
| `Features/Projects/ProjectsView.swift` | liste + détail, résumé, table des skills |
| `Models/ProjectSkillsModels.swift` | `SkillStatus.symbolName` / `.explanation` |
| `Views/DesignSystem.swift` | teinte sémantique de `SkillStatus` |

### Traduction des statuts (§10.9)

Les onze statuts backend sont traduits en titre + explication française. Le
backend reste autoritaire sur `importable`, `allowedActions` et `severity` :
SwiftUI ne recalcule aucun statut.

### Présence Claude/Codex

Une plateforme que le projet ne cible pas affiche « non concerné » et non
« absent ». C'est la traduction visuelle du correctif backend d'UX-03 :
`sharedTargets` vient du backend.

## Règles respectées

- FR-PROJ-01 — sélection stable au rafraîchissement si le projet existe encore.
- FR-PROJ-02 — dernière sélection restaurée au lancement.
- FR-PROJ-03 — état invitant à sélectionner quand rien n'est sélectionné.
- FR-PROJ-04 — état vide avec appel à ajouter un projet.
- FR-STATE-05 — les exceptions attendues ne comptent pas comme actions.
- §10.2 — tri erreurs, attention, sains, puis alphabétique.
- §10.6 — une valeur indisponible s'affiche « non vérifié », jamais « 0 ».
- §10.8 — ouverture depuis une action requise présélectionne « À examiner ».
- §22.4 — un scan en échec conserve l'état connu et propose Réessayer.

## Validation

- Tests Swift : 15 → **30** (13 nouveaux : tri, sélection, projet disparu,
  filtres, recherche, exceptions, échec de scan, cibles partagées)
- Tests backend : 56 — OK
- `./check-ai-system.sh` — OK
- `scripts/build_swift_app.sh` — OK

Réserve inchangée : la cible `AI SystemUITests` échoue à l'initialisation du
runner (environnemental, préexistant). Les tests unitaires passent avec
`-only-testing:"AI SystemTests"`.

## Hors périmètre (UX-05)

Import et synchronisation. Les actions autorisées sont déjà exposées par le
backend (`allowedActions`) mais aucune mutation n'est déclenchable depuis
l'interface à ce stade.
