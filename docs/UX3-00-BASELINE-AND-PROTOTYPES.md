# UX3-00 — Baseline et prototypes de décision

## Périmètre

Cette baseline ouvre la phase UX3.0 « Memorable Experience ». La mission est
limitée aux trois transformations prescrites par
`AI_System_Memorable_Experience_Spec.md` :

1. System Pulse — voir le système ;
2. Quick Command — agir instantanément ;
3. Operation Experience — ressentir le déroulement et le résultat.

Aucun backend, contrat JSON, workflow CLI ou framework externe n’est modifié
par UX3-00.

## État réel au démarrage

Le dépôt était sur `main` avec les rapports générés suivants déjà modifiés et
le fichier de spécification UX3 fourni non suivi :

- `reports/ai-doctor.latest.json` ;
- `reports/ai-doctor.latest.md` ;
- `reports/ai-inventory.latest.json` ;
- `reports/ai-inventory.latest.md` ;
- `docs/AI_System_Memorable_Experience_Spec.md`.

La spécification UX2 précédente était également présente hors suivi. Ces
artefacts sont préservés et ne font pas partie de la mission UX3.

## Audit des données disponibles

| Besoin UX3 | Source réelle | Décision |
|---|---|---|
| état global, compteurs projets et skills | `SystemOverviewResponse` | réutiliser directement |
| état séparé Claude/Codex | absent du contrat actuel | afficher l’état global dans les deux nœuds, sans déduction |
| activité de session | `ActivityStore` | conserver la session-only et enrichir avec un reçu |
| durée et code de sortie | `CommandResult` / `TechnicalDetails` | utiliser pour le reçu technique, jamais pour un statut métier |
| opération active | aucun modèle global avant UX3 | introduire `CommandCenter` comme autorité de présentation |
| projets et skills déjà chargés | vues Overview/Projects | publier dans `AppDataStore`, sans rescan à l’ouverture de Quick Command |

Avant UX3, les opérations longues étaient représentées par des indicateurs
locaux dans les ViewModels. `AppCommands` ne proposait que Nouveau projet,
Actualiser et Rechercher ; aucun `⌘K` global n’existait.

## Prototypes visibles

La galerie isolée `UX3PrototypeGallery` est disponible dans les previews
SwiftUI (`Features/UX3PrototypeGallery.swift`). Elle rassemble :

- System Pulse avec quatre nœuds et état healthy fixture ;
- Quick Command avec son overlay, son champ autofocus et son footer clavier ;
- OperationStatusControl en état running.

Les composants possèdent aussi leurs previews individuelles. Cette galerie ne
rejoint pas la navigation de l’application et ne contient aucune logique
métier.

## Variantes retenues

### System Pulse

- quatre nœuds maximum : AI System, projets, Claude, Codex ;
- ligne horizontale à largeur normale, empilement vertical en largeur réduite ;
- état Claude/Codex explicitement présenté comme global faute de contrat
  séparé ;
- nœud Projets interactif ; nœuds provider ouvrant le même contexte utile ;
- connecteurs décoratifs, labels et actions porteurs du sens ;
- aucune animation permanente ; passage terminal unique de 650 ms, supprimé
  avec Reduce Motion.

### Quick Command

- ouverture `⌘K` depuis la fenêtre principale et menu Actions ;
- intents typés, jamais de closure métier opaque ;
- index local des commandes statiques, données déjà chargées et activité ;
- alias français/anglais avec classement exact, préfixe, mot, sous-chaîne,
  alias, récence et contexte ;
- les mutations synchronisation/ajout sont préparées ou confirmées dans le
  contexte existant ; aucun import ne part depuis un simple Return skill.

### Operation Experience

- `CommandCenter` porte l’opération affichée globalement ;
- `ActivityStore` reste l’historique de session ;
- `OperationReceipt` est construit à partir des champs structurés de l’activité
  et de `CommandResult` ;
- succès temporaire, échec persistant jusqu’à consultation ;
- stdout reste une preuve technique secondaire et n’est jamais interprété.

## Première validation

La compilation Debug du target `AI System` passe après l’ajout de ces
fondations. Les validations backend, les tests Swift complets, le build
Release et la recette installée restent réservés à UX3-07.

## Hors périmètre confirmé

- aucune quatrième transformation ;
- aucun changement de backend ou de schéma JSON ;
- aucun nouveau scan filesystem à l’ouverture de Quick Command ;
- aucun framework UI tiers ;
- aucun commit ni push.
