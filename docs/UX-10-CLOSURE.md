# ÉTAPE UX-10 — Nettoyage contrôlé et clôture

**Statut :** Terminée

## 1. Éléments supprimés

Chaque suppression a suivi la règle « reloger avant supprimer ».

### Vues

| Supprimée | Étape | Remplacée par |
|---|---|---|
| `DashboardView` | UX-03 | `Features/Overview/OverviewView` |
| `ProjectsView` (ancienne) | UX-04 | `Features/Projects/ProjectsView` |
| `DiffusionView` | UX-08 | Projets — synchronisation (UX-05) |
| `ReportsView` | UX-08 | Activité + Réglages > Ressources |
| `LogsView` | UX-08 | Activité > Détails techniques |
| `DocumentationView` | UX-08 | Réglages > Ressources, menu Aide |
| `ToolsView` | UX-08 | Réglages > Avancé |
| `SidebarView` | UX-08 | `ContentView` |

### Composants

`ResultPanel`, `RunStatusView`, `PrimaryActionButton`, `StatusBadge`.

`ResultPanel` était le panneau de résultat global identifié au §28 comme cause
d'« erreurs hors contexte ».

### Modèles et services

| Supprimé | Motif |
|---|---|
| `CommandCenter` | dernier détenteur du `lastResult` global ; remplacé par `ProjectSkillsService` + `ActivityStore` |
| `BackendAction` | mapping d'actions désormais porté par les routes typées du service |
| `ProjectTarget` | orphelin depuis le retrait de `DiffusionView` |
| `SidebarSection` | remplacé par `AppSection` |

## 2. Conservé volontairement

- `scripts/ai_system_gui.applescript` — fallback AppleScript (C-PLAT-07)
- `scripts/build_ai_system_app.sh` — build AppleScript
- `CommandRunner` — `Process` + argv séparés (C-ARCH-04)
- `ENABLE_APP_SANDBOX = NO` (C-PLAT-03)
- Projet Xcode non recréé, `project.pbxproj` non modifié à la main
  (C-PLAT-04/05/06)

## 3. Architecture finale

```text
AI System/
├── AI_SystemApp.swift          scène principale + Settings
├── App/AppCommands.swift       ⌘N ⌘R ⌘F, menu Aide
├── ContentView.swift           NavigationSplitView, 3 destinations
├── Models/
│   ├── AppSection.swift
│   ├── ActivityModels.swift
│   ├── CommandResult.swift
│   ├── ProjectActionModels.swift
│   ├── ProjectSkillsModels.swift
│   └── SystemOverviewModels.swift
├── Services/
│   ├── AISystemPaths.swift
│   ├── ActivityStore.swift
│   ├── BackendJSONDecoder.swift
│   ├── CommandRunner.swift
│   └── ProjectSkillsService.swift
├── Features/
│   ├── Overview/               OverviewView, OverviewViewModel
│   ├── Projects/               ProjectsView, ProjectsViewModel,
│   │                           ImportSkillSheet, AddProjectSheet
│   ├── Activity/               ActivityView (+ détail)
│   └── Settings/               SettingsView
└── Views/
    ├── DesignSystem.swift      espacements + teintes sémantiques
    └── Components/SemanticStatusView.swift
```

## 4. Contrats JSON

Toutes les réponses portent `schemaVersion: 1` et sont refusées proprement si
la version majeure est inconnue.

### `scripts/project_skills.py` — lecture seule

| Route | Renvoie |
|---|---|
| `list-projects` | projets activés |
| `scan --project <id>` | projet, résumé, skills |
| `overview` | état global, résumé, projets, actions classées |

Champs skill : `status`, `severity`, `allowedActions`, `importable`,
`presence`, `paths`, `exception`, `conflict`.
Champs projet : `sharedTargets`.

### `scripts/project_actions.py` — écriture

| Route | Effet |
|---|---|
| `inspect-folder --path` | lecture seule ; nom suggéré, cibles détectées |
| `add-project --project --path --targets` | déclare un projet |
| `import --project --skill --source` | promeut un skill non géré |
| `sync --project [--dry-run]` | reconstruit les exports |

Toute réponse porte `outcome` et `writeState`
(`no_changes` / `applied` / `partial_changes` / `rolled_back`).

### Erreurs

```json
{"code": "...", "message": "...", "details": {},
 "retryable": false, "writeState": "no_changes",
 "suggestedAction": "review_conflict"}
```

## 5. Recette finale

### Automatisée

| Contrôle | Résultat |
|---|---|
| Tests backend (`unittest discover`) | **93** OK |
| Tests Swift (`AI SystemTests`) | **92** OK |
| `make inventory` | OK |
| `make doctor` | OK |
| `make check` | OK |
| `make build-swift-app` | OK |
| `make update-projects` / `make install-project` | cibles intactes |

### Manuelle — à réaliser sur l'app installée

La cible `AI SystemUITests` échoue à l'initialisation du runner
(« Timed out while enabling automation mode »). C'est **environnemental et
préexistant**, sans lien avec la refonte, mais cela empêche d'automatiser les
onze parcours de la §24.3. Deux options :

1. autoriser Xcode dans Réglages Système → Confidentialité → Automatisation,
   puis relancer `xcodebuild test` sans `-only-testing` ;
2. valider ces parcours en recette manuelle.

Checklist manuelle :

- [ ] lancement, état initial neutre
- [ ] Vérifier maintenant → état sain daté
- [ ] action requise → ouverture du projet concerné
- [ ] navigation accueil → projet → skill
- [ ] import réussi
- [ ] import en conflit
- [ ] synchronisation réussie
- [ ] ajout de projet
- [ ] activité et détails techniques
- [ ] erreur contextualisée
- [ ] `⌘,` Réglages
- [ ] outils et documentation
- [ ] `⌘N`, `⌘R`, `⌘F`
- [ ] mode clair / sombre
- [ ] contraste accru
- [ ] taille minimale 900 × 620
- [ ] relance : sidebar et projet restaurés

## 6. Définition de Done — technique

- [x] Logique métier exclusivement backend
- [x] Contrats JSON versionnés
- [x] Aucun parsing YAML dans Swift
- [x] Aucun parsing stdout pour les statuts
- [x] Arguments `Process` séparés
- [x] Opérations mutantes sérialisées
- [x] Tests backend et Swift verts
- [x] AppleScript fallback conservé
- [x] Sandbox désactivé conservé
- [x] Projet Xcode non recréé

## 7. Écarts assumés

| Écart | Motif |
|---|---|
| Liste des projets via `overview` et non `list-projects` | `list-projects` ne porte pas l'état ; §21.2 autorise une composition équivalente |
| Activité session-only | choix explicite documenté en UX-07 (§14.2) |
| Synchronisation globale non exposée | FR-OV-03 : visible seulement si pertinente |
| Case « installation immédiate » absente de la sheet | le backend expose `defaultInstallNow=false` ; la synchronisation couvre le besoin |
| Chemins en dur affichés, non migrés | §16.2 exclut cette migration |
| Tests UI non exécutables | runner d'automatisation indisponible sur la machine |
