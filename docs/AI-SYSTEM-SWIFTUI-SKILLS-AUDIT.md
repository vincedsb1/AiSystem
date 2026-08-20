# Audit — Gestion des skills depuis l’application SwiftUI

Date : 2026-08-20

## 1. Fichiers inspectés

### Manifests et backend

- [`skills-manifest.yml`](/Users/vincentdesbrosses/Documents/Misc/ai-system/skills-manifest.yml)
- [`skills-registry.yml`](/Users/vincentdesbrosses/Documents/Misc/ai-system/skills-registry.yml)
- [`scripts/sync_skills.py`](/Users/vincentdesbrosses/Documents/Misc/ai-system/scripts/sync_skills.py)
- `scripts/install_project_exports.py`
- `scripts/update_project_exports.py`
- `scripts/ai_inventory.py`
- `scripts/ai_doctor.py`
- `scripts/check_ai_system.py`
- [`scripts/ai_system_action.sh`](/Users/vincentdesbrosses/Documents/Misc/ai-system/scripts/ai_system_action.sh)
- [`Makefile`](/Users/vincentdesbrosses/Documents/Misc/ai-system/Makefile)

### Application SwiftUI

- `Models/BackendAction.swift`
- `Models/CommandResult.swift`
- `Models/ProjectTarget.swift`
- `Services/AISystemPaths.swift`
- [`Services/CommandCenter.swift`](</Users/vincentdesbrosses/Documents/Misc/ai-system/apps/AI-System/AI System/Services/CommandCenter.swift>)
- [`Services/CommandRunner.swift`](</Users/vincentdesbrosses/Documents/Misc/ai-system/apps/AI-System/AI System/Services/CommandRunner.swift>)
- [`Views/ProjectsView.swift`](</Users/vincentdesbrosses/Documents/Misc/ai-system/apps/AI-System/AI System/Views/ProjectsView.swift>)
- [`Views/DashboardView.swift`](</Users/vincentdesbrosses/Documents/Misc/ai-system/apps/AI-System/AI System/Views/DashboardView.swift>)
- les composants SwiftUI existants

### Projet Xcode et validation

- [`AI System.xcodeproj/project.pbxproj`](</Users/vincentdesbrosses/Documents/Misc/ai-system/apps/AI-System/AI System.xcodeproj/project.pbxproj>)
- [`scripts/build_swift_app.sh`](/Users/vincentdesbrosses/Documents/Misc/ai-system/scripts/build_swift_app.sh)
- tests Python existants
- tests unitaires et UI Swift existants
- `README.md`, `docs/OPERATIONS.md` et `docs/SWIFTUI-GUI-PLAN.md`

Aucun fichier n’a été modifié pendant l’audit.

## 2. Diagnostic de l’architecture actuelle

L’architecture générale est adaptée et ne nécessite pas de refactor massif.

- `CommandRunner` transmet les arguments avec `Process.arguments`.
- `CommandCenter` sérialise les commandes.
- Le groupe Xcode utilise `PBXFileSystemSynchronizedRootGroup` : les nouveaux fichiers Swift peuvent être ajoutés sans modifier manuellement `project.pbxproj`.
- `ENABLE_APP_SANDBOX = NO` est bien configuré.
- `sync_skills.py` sait déjà synchroniser les canonicals project-specific avec `--only`, `--diff` et `--apply`.
- `ai_inventory.py` possède déjà les briques de scan, de pairing, de drift et de gestion des exceptions.

La cause principale du problème est précise : `install_project_exports.py` passe par `registry_shared_exports()`, qui accepte uniquement les canonicals `shared.*`. Le bouton actuel ne peut donc pas synchroniser les skills project-specific.

Le snapshot d’inventory présent dans le dépôt indique que Suggst est actuellement sain : les 7 skills project-specific sont reconnus en `ok_same_canonical`, sans action requise ni export manquant. Ce snapshot n’a pas été régénéré pendant l’audit.

Le worktree contient déjà des modifications suivies et des éléments non suivis, notamment `apps/`, les scripts GUI et `skills/projects/suggst/`. Ces changements doivent être préservés.

## 3. Problèmes UX identifiés

- Le projet est saisi manuellement au lieu d’être résolu depuis le registry.
- Aucun filtrage des projets actifs n’est fourni par l’interface.
- “Mettre à jour ce projet” ne traite que les skills partagés.
- L’application ne scanne pas les fichiers `.agents/skills` et `.claude/commands`.
- Aucun statut métier ne distingue unmanaged, missing, drift, conflict ou exception attendue.
- Les sorties humaines des scripts ne sont pas un contrat fiable pour SwiftUI.
- Aucun import assisté vers canonical + manifest + exports n’existe.
- Aucun contrôle d’idempotence ni prévisualisation source/destination n’est fourni.
- Le dashboard affiche principalement `Idle` au lieu d’un état système exploitable.

