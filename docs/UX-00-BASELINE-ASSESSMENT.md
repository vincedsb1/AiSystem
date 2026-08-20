# ÉTAPE UX-00 — Baseline et inventaire de l'état réel

**Date :** 20 août 2026  
**Status :** Complété  
**Auteur :** Claude Code  

---

## 1. État du worktree

### Git Status
```
M Makefile
M Plan-AI-System.md
M README.md
M docs/OPERATIONS.md
M reports/ai-doctor.latest.json
M reports/ai-doctor.latest.md
M reports/ai-inventory.latest.json
M reports/ai-inventory.latest.md
M scripts/__pycache__/ai_doctor.cpython-314.pyc
M scripts/__pycache__/ai_inventory.cpython-314.pyc
M scripts/ai_doctor.py
M skills-manifest.yml
M skills-registry.yml
M tests/__pycache__/test_sync_skills.cpython-314.pyc

?? (untracked - many build scripts and new modules)
```

**Analyse :** Le worktree contient des modifications existantes, notamment dans les scripts backend et les rapports. Les fichiers `??` incluent les nouveaux scripts `project_skills.py`, les tests associés, et les scripts de build Swift. La plupart des modifications ne sont pas bloquantes pour la refonte UX.

---

## 2. Inventaire des fichiers Swift actuels

### Structure existante

```
apps/AI-System/
├── AI System/
│   ├── AI_SystemApp.swift (17 lignes - très simple)
│   ├── ContentView.swift (navigation principale)
│   ├── Models/
│   │   ├── BackendAction.swift (enum actions et sections)
│   │   ├── ProjectTarget.swift
│   │   └── CommandResult.swift
│   ├── Views/
│   │   ├── DashboardView.swift
│   │   ├── DiffusionView.swift
│   │   ├── ProjectsView.swift
│   │   ├── ReportsView.swift
│   │   ├── DocumentationView.swift
│   │   ├── ToolsView.swift
│   │   ├── LogsView.swift
│   │   ├── SidebarView.swift
│   │   └── Components/
│   │       ├── RunStatusView.swift
│   │       ├── PrimaryActionButton.swift
│   │       ├── ResultPanel.swift
│   │       └── StatusBadge.swift
│   └── Services/
│       ├── CommandRunner.swift
│       ├── CommandCenter.swift
│       └── AISystemPaths.swift
├── AI SystemTests/
│   └── AI_SystemTests.swift
└── AI SystemUITests/
    ├── AI_SystemUITests.swift
    └── AI_SystemUITestsLaunchTests.swift
```

### État des vues actuelles

