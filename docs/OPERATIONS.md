# AI System Operations

## Commandes

### Validation et diagnostic

```bash
make check                                      # Validation complète (inventaire + doctor + checks)
make inventory                                  # Inventaire des skills
make doctor                                     # Audit des risques et incohérences
```

### Gestion des exports

```bash
make update-projects TARGETS=both               # Mettre à jour tous les projets (Claude + Codex)
make update-projects TARGETS=codex              # Mettre à jour Codex uniquement
make update-projects TARGETS=claude             # Mettre à jour Claude uniquement
make install-project PROJECT=intrai TARGETS=both  # Mettre à jour un seul projet
```

`make check` exécute la validation globale. `make inventory` et `make doctor`
restent disponibles pour isoler un diagnostic.

`make update-projects` installe les exports partagés de **tous les projets enabled**
en une seule commande. Respecte les targets autorisées de chaque projet
(`install_shared_targets` dans `skills-registry.yml`).

`make install-project` installe les exports partagés d'**un seul projet**.

## Hook Git local

Installer un hook pre-commit local pour lancer `make check` avant chaque
commit :

```bash
scripts/install_git_hooks.sh
```

Le hook est local au clone courant, optionnel, et bloque le commit si la
validation échoue.

## Interprétation

- `action_required` : findings à corriger. Tant que ce compteur est > 0,
  l'inventaire n'est pas considéré comme propre.
- `accepted_findings` : findings transparents mais non bloquants. Ils restent
  visibles dans le rapport pour auditabilité.
- `expected_exceptions` : écarts encodés dans `pairing_exceptions`. Ils sont
  attendus et ne dégradent pas le statut.
- `missing_*` : artefacts attendus mais absents. Toute valeur > 0 est bloquante.
- `drift_*` : métadonnées incohérentes entre Claude et Codex. Toute valeur > 0
  est bloquante.

## Si `make check` échoue

1. Lire `reports/ai-inventory.latest.md`.
2. Corriger les éléments dans `action_required` en priorité.
3. Si l'échec vient d'un `missing_*`, d'un `drift_*`, d'un export manquant ou
   d'un danger Doctor, corriger la source canonique ou l'export généré.
4. Ne pas modifier les exports à la main.

## Règles d'évolution

- Créer une `pairing_exception` seulement pour une commande Claude-only
  explicitement voulue et justifiée par projet.
- Créer un canonical project-specific seulement quand le besoin métier est clair
  et qu'il ne doit pas rester Claude-only.
- Ne pas éditer les exports projet à la main. Ils doivent rester générés depuis
  les canonicals et le registre.

## Interface locale macOS — Backend d'actions

L'accès via une future interface graphique macOS utilise le point d'entrée unique :

```bash
scripts/ai_system_action.sh <action>
```

Cet entrypoint orchestre l'exécution des commandes Make existantes et gère :
- Les **actions longues** (validation, sync) : ouvertes dans Terminal visible
- Les **rapports/docs** : ouvertes avec `open` (app par défaut macOS)
- Les **actions de config** : bash scripts existants
- Les **raccourcis locaux** : Cursor, Terminal, Finder

### Actions supportées

#### Système — Validation et diagnostic

```bash
scripts/ai_system_action.sh check              # make check
scripts/ai_system_action.sh inventory          # make inventory
scripts/ai_system_action.sh doctor             # make doctor
```

#### Exports — Synchronisation et installation

```bash
scripts/ai_system_action.sh update             # make update-projects TARGETS=both + make check
scripts/ai_system_action.sh update-codex       # make update-projects TARGETS=codex + make check
scripts/ai_system_action.sh update-claude      # make update-projects TARGETS=claude + make check
scripts/ai_system_action.sh install-project intrai both    # make install-project + make check
scripts/ai_system_action.sh install-project Pylaa claude   # make install-project + make check
```

#### Rapports

```bash
scripts/ai_system_action.sh open-inventory     # open reports/ai-inventory.latest.md
scripts/ai_system_action.sh open-doctor        # open reports/ai-doctor.latest.md
```

#### Documentation

