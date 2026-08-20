# ÉTAPE UX-03 — Vue d'ensemble métier

**Statut :** Terminée
**Dépend de :** UX-01, UX-02

## Objectif

Remplacer le tableau de bord technique par un état global compréhensible sans lire un log.

## Écart documenté puis corrigé (spec §1.2)

`project_skills.py` attendait un export Claude pour **chaque** skill partagé de
**chaque** projet. Or `ai_inventory.project_shared_targets()` fait autorité et
retourne `{"codex"}` par défaut quand `install_shared_targets` est absent.

Conséquence : la Vue d'ensemble aurait annoncé « 34 éléments demandent votre
attention » alors que `check-ai-system.sh` rapporte `action_required=0`.

Correction : un skill partagé n'est attendu que sur les cibles réellement
installées par le projet. Les deux sources convergent désormais
(`actionRequired=0`, `expectedExceptions=30`).

## Backend

| Route | État |
|---|---|
| `project_skills.py overview --json` | ajoutée |
| `ai_system_action.sh project-overview` | ajoutée (argv séparés, pas de `eval`) |

Contrat `overview` : `schemaVersion`, `status`, `generatedAt`, `state`,
`summary`, `projects[]`, `actions[]`, `error`.

Un projet non scannable est reporté comme entrée en erreur au lieu de casser
tout l'agrégat.

Champs ajoutés au contrat skill : `severity`, `allowedActions` (§10.9, §21.5).
Champ ajouté au contrat projet : `sharedTargets`.

## Swift

| Fichier | Rôle |
|---|---|
| `Models/SystemOverviewModels.swift` | réaligné sur le contrat réel |
| `Services/ProjectSkillsService.swift` | routes typées + `BackendExecuting` injectable |
| `Services/BackendJSONDecoder.swift` | `VersionedBackendPayload` : refus propre d'une version majeure inconnue |
| `Features/Overview/OverviewViewModel.swift` | états unknown/checking/healthy/attention/error |
| `Features/Overview/OverviewView.swift` | synthèse, actions requises, projets, toolbar |
| `Views/DesignSystem.swift` | échelle d'espacement + teintes sémantiques |

## Règles respectées

- FR-OV-01 — l'action principale lance `check`, puis rafraîchit l'instantané.
- FR-OV-05 — aucun `stdout`/`stderr` rendu dans la Vue d'ensemble.
- FR-STATE-02 — l'erreur structurée du backend prime sur l'`exitCode`.
- FR-STATE-03 — chaque couleur est doublée d'un texte et d'un symbole.
- FR-STATE-04 — `unknown` reste neutre.
- FR-STATE-06 — l'état sain n'est affiché qu'après une observation datée.
- FR-NAV-02 — ouvrir une action sélectionne Projets et le projet concerné.
- §22.4 — un refresh en échec conserve le contenu et affiche une erreur inline.
- §21.8 — aucun statut métier dérivé de stdout.

## Validation

- Tests backend : 19 → 56 (`unittest discover`) — OK
- Tests Swift : 15 (décodage, service, view model) — OK
- `./check-ai-system.sh` — OK
- `scripts/build_swift_app.sh` — OK, app installée

Réserve connue : la cible `AI SystemUITests` échoue à l'initialisation du
runner (« Timed out while enabling automation mode »). Environnemental et
préexistant, sans lien avec cette étape. Les tests unitaires
(`-only-testing:"AI SystemTests"`) passent.

## Reporté

L'activité récente affiche un renvoi vers la vue Activité : aucun `ActivityStore`
n'existe avant UX-07, et la spec interdit de fabriquer une valeur absente.
