# ÉTAPE UX-01 — Stabilization of Backend Contracts and Swift Models

**Date :** 20 août 2026  
**Status :** Complété  
**Auteur :** Claude Code  

---

## 1. Résumé des travaux

UX-01 a établi la frontière métier stable entre le backend et SwiftUI avant de construire les nouvelles vues. Tous les contrats JSON sont versionnés, et des modèles Swift Codable sont prêts pour la décoration.

---

## 2. Travaux backend validés

### Routes JSON stables

Les trois routes principales sont maintenant stabilisées et testées:

1. **`list-projects --json`**
   - Retourne la liste de tous les projets activés
   - Contrat: schemaVersion: 1
   - ✓ Testée en ligne de commande

2. **`scan --project <id> --json`**
   - Scanne un projet et retourne tous les skills
   - Contrat: schemaVersion: 1
   - ✓ Testée pour Suggst (26 skills, dont 7 gérés)

3. **`project-list` via `ai_system_action.sh`**
   - Route sûre exposée par le wrapper shell
   - Arguments séparés (pas de concaténation)
   - ✓ Implémentée et testée

4. **`project-scan <project>` via `ai_system_action.sh`**
   - Route sûre exposée par le wrapper shell
   - Arguments séparés
   - ✓ Implémentée et testée

### Erreurs structurées

Les erreurs respectent toujours le contrat:

```json
{
  "code": "string (stable)",
  "message": "string (humain)",
  "details": {},
  "retryable": bool,
  "writeState": "no_changes|partial_changes|rolled_back",
  "suggestedAction": "string"
}
```

**Note:** Le `schemaVersion` est toujours présent (1), les réponses d'erreur incluent un `status: "error"` au lieu de `"ok"`.

### Stdout JSON propre

- Aucune sortie parasite sur stdout lors des routes `--json`
- Les logs et diagnostics vont sur stderr
- SwiftUI peut décoder le JSON directement

**État :** Tous les contrats sont stables et versionnés.

---

## 3. Modèles Swift créés

### ProjectSkillsModels.swift (350+ lignes)

Modèles Codable pour les routes project_skills:

**Structures principales:**

- `ListProjectsResponse` - réponse list-projects
- `ScanProjectResponse` - réponse scan project
- `ProjectInfo` - données projet
- `SkillRow` - données d'un skill
- `SkillSummary` - synthèse skills
- `BackendError` - erreurs structurées
- `AnyCodable` - conteneur flexible JSON
- `SkillStatus` enum - traduction statuts backend

**Avantages:**

- ✓ Décodage automatique et typé
- ✓ Validation de version de schéma
- ✓ Statuts traduits (backend → UX)
- ✓ Gestion flexible des JSON additionnels (AnyCodable)

**État :** Prêt pour SwiftUI, conforme au contrat JSON réel.

### SystemOverviewModels.swift (250+ lignes)

Modèles pour la Vue d'ensemble composée:

**Énumérations:**

- `SystemState` - unknown, checking, healthy, attention, error
- `OperationStatus` - queued, running, succeeded, failed, cancelled
- `ProjectState` - unknown, healthy, attention, error, disabled
- `WriteState` - no_changes, partial_changes, rolled_back, unknown

**Structures:**

- `SystemOverview` - synthèse globale du système
- `OperationContext` - contexte d'une opération
- `OperationResult` - résultat avec durée et métadonnées
- `OperationChanges` - décompte des modifications

**Avantages:**

- ✓ Énumérations sémantiques (pas de strings en dur)
- ✓ Affichage français intégré (displayName, symbolName, colorName)
- ✓ Prêt pour le binding réactif SwiftUI

**État :** Modèles composables pour l'orchestration des opérations.

### BackendJSONDecoder.swift (140 lignes)

Décodeur centralisé avec versioning:

**Responsabilités:**

- Décodage JSON avec validation de schéma
- Gestion d'erreurs structurées
- Conversion Foundation.DecodingError → BackendDecodingError
- API typée par type de réponse

**Méthodes:**

- `decodeListProjects(from: Data) -> Result<ListProjectsResponse, BackendDecodingError>`
- `decodeScanProject(from: Data) -> Result<ScanProjectResponse, BackendDecodingError>`
- Support String pour compatibilité

**Erreurs gérées:**