```bash
scripts/ai_system_action.sh open-readme                    # open README.md
scripts/ai_system_action.sh open-operations                # open docs/OPERATIONS.md
scripts/ai_system_action.sh open-skill-workflow            # open docs/SKILL-WORKFLOW.md
scripts/ai_system_action.sh open-project-onboarding        # open docs/PROJECT-ONBOARDING.md
scripts/ai_system_action.sh open-plan                      # open Plan-AI-System.md
scripts/ai_system_action.sh open-local-gui-design          # open docs/LOCAL-GUI-DESIGN.md
```

#### Configuration

```bash
scripts/ai_system_action.sh install-hooks     # bash scripts/install_git_hooks.sh
scripts/ai_system_action.sh git-status        # git status
```

#### Raccourcis locaux

```bash
scripts/ai_system_action.sh open-cursor       # cursor /path/to/ai-system
scripts/ai_system_action.sh open-terminal     # open -a Terminal /path
scripts/ai_system_action.sh open-finder       # open /path
```

### Cibles Make correspondantes

Pour un accès direct via Make (si nécessaire) :

```bash
make gui-check
make gui-inventory
make gui-doctor
make gui-update
make gui-update-codex
make gui-update-claude
make gui-install-project PROJECT=intrai TARGETS=both
make gui-open-inventory
make gui-open-doctor
make gui-open-readme
make gui-open-operations
make gui-open-skill-workflow
make gui-open-project-onboarding
make gui-open-plan
make gui-open-local-gui-design
make gui-install-hooks
make gui-git-status
make gui-open-cursor
make gui-open-terminal
make gui-open-finder
```

### Notes

- `scripts/ai_system_action.sh` est conçu comme point d'entrée pour une interface AppleScript future.
- Les actions longues (`check`, `update*`, `install-hooks`, `git-status`) ouvrent Terminal visible.
- Les rapports/docs s'ouvrent avec `open` (application par défaut du système).
- `make check` reste la validation de référence et est exécutée automatiquement après chaque action de sync.
- L'aide du script : `scripts/ai_system_action.sh --help`

## Interface locale macOS

### SwiftUI App (Recommandée — en développement)

Une nouvelle interface native macOS SwiftUI remplace progressivement l'AppleScript. Elle offre une meilleure UX, logs intégrés, et gestion native des projets.

#### Installation et lancement

Builder et installer l'app SwiftUI locale :

```bash
make build-swift-app
```

Cette commande :
- Compile le projet Xcode (`apps/AI-System/AI System.xcodeproj`).
- Installe l'app compilée dans `~/Applications/AI System.app`.

Lancer l'app installée :

```bash
open ~/Applications/AI\ System.app
```

Ou simplement cliquer sur l'icône dans le Finder/Spotlight.

#### Fonctionnalités

- **Tableau de bord** : vérification du système, diffusion partout.
- **Diffusion** : mettre à jour Codex / Claude / Tout.
- **Projets** : ajouter ou mettre à jour des projets (formulaire avec `NSOpenPanel`).
- **Rapports** : afficher Inventory et Doctor.
- **Documentation** : accès aux docs principales.
- **Outils** : installer hooks, consulter Git, ouvrir IDE/Terminal/Finder.
- **Logs** : afficher stdout/stderr/exit code, copier, effacer.

#### Mode CLI sans GUI

Pour exécuter des commandes sans lancer l'app graphique :

```bash
# Utilise le mode swift (pas de Terminal, separate streams)
AI_SYSTEM_UI_MODE=swift scripts/ai_system_action.sh check
AI_SYSTEM_UI_MODE=swift scripts/ai_system_action.sh install-project intrai both
```

### AppleScript App (Fallback — conservée)

L'ancienne interface AppleScript reste conservée comme fallback pendant la transition.

#### Lancement direct

Exécuter le script AppleScript directement depuis Terminal :

```bash
osascript scripts/ai_system_gui.applescript
```

ou :

```bash
./scripts/ai_system_gui.applescript
```

### Structure du menu

