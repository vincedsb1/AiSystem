# Plan SwiftUI pour l'interface locale macOS

**Statut :** Plan de remplacement progressif (aucune implémentation dans cette étape)  
**Date :** 2026-06-17  
**Scope :** App SwiftUI native macOS locale remplaçant `scripts/ai_system_gui.applescript`

---

## Objectif

Remplacer progressivement l'interface AppleScript par une application SwiftUI native, locale et sans dépendances lourdes (Electron, Tauri), qui pilote le backend `ai-system` existant sans dupliquer sa logique métier. L'app doit offrir une UX bien meilleure : fenêtre native, logs intégrés, feedback en temps réel, icône correcte.

---

## Principes et Contraintes

1. **Backend = source de vérité unique** — `scripts/ai_system_action.sh` reste le point d'entrée exclusif. SwiftUI est purement une couche de présentation/orchestration.
2. **Zéro duplication logique** — SwiftUI n'implémente pas `make`, Python, YAML parsing, etc. ; il appelle le script backend.
3. **Pas d'Electron/Tauri/framework lourd** — SwiftUI natif uniquement.
4. **100% locale** — signature ad-hoc, pas de notarisation, pas d'App Store.
5. **Terminal jamais ouvert automatiquement** — seulement via action explicite "Ouvrir dans Terminal" ou fallback.
6. **`make check` doit rester vert** — à chaque phase du développement.

---

## Architecture SwiftUI

### Choix technologiques

- **State management :** `@Observable` (macro Swift 6.3+, plus simple que `ObservableObject`), pas de Combine.
- **Concurrency :** `async/await`, `Task`, `actor` pour la sérialisation — aucun callback.
- **Navigation :** `NavigationSplitView` (pattern standard macOS 13+), sidebar + détail.
- **Execution sérialisée :** `CommandCenter` singleton contrôle qu'un seul run soit actif (car le fichier log est partagé).

### Vue d'ensemble

```
AISystemApp (@main)
└─ ContentView (NavigationSplitView)
   ├─ SidebarView (List des sections, sélection binding)
   └─ Détail (switch sur la section sélectionnée)
      ├─ DashboardView              — carte de statut, bouton "Vérifier maintenant"
      ├─ DiffusionView              — Tout / Codex / Claude
      ├─ ProjectsView               — mettre à jour existant, ajouter nouveau
      ├─ ReportsView                — Inventory / Doctor, "Ouvrir" buttons
      ├─ DocumentationView          — 6 docs, "Ouvrir" buttons
      ├─ LogsToolsView              — lecteur de log, install-hooks, git-status,
      │                                raccourcis, rebuild app
      └─ StatusBar globale (bottom)  — idle/running/success/failure
```

### View Models

- **`CommandCenter`** (`@Observable`, singleton injecté via `@Environment`/`@State` au level `App`) : propriétaire du `CommandRunner` unique, `currentRun: RunState?` (idle/running/finished), `lastResult: CommandResult?`. Exécute les actions avec sérialisation — aucun run parallèle.
- **`ProjectsViewModel`** (`@Observable`) : formulaire d'ajout de projet (name, path, target enum, install-now toggle), picker d'installation existante.
- **Vues stateless** : lisent `CommandCenter.lastResult`/`currentRun` directement, appelent `CommandCenter.execute(...)`.

---

## Structure de Fichiers Proposée

