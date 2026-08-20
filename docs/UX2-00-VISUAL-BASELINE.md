# UX2-00 — Baseline visuelle et mapping du code

**Date :** 20 août 2026  
**État :** Complétée  
**Référence :** `AI_System_UX_UI_Polish_Spec_V2.md`

## 1. Worktree observé avant l’étape

Le dépôt était sur `main`. Les modifications préexistantes suivantes ont été
conservées sans édition :

```text
M reports/ai-doctor.latest.json
M reports/ai-doctor.latest.md
M reports/ai-inventory.latest.json
M reports/ai-inventory.latest.md
?? docs/AI_System_UX_UI_Polish_Spec_V2.md
```

Les captures et ce document sont les seuls artefacts ajoutés par UX2-00. Aucun
fichier de rapport préexistant n’a été écrasé.

## 2. Mapping des écrans et composants

| Surface | Fichiers principaux | État avant UX2 |
|---|---|---|
| Navigation | `apps/AI-System/AI System/ContentView.swift`, `Models/AppSection.swift` | `NavigationSplitView`, trois destinations conservées |
| Vue d’ensemble | `Features/Overview/OverviewView.swift`, `OverviewViewModel.swift`, `Models/SystemOverviewModels.swift` | état global structuré, mais héro absent et actions dupliquées |
| Projets | `Features/Projects/ProjectsView.swift`, `ProjectsViewModel.swift`, `Models/ProjectSkillsModels.swift` | maître-détail fonctionnel, résumé à six métriques, tableau sans en-tête |
| Activité | `Features/Activity/ActivityView.swift`, `Services/ActivityStore.swift`, `Models/ActivityModels.swift` | maître-détail session-only, filtre dans la toolbar, stdout visible après ouverture |
| Fondations | `Views/DesignSystem.swift`, `Views/Components/SemanticStatusView.swift` | espacement/tintes partagés, pas encore de conteneur adaptatif ni de surfaces V2 |
| Toolbar/menu | `App/AppCommands.swift` et toolbars des trois vues | raccourcis existants à préserver ; doublons de rafraîchissement présents |

Les ViewModels restent la source des données interprétées. Les vues ne
scannent ni skills ni logs et aucun parsing de `stdout` n’est requis pour la
passe UX2.

## 3. Validation technique de référence

| Contrôle | Résultat |
|---|---|
| Build SwiftUI Release | OK |
| App installée | `/Users/vincentdesbrosses/Applications/AI System.app` |
| Tests backend | 93 tests, OK |
| `make check` | OK — Inventory action_required=0, Doctor danger=0, manifest missing_exports=0 |
| Taille de recette | 1335 × 968 |
| Taille minimale déclarée | 900 × 620 dans `ContentView` |

Le build Release a utilisé `scripts/build_swift_app.sh` via `make
build-swift-app`. Le fallback AppleScript, le sandbox désactivé et le projet
Xcode existant restent inchangés.

## 4. Baseline visuelle

Les captures ont été produites depuis l’app installée, dans une fenêtre de
1335 × 968, en apparence sombre, après stabilisation de chaque destination :

- [Vue d’ensemble](ux2-baseline/ux2-00-current-overview.png)
- [Projets](ux2-baseline/ux2-00-current-projects.png)
- [Activité](ux2-baseline/ux2-00-current-activity.png)

### Vue d’ensemble

- la conclusion est lisible mais trop proche du bord supérieur ;
- le bouton bleu reste dominant même lorsque l’état est sain ;
- les métriques flottent sans surface commune ;
- les lignes d’activité s’étirent sur toute la largeur et répètent un bouton
  `Voir` ;
- une action de vérification existe dans le contenu, la toolbar et le menu ;
- `DateFormatter` fournit une date lisible mais le format n’est pas centralisé.

### Projets

- la colonne latérale est utile mais laisse le détail sous pression ;
- chaque ligne saine répète une coche verte et « Sain » ;
- le résumé isole « Conflits » sur une ligne supplémentaire ;
- la barre de filtres et la recherche sont très compactes ;
- les skills n’ont pas d’en-tête de colonnes ;
- Claude et Codex répètent des symboles verts de même poids ;
- le bouton `Actualiser` de toolbar duplique `Vérifier` dans le détail.

### Activité

- la recherche est dans la liste mais le filtre est dans la toolbar ;
- deux vérifications identiques se distinguent surtout par l’heure ;
- le détail commence par une bonne conclusion mais expose rapidement les
  détails techniques ;
- les boutons de ressources sont des contrôles gris juxtaposés ;
- la date et la durée observées sont encore affichées en format technique ou
  dépendant du locale ;
- les détails techniques devront rester repliés et être réinitialisés lors
  d’un changement de sélection.

## 5. Décisions pour la suite

1. Conserver les contrats JSON, le modèle session-only et les workflows
   backend.
2. Commencer par les fondations et les formateurs partagés avant les trois
   écrans.
3. Utiliser une surface sémantique par section, avec une hiérarchie plus
   forte et des signaux de statut moins répétitifs.
4. Produire une capture Release à chaque étape visuelle puis refaire la
   recette claire/sombre et taille minimale en UX2-06.

**UX2-00 : validée.**