```
🤖 AI System Control (menu principal)
├─ ✅ Vérifier le système
├─ 📊 Diagnostics
│  ├─ ✅ Vérifier tout le système
│  ├─ ⚙️ Lancer Inventory seul
│  ├─ 🩺 Lancer Doctor seul
│  └─ ← Retour
├─ 📤 Diffusion des exports
│  ├─ 🔄 Diffuser tous les projets (Claude + Codex)
│  ├─ 📦 Diffuser Codex seulement
│  ├─ 🧠 Diffuser Claude seulement
│  └─ ← Retour
├─ 🎯 Projet spécifique
│  ├─ 🎯 Installer / mettre à jour un projet
│  │  ├─ [Dialogue] Saisir le nom du projet
│  │  └─ [Menu] Choisir la cible (codex, claude, both)
│  └─ ← Retour
├─ 📖 Rapports
│  ├─ 📄 Ouvrir Inventory
│  ├─ 🩺 Ouvrir Doctor
│  └─ ← Retour
├─ 📚 Documentation
│  ├─ 📘 README
│  ├─ 📘 Operations
│  ├─ 📘 Skill Workflow
│  ├─ 📘 Project Onboarding
│  ├─ 📘 Local GUI Design
│  ├─ 📘 Plan AI System
│  └─ ← Retour
├─ ⚙️ Configuration locale
│  ├─ 🔗 Installer hook pre-commit
│  ├─ 🌳 Afficher l'état Git
│  └─ ← Retour
├─ 🔗 Raccourcis
│  ├─ 💻 Ouvrir dans Cursor
│  ├─ ⌨️ Ouvrir dans Terminal
│  ├─ 📁 Ouvrir dans Finder
│  └─ ← Retour
└─ ❌ Quitter
```

### Exporter en application macOS

1. **Ouvrir le script dans Script Editor** :
   ```bash
   open -a "Script Editor" scripts/ai_system_gui.applescript
   ```

2. **Exporter en application** :
   - Cliquer sur **File > Export**
   - Choisir le format : **Application**
   - Nom recommandé : `AI System`
   - Emplacement recommandé : `~/Applications` ou `/Applications`
   - Cocher **Run in Background** (optionnel)
   - Cliquer **Save**

3. **L'application est maintenant prête** à être lancée comme une app macOS normale.

### Ajouter au Dock

1. **Ouvrir l'application** :
   ```bash
   open ~/Applications/"AI System.app"
   ```

2. **Ajouter au Dock** :
   - Clic droit sur l'icône dans le Dock
   - Sélectionner **Options > Keep in Dock**

3. **Désormais, cliquer sur l'icône Dock** lance le menu immédiatement.

### Tester les actions principales

Exemples de test manuel :

```bash
# Test 1 : Vérifier le système (ouvrira Terminal)
osascript scripts/ai_system_gui.applescript
→ Menu principal > ✅ Vérifier le système

# Test 2 : Ouvrir un rapport
osascript scripts/ai_system_gui.applescript
→ Menu principal > 📖 Rapports > 📄 Ouvrir Inventory

# Test 3 : Accéder à la documentation
osascript scripts/ai_system_gui.applescript
→ Menu principal > 📚 Documentation > 📘 Operations

# Test 4 : Ouvrir dans Finder
osascript scripts/ai_system_gui.applescript
→ Menu principal > 🔗 Raccourcis > 📁 Ouvrir dans Finder
```

### Cas d'usage

- **Nouvelle session de travail** : Cliquer sur l'icône Dock → ✅ Vérifier le système
- **Synchroniser les exports** : 📤 Diffusion des exports → 🔄 Diffuser tous les projets
- **Installer un projet** : 🎯 Projet spécifique → [nom du projet] + [cible]
- **Consulter un rapport** : 📖 Rapports → [Inventory ou Doctor]
- **Consulter la doc** : 📚 Documentation → [document]
- **Ouvrir en IDE** : 🔗 Raccourcis → 💻 Ouvrir dans Cursor

### Rappels importants