```
ai-system/
├── apps/
│   └── AI-System/
│       ├── AI System.xcodeproj/             # checked-in, existant (ne pas recréer)
│       ├── AI System/                       # dossier source synchronisé Xcode
│       │   ├── AI_SystemApp.swift           # @main, existant
│       │   ├── ContentView.swift            # existant, remplacé en Phase A
│       │   ├── Models/
│       │   │   ├── BackendAction.swift      # enum + métadonnées
│       │   │   └── CommandResult.swift      # struct: stdout, stderr, exitCode, duration
│       │   ├── Services/
│       │   │   ├── CommandRunner.swift      # Process wrapper (actor)
│       │   │   ├── CommandCenter.swift      # orchestrateur @Observable
│       │   │   └── AISystemPaths.swift      # résout repo root, script, log paths
│       │   ├── Views/
│       │   │   ├── SidebarView.swift
│       │   │   ├── DashboardView.swift
│       │   │   ├── DiffusionView.swift
│       │   │   ├── ProjectsView.swift
│       │   │   ├── ReportsView.swift
│       │   │   ├── DocumentationView.swift
│       │   │   ├── LogsToolsView.swift
│       │   │   └── Components/
│       │   │       ├── StatusBadge.swift
│       │   │       ├── RunOutputView.swift
│       │   │       └── ActionButton.swift
│       │   └── Assets.xcassets              # AppIcon, couleurs, etc. (existant)
│       ├── AI SystemTests/                  # tests optionnels (existant)
│       └── AI SystemUITests/                # existant
├── scripts/
│   ├── ai_system_action.sh                  # MODIFIÉ : mode swift
│   ├── build_ai_system_app.sh               # CONSERVÉ (non référencé après bascule)
│   └── build_swift_app.sh                   # NOUVEAU : xcodebuild wrapper
└── docs/
    └── SWIFTUI-GUI-PLAN.md                  # ce document
```

**Note importante :** le groupe source `AI System/` utilise la fonctionnalité
Xcode 16+ `fileSystemSynchronizedGroups` — tout fichier `.swift` ajouté
physiquement dans ce dossier (et ses sous-dossiers) est automatiquement inclus
dans la compilation. Aucune édition manuelle de `project.pbxproj` n'est requise
pour ajouter de nouveaux fichiers Swift.

---

## Modèle de Données des Actions

```swift
enum BackendAction: String, CaseIterable, Identifiable {
    // System
    case check, inventory, doctor
    
    // Exports
    case update, updateCodex, updateClaude
    
    // Projects
    case installProject, addProject
    
    // Reports & Docs
    case openInventory, openDoctor, openLog
    case openReadme, openOperations, openSkillWorkflow
    case openProjectOnboarding, openPlan, openLocalGuiDesign
    
    // Config & Shortcuts
    case installHooks, gitStatus
    case openCursor, openTerminal, openFinder
    case buildGuiApp
    
    // Propriétés
    var id: String { rawValue }
    var cliArgument: String { /* "check", "update-codex", etc. */ }
    var displayName: String { /* "Vérifier que tout est OK", etc. */ }
    var symbolName: String { /* SF Symbol: "checkmark.circle", etc. */ }
    var kind: ActionKind { /* .validation, .sync, .report, .doc, .config, .shortcut */ }
    var requiresInput: InputRequirement { /* .none, .projectAndTarget, .addProjectForm */ }
    var durationClass: DurationClass { /* .instant, .fast, .long */ }
    var section: SidebarSection { /* Dashboard, Diffusion, Projects, etc. */ }
}
```

**Raison :** Un seul point de mapping Swift ↔ chaîne CLI, unique source de vérité pour éviter la dérive.

---

## `CommandRunner` — Design Détaillé

### API

```swift
struct CommandResult: Sendable {
    let stdout: String
    let stderr: String      // séparé de stdout
    let exitCode: Int32
    let duration: TimeInterval
    let timedOut: Bool
}

enum CommandRunnerError: Error {
    case scriptNotFound
    case launchFailed(underlying: Error)
    case cancelled
}

actor CommandRunner {
    private var currentTask: Process?
    
    func run(
        action: String,
        args: [String] = [],
        uiMode: String = "swift",
        timeout: TimeInterval? = nil
    ) async throws -> CommandResult
    
    func cancelCurrent()
}
```

### Exécution du process

- **Exécutable :** `/usr/bin/env bash <scriptPath> <action> <args...>`
- **Arguments :** tableau `Process.arguments` (jamais concatenation shell-string) — plus sûr que l'AppleScript actuel.
- **Répertoire courant :** `AISystemPaths.root` (repo root).
- **Environnement :** `ProcessInfo.processInfo.environment` + `["AI_SYSTEM_UI_MODE": uiMode]`.

### Gestion des pipes

- Deux `Pipe()` séparés : `standardOutput` et `standardError` (contrairement au mode `app` bash actuel qui les fusionne).
- Lecture via `FileHandle.readabilityHandler` (async-friendly, évite les deadlocks de pipe).
- Accumulateurs de `Data` protégés par l'isolation `actor`.
- `terminationHandler` : arrête les readability handlers, décode UTF-8 (lossy fallback), résout la continuation.

### async/await