Le script `ai_system_action.sh` contient également des chemins historiques utilisant `eval` pour des actions paramétrées. Les nouvelles actions projet devront utiliser une exécution directe avec des arguments séparés.

## 4. Architecture backend proposée

Créer une façade dédiée :

`scripts/project_skills.py`

Sous-commandes proposées :

- `list-projects --json`
- `scan --project Suggst --json`
- `import --project Suggst --skill my-new-skill --source codex --json`
- `sync --project Suggst --json`
- `overview --json`

Cette façade devra :

1. Résoudre les projets actifs depuis `skills-registry.yml`.
2. Refuser les projets inconnus, désactivés ou ambigus.
3. Scanner les deux répertoires runtime.
4. Réutiliser les helpers existants de normalisation, frontmatter, pairing, exceptions et génération.
5. Effectuer les imports avec prévalidation et écritures atomiques.
6. Synchroniser les shared autorisés et les canonicals project-specific.
7. Retourner exclusivement du JSON pour les appels machine.

Flux d’import :

1. Résolution stricte du projet.
2. Résolution du skill uniquement sous les chemins enregistrés.
3. Lecture du frontmatter `name` et `description`.
4. Validation du nom normalisé et du canonical ID.
5. Vérification des doublons, chemins, exceptions et destinations existantes.
6. Création du canonical project-specific.
7. Ajout de l’entrée manifest.
8. Synchronisation des deux exports.
9. Scan de validation.
10. Réponse JSON détaillée.

Un canonical existant identique pourra retourner `already_managed`. Un canonical existant incompatible devra retourner une erreur sans écriture.

## 5. Contrat JSON proposé

Le contrat doit utiliser une enveloppe stable avec `schemaVersion`, `status`, `generatedAt`, les données métier et un objet `error` éventuel.

Exemple de réponse `scan` :

```json
{
  "schemaVersion": 1,
  "status": "ok",
  "generatedAt": "2026-08-20T15:00:00Z",
  "project": {
    "name": "Suggst",
    "root": "/Users/vincentdesbrosses/Documents/Misc/Suggst",
    "enabled": true,
    "paths": {
      "codexSkills": "/Users/vincentdesbrosses/Documents/Misc/Suggst/.agents/skills",
      "claudeCommands": "/Users/vincentdesbrosses/Documents/Misc/Suggst/.claude/commands"
    }
  },
  "summary": {
    "managed": 20,
    "unmanaged": 2,
    "shared": 13,
    "projectSpecific": 7,
    "missingClaude": 0,
    "missingCodex": 0,
    "drift": 0,
    "conflicts": 0,
    "expectedExceptions": 6,
    "actionRequired": 0
  },
  "skills": [
    {
      "name": "my-new-skill",
      "canonicalId": null,
      "candidateCanonicalId": "suggst.my-new-skill",
      "scope": null,
      "sourceOfTruth": null,
      "presence": {
        "codex": true,
        "claude": false
      },
      "paths": {
        "codex": "/Users/.../.agents/skills/my-new-skill/SKILL.md",
        "claude": null,
        "canonical": "/Users/.../ai-system/skills/projects/suggst/my-new-skill/canonical.md"
      },
      "managed": false,
      "importable": true,
      "status": "local_codex_only",
      "exception": null,
      "conflict": null
    }
  ],
  "error": null
}
```

Statuts métier proposés :

- `managed_synced`
- `local_codex_only`
- `local_claude_only`
- `local_both_unmanaged`
- `missing_claude`
- `missing_codex`
- `canonical_drift`
- `manifest_error`
- `conflict`
- `expected_claude_only`

Les erreurs utiliseront des codes comme `unknown_project`, `disabled_project`, `frontmatter_missing`, `canonical_exists`, `canonical_conflict`, `path_escape`, `expected_exception` ou `target_conflict`.

## 6. Modifications SwiftUI proposées

- Ajouter des modèles `Codable` pour les réponses JSON.
- Ajouter les actions projet typées dans `BackendAction`.
- Faire retourner un `CommandResult` par une nouvelle méthode de `CommandCenter`, sans casser l’API existante.
- Conserver `CommandRunner` basé sur `Process.arguments`.
- Remplacer le champ texte de `ProjectsView` par un `Picker` alimenté par `list-projects`.
- Ajouter l’analyse, le résumé métier, la liste des skills et les statuts.
- Ajouter l’import avec confirmation source/destination.
- Ajouter la synchronisation globale du projet.
- Ajouter `ProgressView`, désactivation des boutons et erreurs inline.
- Conserver le formulaire “Ajouter un nouveau projet”.
- Alimenter `DashboardView` avec `overview --json`.