- La GUI est uniquement un **lanceur local** pour les actions du système.
- Le vrai **backend** reste `scripts/ai_system_action.sh` (pas visible à l'utilisateur).
- `make check` reste la **validation de référence** exécutée automatiquement.
- Les **annulations** (échap, fermeture) reviennent au menu précédent ou quittent proprement.

## Mode app vs Mode Terminal

### Mode app (défaut depuis l'interface GUI)

Les actions longues sont exécutées **en arrière-plan sans ouvrir Terminal** :

```bash
AI_SYSTEM_UI_MODE=app scripts/ai_system_action.sh check
```

Comportement :
- Pas d'ouverture de Terminal
- La sortie est écrite dans `logs/ai-system-last-action.log`
- L'interface affiche un message de succès ou d'erreur
- Exit code exploitable par AppleScript

### Mode Terminal (défaut en CLI)

Les actions s'exécutent **dans un Terminal visible** :

```bash
scripts/ai_system_action.sh check
# ou explicitement
AI_SYSTEM_UI_MODE=terminal scripts/ai_system_action.sh check
```

Comportement :
- Terminal s'ouvre automatiquement
- Vous voyez la progression en temps réel
- Utile pour déboguer ou voir les logs détaillés

### Logs

Chaque action en mode app écrit un log dans :

```
logs/ai-system-last-action.log
```

Contenu du log :
- Timestamp
- Action exécutée
- Commande lancée
- Stdout et stderr
- Exit code

**Accéder au log depuis l'interface :**
- Menu **Outils locaux** > **Ouvrir le dernier log**
- En cas d'erreur, cliquer sur **"Voir le log"** dans l'alerte

### Pourquoi pas d'emojis couleur

Les emojis couleur (🔄, 📦, 🧠, etc.) ont été évités volontairement car ils peuvent causer des problèmes :
- Problèmes d'encodage dans AppleScript
- Instabilité du compilateur osascript
- Affichage incohérent selon la version de macOS

À la place, le menu utilise du texte français clair et lisible.

## Ajouter un nouveau projet via l'interface

### Via l'interface locale (recommandé)

```bash
osascript scripts/ai_system_gui.applescript
```

Puis :
1. **Menu principal** > **Ajouter un nouveau projet**
2. Entrez le nom du projet : `mon-nouveau-projet`
3. Entrez le chemin absolu : `/Users/username/Documents/Misc/mon-nouveau-projet`
4. Sélectionnez la cible : `Claude + Codex` ou `Codex seulement` ou `Claude seulement`
5. Choisir : `Installer les commands/skills partagees maintenant` ou `Ajouter seulement au registre`
6. L'interface affiche le résultat

### Via le terminal

**Ajouter le projet au registre :**
```bash
python scripts/add_project.py --project mon-nouveau-projet --path /Users/username/Documents/Misc/mon-nouveau-projet --targets both
```

**Installer les commands/skills partagés :**
```bash
make install-project PROJECT=mon-nouveau-projet TARGETS=both
```

### Ce que `add-project` fait

1. Ajoute une entrée au `skills-registry.yml`
2. Configure les shared skills standards
3. Configure les targets (codex, claude, ou both)
4. Configure les paths par défaut
5. Marque le projet comme `enabled: true`
6. Optionnellement installe les exports partagés

### Validation après ajout

```bash
make check
```

Doit rester **OK**.

## Recréer l'application AI System.app

### Via l'interface

**Outils locaux** > **Recréer l'application Dock**

### Via le terminal

```bash
bash scripts/build_ai_system_app.sh
```

ou :

```bash
make build-gui-app
```

L'app est créée/mise à jour dans : `~/Applications/AI System.app`

### Ajouter l'app au Dock

1. Ouvrir l'app :
   ```bash
   open ~/Applications/"AI System.app"
   ```

2. Dans le Dock : clic droit sur l'icône AI System
3. **Options** > **Keep in Dock**

## Gestion des annulations

L'interface AppleScript gère proprement les annulations :
- Cliquer **Annuler** revient au menu précédent
- Aucune erreur `User cancelled. (-128)` n'apparaît
- Fermer un dialogue annule l'action en cours
- Le script n'affiche jamais de stack trace en cas d'annulation