```swift
func run(...) async throws -> CommandResult {
    try await withCheckedThrowingContinuation { continuation in
        let process = Process()
        // ... configuration ...
        process.terminationHandler = { _ in
            continuation.resume(returning: CommandResult(...))
        }
        do {
            try process.run()
            self.currentTask = process
        } catch {
            continuation.resume(throwing: CommandRunnerError.launchFailed(...))
        }
    }
}
```

L'`actor` isole l'accès `currentTask` ; la continuation elle-même est thread-safe et peut être reprise de tout thread.

### Annulation

- `cancelCurrent()` → `currentTask?.terminate()` (SIGTERM), puis escalade à `interrupt()` après 2s.
- Wire à SwiftUI `Task` cancellation via `withTaskCancellationHandler`.
- `terminationHandler` systématique → pas de zombie processes.

### MVP : pas de streaming live

Attendre la fin et afficher le résultat final. Pas de tee'd partial output dans la phase 2. Branchable plus tard (phase 4) en changeant la stratégie d'accumulation sans changement de contrat.

---

## UX Cible

### Sidebar (6 sections)

1. **Dashboard**
   - Carte de statut : dernier `check` (OK/fail), timestamp, exit code.
   - Bouton "Vérifier maintenant".
   - Mini cartes : compteurs Inventory (action_required), Doctor (danger) si facilement disponibles.

2. **Diffusion** (exports)
   - Boutons : Tout diffuser / Codex seulement / Claude seulement.
   - Affiche le résultat inline sous chaque action.

3. **Projets**
   - Subsection 1 : Mettre à jour existant — picker (projet, cible segmented control) + bouton Installer.
   - Subsection 2 : Ajouter nouveau — name field, native folder picker (`NSOpenPanel`), target picker, "Installer maintenant" toggle, bouton Ajouter.

4. **Rapports**
   - Boutons : Ouvrir Inventory / Ouvrir Doctor.
   - Optionnel : preview inline en lisant le markdown.

5. **Documentation**
   - Liste des 6 docs, chacun un bouton "Ouvrir".
   - Optionnel : render markdown inline.

6. **Logs & Outils**
   - Lecteur du dernier log (lit `logs/ai-system-last-action.log` directement).
   - "Ouvrir le log" (Finder/app par défaut).
   - Actions : Lancer Inventory, Lancer Doctor, Installer hook, État Git.
   - Raccourcis : Cursor, Terminal, Finder.
   - "Recréer l'app" (rebuild).
   - **Bouton global "Open in Terminal"** : ré-exécute la dernière action avec `AI_SYSTEM_UI_MODE=terminal`.

### Barre de statut globale (bottom)

- Affiche : idle / running (spinner + nom action) / success (✓) / failure (✗ + "View Log").
- Liée à `CommandCenter.currentRun` / `lastResult`.

---

## Tableau de Mapping UI → Backend → Feedback

| Section | UI Action | Backend Invocation | Feedback |
|---|---|---|---|
| Dashboard | "Vérifier maintenant" | `check` | Spinner ~10-15s → succès "OK" ou failure + stdout/stderr |
| Diffusion | "Tout diffuser" | `update` | Spinner ~30-90s → résultat complet |
| Diffusion | "Codex seulement" | `update-codex` | Spinner → résultat |
| Diffusion | "Claude seulement" | `update-claude` | Spinner → résultat |
| Projets | Installer existant | `install-project <project> <targets>` | Validation côté client (targets) → Spinner → résultat |
| Projets | Ajouter nouveau | `add-project <project> <path> <targets> <installNow>` | Validation chemin (FileManager) → Spinner → résultat |
| Rapports | "Ouvrir Inventory" | `open-inventory` | Toast instantané, ouvre app externe |
| Rapports | "Ouvrir Doctor" | `open-doctor` | Toast instantané |
| Docs | chaque doc | `open-readme` / `open-operations` / etc. | Toast instantané |
| Logs & Outils | "Lancer Inventory" | `inventory` | Spinner ~3-5s → résultat |
| Logs & Outils | "Lancer Doctor" | `doctor` | Spinner ~2-3s → résultat |
| Logs & Outils | "Installer hook" | `install-hooks` | Spinner → résultat |
| Logs & Outils | "État Git" | `git-status` | Spinner → output panel (porcelain) |
| Logs & Outils | "Ouvrir log" | Lecture directe Swift + optionnel `open-log` | Toast, ouvre app externe |
| Logs & Outils | Cursor/Terminal/Finder | `open-cursor` / `open-terminal` / `open-finder` | Toast instantané |
| Logs & Outils | "Recréer l'app" | `build-gui-app` | Spinner (quelques sec) → résultat |
| Anywhere | "Open in Terminal" | Re-invoke last action avec `AI_SYSTEM_UI_MODE=terminal` | Terminal.app visible ; Swift garde aussi le résultat précédent in-window |