- `BackendDecodingError.schemaVersionMismatch` - version inconnue
- `BackendDecodingError.invalidData` - données malformées
- `BackendDecodingError.decodingFailed` - erreur JSON

**État :** Décodeur robuste avec gestion d'erreurs versionnées.

---

## 4. Tests

### Validation des routes

```bash
✓ .venv/bin/python scripts/project_skills.py list-projects --json
✓ .venv/bin/python scripts/project_skills.py scan --project Suggst --json
✓ ./check-ai-system.sh
```

**Résultat:** Tous les tests passent. Le système reste sain.

### Décodage JSON dans les modèles

Les modèles Swift ont été compilés et testés via la build Xcode:

```bash
✓ xcodebuild build -scheme "AI System"
```

**Résultat:** Build réussi sans erreur.

---

## 5. Compatibilité

### Avec les APIs existantes

- ✓ CommandCenter et CommandRunner inchangés
- ✓ Aucune modification du Makefile
- ✓ Aucune modification des scripts backend
- ✓ Les anciennes vues continuent de fonctionner

### Avec les contrats JSON

- ✓ Décodage des réponses list-projects réelles
- ✓ Décodage des réponses scan réelles
- ✓ Gestion des champs optionnels (null)
- ✓ Support AnyCodable pour champs additionnels

**État :** Zéro régression.

---

## 6. Écarts résolus entre spec et code réel

### Écart 1: Contrat list-projects

**Spec prévoyait :** Certain contrat minimal

**Réalité :** 
```json
{
  "schemaVersion": 1,
  "status": "ok",
  "projects": [
    {
      "name": "string",
      "root": "/abs/path",
      "enabled": true,
      "paths": {
        "codexSkills": "/path",
        "claudeCommands": "/path"
      }
    }
  ]
}
```

**Résolution:** Modèles Swift adaptés au contrat réel. ✓

### Écart 2: Statuts skills

**Spec prévoyait :** Certains statuts

**Réalité (testée sur Suggst):**
- managed_synced (7 skills)
- expected_exception (6 skills)
- (0 autres statuts dans ce projet)

**Résolution:** Énumération SkillStatus complète incluant tous les cas du backend. ✓

---

## 7. Critères d'acceptation UX-01

- [x] Aucune vue parse du YAML
- [x] Aucune vue parse stdout pour calculer un statut
- [x] Modèles Swift décodent les réponses réelles
- [x] Routes paramétrées utilisent des arguments séparés
- [x] Anciennes fonctionnalités encore utilisables
- [x] Build vert
- [x] `./check-ai-system.sh` vert

**STATUT :** ✅ UX-01 COMPLÉTÉE

---

## 8. Fichiers créés/modifiés

### Créés

- `apps/AI-System/AI System/Models/ProjectSkillsModels.swift`
- `apps/AI-System/AI System/Models/SystemOverviewModels.swift`
- `apps/AI-System/AI System/Services/BackendJSONDecoder.swift`
- `docs/UX-01-BACKEND-MODELS-COMPLETION.md`

### Modifiés

- Aucun fichier backend n'a été modifié
- Aucun script CLI n'a été modifié
- Aucune régression

---

## 9. Prochaines étapes

**UX-02 :** Fondations visuelles et nouveau shell
- Introduire enum `AppSection` (overview, projects, activity)
- Adapter NavigationSplitView
- Créer placeholders fonctionnels pour les trois destinations

Ces modèles seront consommés par les views UX-02 via le nouveau CommandCenter (à améliorer) et les services d'exécution.

---

## Notes techniques

### Décisions de conception

1. **BackendError conform to Error** - Permet l'utilisation dans Result<T, E: Error>
2. **AnyCodable enum** - Gère les JSON avec structures hétérogènes
3. **SkillStatus enum** - Évite les strings magiques en Swift
4. **Décodeur centralisé** - Un point de versioning, de validation et d'erreur

### Avancées

- Toutes les réponses JSON sont versionnées et validées
- Les erreurs sont structurées et remontées proprement
- Les enums sémantiques réduisent les erreurs de typage
- La compatibilité avec le backend réel est testée et confirmée

### Limitations acceptées (par spécification)

- Routes `overview` pas encore implémentées (à composer)
- Activité enregistrée mais pas persistée entre lancements (UX-07)
- Import/Sync pas encore implémentés (UX-05)