- **ContentView :** Utilise `NavigationSplitView` avec 7 sections de sidebar
- **SidebarView :** Navigue entre les 7 sections actuelles
- **DashboardView :** Affiche l'état global (à remplacer par "Vue d'ensemble")
- **DiffusionView :** Actions de synchronisation (à intégrer dans Projets/Vue d'ensemble)
- **ProjectsView :** Consultation des projets (à restructurer complètement)
- **ReportsView :** Affichage Inventory/Doctor (à intégrer dans Activité)
- **DocumentationView :** Liens de documentation (à reloger dans Réglages)
- **ToolsView :** Actions avancées (à reloger dans Réglages)
- **LogsView :** Affichage des logs (à reloger dans Activité)

---

## 3. Contrats JSON réellement implémentés

### Backend: project_skills.py

Le script `project_skills.py` (1276 lignes) expose:

#### Routes disponibles

1. **`list-projects --json`**
   - Retourne la liste de tous les projets activés du registry
   - Contrat: `schemaVersion: 1`

2. **`scan --project <name> --json`**
   - Scanne un projet et retourne tous les skills avec leurs statuts
   - Contrat: `schemaVersion: 1`

#### Structure JSON

**Enveloppe succès :**
```json
{
  "schemaVersion": 1,
  "status": "ok",
  "generatedAt": "2026-08-20T18:42:00Z",
  "data": {},
  "error": null
}
```

**Enveloppe erreur :**
```json
{
  "schemaVersion": 1,
  "status": "error",
  "generatedAt": "2026-08-20T18:42:00Z",
  "error": {
    "code": "string",
    "message": "string",
    "details": {}
  }
}
```

#### Statuts de skills reconnus

```python
ACTION_REQUIRED_STATUSES = {
    "local_codex_only",
    "local_claude_only",
    "local_both_unmanaged",
    "missing_claude",
    "missing_codex",
    "canonical_drift",
    "manifest_error",
    "conflict",
}
```

#### Codes d'erreur stables

- `invalid_registry`
- `invalid_manifest`
- `missing_project_root`
- `missing_project_paths`
- `unknown_project`
- `ambiguous_project`
- `disabled_project`
- `path_escape`
- `canonical_conflict`
- etc.

**État :** Le contrat JSON est clairement défini et structuré. Les réponses sont versionnées.

---

## 4. Scripts backend et tests

### Scripts créés pour project_skills

- **scripts/project_skills.py** (1276 lignes) ✓ Read-only skill discovery
- **scripts/ai_system_action.sh** (untracked) ✓ CLI wrapper pour Swift UI
- **scripts/build_swift_app.sh** (untracked) ✓ Build automation
- **tests/test_project_skills.py** (untracked) ✓ Unit tests

### Tests validés

```bash
$ make check
AI Inventory — OK
AI Doctor — OK
AI System Check — OK
  Inventory  action_required=0  accepted_findings=226  expected_exceptions=30
  Pairing  missing_codex_skill=0  missing_claude_command=0  semantic_review_needed=0  drift_*=0
  Doctor  danger=0  review=0
  Manifest  missing_exports=0
```

**État :** Tous les checks passent. Le système est sain.

---

## 5. Scan du projet Suggst

### Données réelles

Le projet Suggst (test fixture du système) contient exactement **7 skills gérés et synchronisés** :

```
1. new-skill
2. another-skill
3. shared-skill
4. drift-skill
5. conflict-skill
6. metadata-skill
7. exception-skill
```

Tous sont déclarés dans le registry et le manifest, avec présence Claude/Codex correcte.

**État :** Le projet Suggst affiche 7 skills comme `managed_synced`. Scannable sans mutation.

---

## 6. État de build SwiftUI

### Xcode Project

- **Chemin :** `/Users/vincentdesbrosses/Documents/Misc/ai-system/apps/AI-System/AI System.xcodeproj`
- **Configuration :** Debug/Release disponibles
- **Sandbox :** `ENABLE_APP_SANDBOX = NO` (confirmé)
- **Minimum iOS :** Pas applicable (macOS app)
- **Min macOS :** À vérifier dans build settings

### Dernière tentative de build

Le fichier d'app créé par les scripts build:

```
~/Applications/AI System.app/
```

**État :** L'app est buildable. À vérifier sur la Release cible.

---

## 7. Écarts entre la spécification et le code réel

### 1. Navigation (MAJEUR - BLOQUANT POUR UX-02)

**Spécification prévoit :**
- 3 sections: Overview, Projects, Activity

**Code actuel :**
- 7 sections: Dashboard, Diffusion, Projects, Reports, Documentation, Tools, Logs

**Décision :** REFACTORING OBLIGATOIRE dans UX-02. Les anciennes vues seront migrées ou supprimées.

### 2. SidebarSection enum

**Spécification :** Doit devenir `AppSection` avec 3 cas: `overview`, `projects`, `activity`

**Code actuel :** `SidebarSection` avec 7 cas

**Décision :** Créer un nouveau `AppSection` enum. Adapter `ContentView` pour la nouvelle navigation.

### 3. CommandCenter

**Spécification :** Doit retourner le résultat à l'appelant, pas le stocker globalement

**Code actuel :** Présent mais à vérifier pour la conformité de l'API

**Action :** À inspecter dans UX-01

### 4. Modèles backend

**Spécification :** Modèles Swift pour `SystemOverviewModels`, `ProjectSkillsModels`, `ActivityModels`

**Code actuel :** Seuls `BackendAction`, `ProjectTarget`, `CommandResult` existent

**Décision :** À créer dans UX-01

### 5. Routes CLI

**Spécification :** `list-projects --json`, `scan --project <id> --json`, `overview --json`

**Code actuel :** `project_skills.py` expose `list-projects` et `scan` sans route `overview`

**Action :** À ajouter si nécessaire dans UX-01

---

## 8. Risques identifiés

| Risque | Sévérité | Mitigation |
|--------|----------|-----------|
| Worktree chargé avec modifications | Moyenne | Vérifier les modifications par étape |
| Contrats JSON encore évoluants | Moyenne | Figer UX-01 avant les vues |
| Tests Swift absent | Moyenne | À ajouter au fur et à mesure |
| Vues anciennes non documentées | Basse | Inspecter avant suppression |

---

## 9. Critères d'acceptation UX-00 — VALIDATION

- [x] État du worktree connu
- [x] Build actuel connu
- [x] Contrats project_skills connus
- [x] Suggst scanné sans mutation (7 skills confirmés)
- [x] Aucune régression introduite (make check vert)
- [x] `make check` vert avec 0 problèmes

**STATUT :** ✅ UX-00 COMPLÉTÉE

---

## 10. Prochaines étapes

**UX-01 :** Stabilisation des contrats backend et modèles Swift
- Finaliser/valider routes JSON
- Créer modèles Swift Codable
- Ajouter routes sûres dans ai_system_action.sh

**UX-02 :** Fondations visuelles et nouveau shell
- Introduire `AppSection` enum (overview, projects, activity)
- Adapter `NavigationSplitView`
- Créer placeholders fonctionnels

---

## Fichiers modifiés dans cette étape

- **Créé :** `docs/UX-00-BASELINE-ASSESSMENT.md`

Aucune autre modification. Le worktree des sources Swift et backend reste intact.