---

## Modifications Backend Nécessaires

### 7.1 Nouveau `AI_SYSTEM_UI_MODE=swift`

- Comme `app` : pas de Terminal, log écrit dans `logs/ai-system-last-action.log`.
- **Différence clé :** stdout/stderr doivent aussi alimenter les flux réels du process (via `tee`/process substitution) pour que les pipes Swift du parent reçoivent des flux séparés et non vides :

```bash
{ cd "$AI_SYSTEM_ROOT" && eval "$command"; } \
  > >(tee -a "$LAST_LOG_OUT") \
  2> >(tee -a "$LAST_LOG_ERR" >&2)
```

- Conserve le header syntétique (`=== AI System Action Log ===`, Timestamp, Mode) dans le fichier log pour débogage humain.

### 7.2 Exit codes fiables pour tous les `open-*`

- Vérifier l'existence du fichier avant d'appeler `open` ; exit 1 si absent.
- Vérifier que l'outil externe existe (`command -v cursor`, etc.) ; exit 1 sinon.
- Les actions `.instant` n'échappent plus à la log/exit code pipeline par oubli.

### 7.3 Backward compatibility

- Modes `terminal` et `app` inchangés.
- Mode `swift` est additive.
- AppleScript GUI (si maintenu en parallèle pendant la transition) continue d'utiliser `app` mode exactement comme aujourd'hui.

---

## Risques Identifiés

| Risque | Mitigation |
|---|---|
| Gatekeeper (app non signée) | Acceptable, documenter clic-droit → Ouvrir |
| Injection shell (path avec espaces/quotes/`$()`) | `Process.arguments` tableau (jamais shell-string) — strictement plus sûr qu'AppleScript actuel |
| Bugs concurrence UI | `CommandRunner` actor isole état ; `@MainActor` pour mutations depuis appels de vue |
| Processus zombie | `terminationHandler` systématique + `cancelCurrent()` + TaskCancellation wiring |
| Log corrompu (runs concurrents) | Sérialisation `CommandCenter` — aucun run parallèle |
| Drift enum Swift ↔ bash script | Tableau de mapping documenté ; test optionnel futur : comparer `BackendAction.allCases` vs `ai_system_action.sh --help` |
| Liste projets codée en dur | MVP accepté ; phase 3 envisage action `list-projects` lisant `skills-registry.yml` via bash |
| Stdout/stderr fusionnés actuellement | Mitigé par mode `swift` de la phase 1 |

---

## Plan par Phases

### Phase 1 — Préparation backend (bash seul, zéro Swift)

- Ajouter `AI_SYSTEM_UI_MODE=swift` avec tee-based separated-stream output.
- Durcir `open_file` / `open_*` pour exit codes fiables.
- **Validation :** `make check` vert ; test manuel `AI_SYSTEM_UI_MODE=swift scripts/ai_system_action.sh check` confirme que stdout/stderr sont séparés.

### Phase 2 — MVP SwiftUI (Dashboard + check uniquement)

- Créer Xcode project, `CommandRunner` (implementation complète), `CommandCenter`, `ContentView` minimaliste avec Dashboard et "Vérifier maintenant" button.
- Valide la plomberie Process/pipes/async avant d'investir dans le reste.
- **Validation :** `make check` inchangé ; lancer l'app, cliquer "Vérifier", confirmer success/failure match du `make check` terminal.

### Phase 3 — Couverture complète

- Toutes les sections sidebar (Diffusion, Projects, Reports, Documentation, Logs & Tools).
- Chaque case `BackendAction` filée.
- Optionnel : action `list-projects` backend pour éviter hardcoding dans Swift.

### Phase 4 — Polish UX

