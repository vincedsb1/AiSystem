# AI System Local GUI Design (v1)

**Date:** 2026-06-17  
**Status:** Design proposal (not implemented)  
**Scope:** macOS local interface accessible from Dock

---

## Objectif

Créer une interface locale macOS simple et complète pour piloter `ai-system` sans mémoriser les commandes terminal. Interface accessible depuis une icône dans le Dock, sans dépendances lourdes (Electron, Tauri, SwiftUI).

**Besoin clé :** Ne plus devoir se rappeler les commandes `make check`, `make inventory`, `make doctor`, etc.

---

## Principes de conception

1. **Approche simple :** AppleScript + shell backend, pas de framework lourd.
2. **Actions longues asynchrones :** Exécutées dans Terminal visible (l'utilisateur voit la progression).
3. **Rapports/docs :** Ouverts avec `open` (application par défaut du système).
4. **Pas de logique métier nouvelle :** L'interface orchestre des commandes existantes seulement.
5. **Pas de modification des exports/canonicals :** Aucune logique créée dans l'interface.
6. **Actions avec contexte :** Les actions complexes (installation projet, sync) permettent la saisie du contexte.

---

## Architecture

### Composants

```
AI System Menu (AppleScript/Shell)
├── Système
│   ├── Check complet (Terminal visible)
│   ├── Inventory seul (Terminal visible)
│   └── Doctor seul (Terminal visible)
├── Exports
│   ├── Mettre à jour tous les projets (Claude + Codex) [Terminal]
│   ├── Mettre à jour Codex seulement [Terminal]
│   ├── Mettre à jour Claude seulement [Terminal]
│   ├── Installer/mettre à jour un projet spécifique [Dialogue]
│   └── Actions longues dans Terminal
├── Rapports & Documentation
│   ├── Rapport Inventory (Markdown)
│   ├── Rapport Doctor (Markdown)
│   ├── README.md
│   ├── docs/OPERATIONS.md
│   ├── docs/SKILL-WORKFLOW.md
│   ├── docs/PROJECT-ONBOARDING.md
│   └── Plan-AI-System.md
├── Configuration
│   ├── Installer hook pre-commit local
│   └── Voir l'état Git
├── Raccourcis
│   ├── Ouvrir repo dans Cursor
│   ├── Ouvrir repo dans Terminal
│   └── Ouvrir dossier dans Finder
└── Quitter
```

---

## Catégories et actions

### 1. SYSTÈME — Validation et diagnostic

**Objectif :** Exécuter les validations du système.  
**Comportement :** Actions longues → ouvertes dans Terminal visible.

| Action | Commande | Durée estimée | Notes |
|---|---|---|---|
| **Vérifier tout le système** | `make check` | 10-15s | Validation complète : inventory + doctor + checks. Bloc si échec. |
| **Lancer Inventory seul** | `make inventory` | 3-5s | Générer rapports/ai-inventory.latest.{md,json} |
| **Lancer Doctor seul** | `make doctor` | 2-3s | Audit de risques. Utilise inventory en entrée. |

**Terminal :** Visible, l'utilisateur voit la progression en temps réel.  
**Après exécution :** Menu reste ouvert, l'utilisateur peut voir les rapports ensuite.

---

### 2. EXPORTS — Synchronisation et installation des skills

**Objectif :** Mettre à jour les exports Claude/Codex dans les projets.  
**Comportement :** Actions longues → Terminal visible.

#### 2.1 Mises à jour globales

| Action | Commande | Durée | Notes |
|---|---|---|---|
| **Diffuser tous les projets** | `make update-projects TARGETS=both` | 30-60s | Sync Claude + Codex pour **tous** les projets enabled. |
| **Diffuser Codex seulement** | `make update-projects TARGETS=codex` | 20-40s | Sync Codex uniquement (projets multi-cibles). |
| **Diffuser Claude seulement** | `make update-projects TARGETS=claude` | 20-40s | Sync Claude uniquement (projets multi-cibles). |

**Attention :** `make update-projects` respecte les `install_shared_targets` de chaque projet. Certains projets (LinkedIn) sont Codex-only.

#### 2.2 Installation/mise à jour d'un projet

**Action :** "Installer/mettre à jour un projet spécifique"

**Comportement :** 
1. Afficher une fenêtre de dialogue macOS :
   - Texte : « Entrez le nom du projet »
   - Liste déroulante des 10 projets (complétable) :
     - aimoto
     - InterviewOS
     - intrai
     - linkedin-ia-comments
     - Pylaa
     - Pylot
     - Skriipt
     - Spotter
     - suggst
     - truthify
   - Sélection des targets (checkbox) :
     - ☐ Codex
     - ☐ Claude
     - (precoché : Codex + Claude si les deux sont autorisés)

2. Exécuter dans Terminal :
   ```bash
   make install-project PROJECT=<name> TARGETS=<targets>
   ```

3. Afficher la progression en Terminal visible.

**Contrainte :** Respecter `install_shared_targets` du projet dans le registre. Si l'utilisateur sélectionne une target interdite, avertir et ignorer.

---

### 3. RAPPORTS & DOCUMENTATION — Consultation

**Objectif :** Ouvrir les rapports et docs existantes.  
**Comportement :** Ouverture avec `open -a <app>` (application par défaut macOS).

| Action | Fichier | Notes |
|---|---|---|
| **Rapport Inventory** | `reports/ai-inventory.latest.md` | Vue complète des skills/commands |
| **Rapport Doctor** | `reports/ai-doctor.latest.md` | Audit de risques et findings |
| **README.md** | `README.md` | Introduction et règles fondamentales |
| **OPERATIONS.md** | `docs/OPERATIONS.md` | Commandes et interprétation |
| **SKILL-WORKFLOW.md** | `docs/SKILL-WORKFLOW.md` | Workflow d'évolution des skills |
| **PROJECT-ONBOARDING.md** | `docs/PROJECT-ONBOARDING.md` | Onboarding d'un nouveau projet |
| **Plan-AI-System.md** | `Plan-AI-System.md` | Plan complet et phases |

**Ouverture :** `open <file>` (ouvre avec l'application associée par défaut : TextEdit, VS Code, etc.)

---

### 4. CONFIGURATION — Maintenance locale

**Objectif :** Configurer les éléments locaux du système.

| Action | Commande | Notes |
|---|---|---|
| **Installer hook pre-commit** | `bash scripts/install_git_hooks.sh` | Ajoute un hook `.git/hooks/pre-commit` qui exécute `make check` avant chaque commit. Local, optionnel, non imposé. |
| **Afficher l'état Git** | `git status` | Ouvert dans Terminal pour voir les changements non commitées. |

**Contexte :** Ces actions sont optionnelles et configurent l'environnement local pour améliorer le workflow.

---

### 5. RACCOURCIS — Outils rapides

**Objectif :** Accéder rapidement aux outils externes et répertoires du projet.

| Action | Commande | Notes |
|---|---|---|
| **Ouvrir dans Cursor** | `cursor /Users/vincentdesbrosses/Documents/Misc/ai-system` | Ouvre l'IDE Cursor (si installé) |
| **Ouvrir dans Terminal** | Ouvrir Terminal et `cd /Users/vincentdesbrosses/Documents/Misc/ai-system` | Ouvre Terminal.app dans le dossier racine |
| **Ouvrir dans Finder** | `open /Users/vincentdesbrosses/Documents/Misc/ai-system` | Affiche le dossier racine dans Finder |

**Alternative :** Utiliser `cmd+space` → Spotlight pour accéder plus vite.

---

### 6. QUITTER

Ferme l'interface.

---

## Groupes d'actions et organisation visuelle

```
┌─────────────────────────────────────────────┐
│  🤖 AI System Control                       │
├─────────────────────────────────────────────┤
│                                             │
│  📊 SYSTÈME                                 │
│    ✓ Vérifier tout le système              │
│    ⚙️  Lancer Inventory seul                │
│    ⚙️  Lancer Doctor seul                   │
│                                             │
│  📤 EXPORTS                                 │
│    ↗️  Diffuser tous les projets            │
│    ↗️  Diffuser Codex seulement             │
│    ↗️  Diffuser Claude seulement            │
│    + Installer/mettre à jour un projet     │
│                                             │
│  📖 RAPPORTS & DOCUMENTATION               │
│    📊 Rapport Inventory                     │
│    🔍 Rapport Doctor                        │
│    ────────────────────────                 │
│    📄 README.md                             │
│    📘 OPERATIONS.md                         │
│    📘 SKILL-WORKFLOW.md                     │
│    📘 PROJECT-ONBOARDING.md                 │
│    📘 Plan-AI-System.md                     │
│                                             │
│  ⚙️  CONFIGURATION                          │
│    🔗 Installer hook pre-commit             │
│    🌳 Afficher l'état Git                   │
│                                             │
│  🔗 RACCOURCIS                              │
│    💻 Ouvrir dans Cursor                    │
│    ⌨️  Ouvrir dans Terminal                 │
│    📁 Ouvrir dans Finder                    │
│                                             │
│  ❌ Quitter                                 │
└─────────────────────────────────────────────┘
```

---

## Implémentation cible : AppleScript + osascript

### Stratégie de base

1. **Script principal :** `scripts/mac-gui-launcher.sh`
   - Affiche un menu avec osascript (AppleScript bridge)
   - Parse la sélection utilisateur
   - Exécute la commande appropriée
   - Gère l'ouverture de Terminal si nécessaire

2. **Terminal visible :** Pour les actions longues (`make check`, `make update-projects`, etc.) :
   ```bash
   open -a Terminal scripts/run-long-action.sh
   # ou
   osascript -e 'tell app "Terminal" to do script "cd <path> && make check"'
   ```

3. **Dialogues de contexte :** Pour les actions avec paramètres (projet, targets) :
   ```applescript
   set selectedProject to (choose from list {"aimoto", "InterviewOS", ...} with prompt "Sélectionnez un projet")
   ```

4. **Raccourci Dock :** Créer une « Application Automator » qui exécute `scripts/mac-gui-launcher.sh`.

### Fichiers à créer

- `scripts/mac-gui-launcher.sh` — Menu principal (AppleScript via osascript)
- `scripts/mac-open-report.sh` — Ouvrir fichier avec app par défaut
- `scripts/mac-run-in-terminal.sh` — Exécuter une commande dans Terminal visible
- `scripts/mac-choose-project.sh` — Dialogue pour sélectionner un projet + targets
- Possiblement : `mac-gui.app/` — Application Automator pour l'icône Dock

### Étapes d'installation

1. Créer les scripts shell
2. Tester avec osascript en local
3. Créer une Application Automator pointant vers le lanceur
4. Ajouter l'app au Dock
5. Documenter l'installation dans `docs/OPERATIONS.md`

---

## Commandes backend associées

### Validation et diagnostic

```bash
# Validation complète
make check

# Inventaire seul
make inventory
# → Génère reports/ai-inventory.latest.{md,json}

# Doctor seul
make doctor
# → Génère reports/ai-doctor.latest.{md,json}
```

### Mises à jour d'exports

```bash
# Tous les projets, Claude + Codex
make update-projects TARGETS=both

# Codex seulement
make update-projects TARGETS=codex

# Claude seulement
make update-projects TARGETS=claude

# Un seul projet
make install-project PROJECT=intrai TARGETS=both
make install-project PROJECT=Pylaa TARGETS=claude
```

### Configuration

```bash
# Installer hook pre-commit
bash scripts/install_git_hooks.sh

# Voir l'état Git
git status
```

### Ouvrir documents

```bash
# Ouvrir avec app par défaut
open reports/ai-inventory.latest.md
open docs/OPERATIONS.md
open README.md

# Terminal/Finder/IDE
open -a Terminal /Users/vincentdesbrosses/Documents/Misc/ai-system
open -a Finder /Users/vincentdesbrosses/Documents/Misc/ai-system
cursor /Users/vincentdesbrosses/Documents/Misc/ai-system
```

---

## Choix UX

### Actions longues → Terminal visible

**Raison :** Les utilisateurs veulent voir la progression en temps réel, notamment pour `make check` (10-15s), `make update-projects` (30-60s).

**Implémentation :**
```bash
osascript -e 'tell app "Terminal" to do script "cd /path/to/ai-system && make check"'
```

Le Terminal reste ouvert après exécution pour consultation.

### Rapports/docs → open (app par défaut)

**Raison :** Aucun besoin de contrôle strict. Laisser l'OS gérer (TextEdit, VS Code, etc.)

**Implémentation :**
```bash
open reports/ai-inventory.latest.md
```

### Sélection projet + targets → Dialogue Automator

**Raison :** Certains projets n'autorisent que Codex ou Claude. Dialogue simple + sécurisé.

**Implémentation :**
```applescript
set proj to (choose from list {"aimoto", "InterviewOS", ...})
set codex to (button returned of (display dialog "Codex?" buttons {"Non", "Oui"})) = "Oui"
set claude to (button returned of (display dialog "Claude?" buttons {"Non", "Oui"})) = "Oui"
```

### Pas de GUI propriétaire

**Raison :** Simplicité, maintenabilité, pas de dépendance Python/Electron/Swift.

**Limitation :** Interface moins polished, mais fonctionnelle et rapide à itérer.

---

## Projets et cibles autorisées

Configuration complète dans `skills-registry.yml` :

| Projet | Cibles autorisées | Notes |
|---|---|---|
| aimoto | both (défaut) | Claude + Codex |
| InterviewOS | both (défaut) | Claude + Codex |
| intrai | both | Claude + Codex |
| linkedin-ia-comments | codex uniquement | Codex-only, pas d'export Claude |
| Pylaa | both (défaut) | Claude + Codex |
| Pylot | both (défaut) | Claude + Codex |
| Skriipt | both (défaut) | Claude + Codex |
| Spotter | codex uniquement | Codex-only |
| suggst | both (défaut) | Claude + Codex |
| truthify | both (défaut) | Claude + Codex |

**Important :** Vérifier dans `install_shared_targets` du registre avant de proposer une cible.

---

## Limites de la v1

### Pas implémentés

1. **Pas de GUI graphique native** — Menu text + dialogue simple AppleScript seulement.
2. **Pas de notifications** — L'utilisateur doit consulter le Terminal pour connaître le statut.
3. **Pas d'historique d'actions** — Aucun logging GUI des exécutions.
4. **Pas de gestion d'erreur sophistiquée** — Les erreurs s'affichent dans le Terminal.
5. **Pas de drag-and-drop** — Interface purement menu-driven.
6. **Pas de raccourcis clavier personnalisés** — Accès via Dock seulement (ou `cmd+space`).
7. **Pas de mise à jour continue** — L'utilisateur doit relancer l'app pour recharger le menu.

### Raisons

- **Maintien :** La v1 prioritise la simplicité et la maintenabilité locale.
- **Éviter Electron/Tauri :** Pas de dépendance lourde.
- **Approche itérative :** Une v2 pourrait ajouter une GUI Cocoa/SwiftUI si le besoin est clair.

---

## Prochaines étapes

### v1 (Audit + Conception) — CETTE ÉTAPE ✓

- [x] Lire les fichiers existants
- [x] Identifier les fonctionnalités
- [x] Proposer une organisation d'interface
- [x] Documenter les commandes backend
- [x] Valider `make check`

### v1.5 (Prototypage et test)

- [ ] Créer `scripts/mac-gui-launcher.sh`
- [ ] Tester osascript + Terminal integration
- [ ] Valider les dialogues AppleScript
- [ ] Documenter l'installation dans `docs/OPERATIONS.md`

### v2 (Améliorations optionnelles)

- [ ] GUI native Cocoa ou SwiftUI
- [ ] Notifications système
- [ ] Historique d'actions
- [ ] Raccourcis clavier
- [ ] Gestion d'erreur avancée

---

## Résumé des fonctionnalités détectées

### Système

- 139 codex skills
- 134 commandes Claude
- 8 règles Claude
- 6 strategy profiles
- 6 hooks Claude
- 3 hooks Codex
- 17 docs racine
- **État :** 0 action_required, 0 doctor_danger → **STABLE** ✅

### Projets

10 projets enabled :
- aimoto (22 Codex + 22 Claude)
- InterviewOS (13 Codex + 12 Claude)
- intrai (13 Codex + 13 Claude)
- linkedin-ia-comments (13 Codex, Codex-only)
- Pylaa (13 Codex + 18 Claude)
- Pylot (13 Codex + 18 Claude)
- Skriipt (13 Codex + 15 Claude)
- Spotter (13 Codex, Codex-only)
- suggst (13 Codex + 18 Claude)
- truthify (13 Codex + 18 Claude)

### Scripts disponibles

- `ai_inventory.py` — Génère inventaire
- `ai_doctor.py` — Audit de risques
- `check_ai_system.py` — Validation complète
- `install_project_exports.py` — Installation projet
- `update_project_exports.py` — Mise à jour globale
- `sync_skills.py` — Sync skills
- `install_git_hooks.sh` — Hook pre-commit

### Commandes principales

```
make check                                    # Validation complète
make inventory                                # Inventaire seul
make doctor                                   # Doctor seul
make update-projects TARGETS=both|codex|claude
make install-project PROJECT=<name> TARGETS=both|codex|claude
bash scripts/install_git_hooks.sh
```

---

## Validation

À la fin de cette étape, exécuter :

```bash
make check
```

Résultat attendu :

```
AI Inventory - OK
AI Doctor - OK
AI System Check - OK
```

Aucun changement aux exports ou canonicals, seulement cette documentation.