SwiftUI ne devra parser ni YAML ni logs humains.

## 7. Fichiers à créer

- `scripts/project_skills.py`
- `tests/test_project_skills.py`
- `apps/AI-System/AI System/Models/ProjectSkillsModels.swift`

Un composant optionnel pourra être ajouté si nécessaire :

- `apps/AI-System/AI System/Views/Components/ProjectSkillRow.swift`

Aucun nouveau package externe et aucune modification manuelle du projet Xcode ne sont nécessaires.

## 8. Fichiers à modifier

- `scripts/ai_system_action.sh` : ajout des routes JSON et exécution sûre par arguments séparés.
- `Makefile` : éventuelles cibles CLI de confort.
- `Models/BackendAction.swift`
- `Services/CommandCenter.swift`
- `Views/ProjectsView.swift`
- `Views/DashboardView.swift`
- `README.md`
- `docs/OPERATIONS.md`
- `docs/SWIFTUI-GUI-PLAN.md`

À ne pas modifier dans l’implémentation initiale :

- `skills-manifest.yml` manuellement ;
- `skills-registry.yml` manuellement ;
- les 7 canonicals Suggst existants ;
- `project.pbxproj` ;
- l’AppleScript fallback.

## 9. Migration et rétrocompatibilité

- `make install-project` reste limité aux shared skills.
- `make update-projects` reste inchangé.
- `sync_skills.py` reste utilisable avec `--only`.
- Le nouveau bouton “Synchroniser le projet” utilise la nouvelle façade.
- L’entrée inactive `suggst` est conservée.
- `list-projects` affiche uniquement `Suggst`, l’entrée active.
- Une résolution avec `suggst` exact retourne “projet désactivé”.
- Les 7 entries `suggst.*` existantes sont reconnues comme managed, sans réimport.
- L’AppleScript reste disponible.

## 10. Stratégie de tests

Ajouter des tests Python sur des fixtures temporaires pour couvrir :

1. Codex-only non géré.
2. Claude-only non géré.
3. Claude-only attendu via exception.
4. Skill déjà canonicalisé.
5. Import Codex vers canonical puis Claude.
6. Import Claude vers canonical puis Codex.
7. Canonical existant.
8. Canonical ID conflictuel.
9. Chemin hors projet.
10. Projet inconnu.
11. Projet désactivé.
12. Scan idempotent du cas Suggst.

Ajouter également :

- tests de décodage des modèles Swift ;
- `bash -n` sur le pont shell ;
- scan CLI réel de Suggst en lecture seule ;
- vérification que les 7 skills restent `managed_synced`.

## 11. Risques identifiés

- Écriture simultanée du canonical, du manifest et des exports : utiliser des fichiers temporaires, une validation YAML et des sauvegardes.
- Réécriture complète du manifest par PyYAML : privilégier une modification atomique limitée à l’entrée ajoutée.
- Destination Claude/Codex existante mais différente : retourner `target_conflict`.
- Collision après normalisation du nom : retourner `conflict`.
- Symlink sortant du root projet : refuser.
- Frontmatter absent ou invalide : import impossible avec message explicite.
- Exception Claude-only : ne jamais convertir automatiquement.
- Différence de casse dans le registry : résolution exacte et erreur d’ambiguïté.
- Dashboard dépendant d’un rapport historique : produire une observation fraîche via `overview --json`.
- Worktree déjà modifié : préserver tous les changements existants.

## 12. Plan d’implémentation

1. Audit terminé, sans écriture.
2. Implémenter le contrat JSON et la résolution des projets.
3. Implémenter `list-projects` et `scan`.
4. Ajouter les tests de scan et valider Suggst en lecture seule.
5. Implémenter l’import atomique et ses tests.
6. Implémenter `sync` project + shared + validation.
7. Ajouter les routes sûres dans `ai_system_action.sh`.
8. Ajouter les modèles Swift et l’API de retour de `CommandCenter`.
9. Refondre `ProjectsView`.
10. Ajouter `overview --json` et le résumé Dashboard.
11. Mettre à jour la documentation.
12. Exécuter les validations finales :
    - `make inventory`
    - `make doctor`
    - `make check`
    - build Release avec `xcodebuild`
    - `make build-swift-app`
    - test de l’application installée.

La prochaine étape est l’implémentation backend, en commençant par `list-projects` et `scan`, sans toucher aux canonicals Suggst existants.