- AppIcon `Assets.xcassets` (icône réelle).
- SF Symbols (remplace glyphes Unicode).
- Dark mode (SwiftUI gratuit).
- Persistance `@AppStorage` (last section, etc.).
- Optionnel : live-streaming output (section 4).

### Phase 5 — Build local & retraite AppleScript

- `scripts/build_swift_app.sh` (xcodebuild wrapper).
- Repoint `action_build_gui_app` dans le script.
- Mets à jour `README.md` / `docs/OPERATIONS.md` / `docs/LOCAL-GUI-DESIGN.md`.
- Optionnel : déplace AppleScript en `archive/` (ou efface si confiant).

**À chaque phase :** `make check` vert, aucune modification exports/canonicals.

---

## Commandes de Validation

```bash
# Phase 1 : test du mode swift
AI_SYSTEM_UI_MODE=swift scripts/ai_system_action.sh check
echo "exit code: $?"
cat logs/ai-system-last-action.log

# Phase 2+ : build et test de l'app Swift
xcodebuild -project "apps/AI-System/AI System.xcodeproj" -scheme "AI System" -configuration Release build
open ~/Applications/"AI System.app"

# Partout : validation système
make check
# Résultat attendu : AI Inventory — OK, AI Doctor — OK, AI System Check — OK

# Automatisation : build script
bash scripts/build_swift_app.sh
```

---

## Fichiers Concernés

### À créer

- `docs/SWIFTUI-GUI-PLAN.md` (ce document)
- `apps/AI-System/AI System.xcodeproj/` (existant, phase 2+ utilise le squelette en place)
- `apps/AI-System/AI System/` — vues/services/modèles (phase 2+)
- `scripts/build_swift_app.sh` (phase 5)

### À modifier

- `scripts/ai_system_action.sh` — ajouter mode `swift`, durcir `open_*` (phase 1)
- `Makefile` — possiblement ajouter cible de convenience pour build (phase 5)

### À conserver

- `scripts/ai_system_gui.applescript` — non référencé après phase 5, archivé optionnellement
- `scripts/build_ai_system_app.sh` — non référencé après phase 5
- Tous les autres (`docs/`, canonicals, exports) inchangés

---

## Notes

1. **Roadmap progressive :** chaque phase ajoute de la fonctionnalité sans casser `make check` ni dépendre de la phase suivante — rollback possible à tout moment.
2. **Séparation de responsabilité :** bash/Python restent les gardiens de la logique métier ; Swift est orchestre et présentation.
3. **Coût d'entrée :** après phase 1 (backend), phase 2 MVP est petit (CommandRunner + un seul bouton), permet d'itérer rapidement.
4. **Transition douce :** l'AppleScript GUI et l'app Swift peuvent coexister pendant des semaines, l'un remplaçant l'autre progressivement.

---

## Phase 5 — Installation locale et documentation (Phase D)

**Statut :** Implémentée.

- Créer script `scripts/build_swift_app.sh` pour builder Xcode et installer dans `~/Applications`.
- Ajouter cible Makefile `build-swift-app` (distinct de `build-gui-app` AppleScript).
- Ajouter action backend `build-swift-app` dans `ai_system_action.sh`.
- Mettre à jour `docs/OPERATIONS.md` pour documenter la nouvelle app SwiftUI.
- Conserver `build-gui-app` et l'AppleScript comme fallback.

Commande d'installation finale :

```bash
make build-swift-app
open ~/Applications/"AI System.app"
```

---

## Conclusion

Ce plan a guidé une migration progressive de l'interface AppleScript vers une app SwiftUI native qui reste simple (pas de gros framework), locale (pas de dépendances), et focalisée sur orchestration du backend existant. Les cinq phases ont permis une livraison progressive, des validations fréquentes à chaque étape, et une transition en douceur sans rupture :

- **Phase 1** : Préparation backend (mode `swift`, stdout/stderr séparés, exit codes fiables).
- **Phase 2** : MVP SwiftUI (dashboard minimal, check + diffuse).
- **Phase 3** : Couverture complète (6 sections sidebar, toutes les actions).
- **Phase C** : Gestion des projets (formulaires, NSOpenPanel, commandes dynamiques).
- **Phase D** : Installation locale propre (`~/Applications`, build Release, script dédié).

L'AppleScript reste conservé comme fallback. La SwiftUI app est maintenant l'interface principale recommandée.
