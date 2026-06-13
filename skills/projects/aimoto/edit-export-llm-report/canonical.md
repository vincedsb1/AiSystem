# /edit-export-llm-report — Modifier le rapport Export LLM

Commande dédiée à toute modification du rapport LLM de grid-search (structure, contenu, logique, tests).
Couvre : ajout/suppression de sections, changement de wording, modification du VETO TABLE, enrichissement des agrégats, nouveau check RCS, etc.

---

## PHASE 0 — Lecture obligatoire avant toute modification

Lire ces fichiers **en entier** avant de toucher au code :

| Fichier | Pourquoi |
|---------|----------|
| `docs/reference/FEATURE-EXPORT-LLM-REPORT.md` | Vue d'ensemble, structure du prompt, versionnement, bonnes pratiques |
| `backend/app/algo/prompt/wording.py` | Contient `PROMPT_VERSION` — à bumper obligatoirement |
| `backend/app/algo/prompt/registry.py` | Liste ordonnée des sections — vérifier l'ordre avant tout ajout |
| `backend/app/algo/prompt/context.py` | `PromptContext` (frozen dataclass) — tous les inputs disponibles |
| `backend/app/algo/prompt/builder.py` | Signature publique `build_export_llm_prompt` |
| `.claude/rules/tests.md` | Marqueurs pytest, gate de couverture sur modules purs |

---

## PHASE 1 — Identifier la portée du changement

Déterminer dans quelle(s) couche(s) la modification touche :

```
[ ] Wording / texte d'une section existante    → modifier le fichier section concerné
[ ] Nouvelle section                            → créer s{N}_*.py + enregistrer dans registry.py
[ ] Suppression de section                      → retirer de registry.py, supprimer le fichier
[ ] Logique VETO TABLE                          → backend/app/algo/prompt/veto/engine.py + tables.py
[ ] Check RCS (Report Consistency Status)       → backend/app/algo/report_consistency.py
[ ] Input supplémentaire depuis l'endpoint      → main.py + context.py + builder.py
[ ] Enrichissement des agrégats                 → backend/app/algo/aggregates_enrich.py (si présent)
[ ] Caveats / détection d'anomalies             → backend/app/algo/caveats_detector.py
```

---

## PHASE 2 — Règles de versionnement (OBLIGATOIRES — STRICT)

> ⚠️ **RÈGLE BLOQUANTE** : tout changement de cette commande qui touche le contenu du prompt généré **DOIT** être accompagné, dans le **même commit / la même unité de travail**, d'un bump explicite de `PROMPT_VERSION` dans `backend/app/algo/prompt/wording.py`. **Aucune exception**, y compris pour :
>
> - les micro-corrections cosmétiques (wording d'une ligne)
> - les ajouts conditionnels (nouveau cas affichant une nouvelle phrase)
> - les itérations rapprochées pendant une même review (chaque itération = un bump, pas d'« absorption » dans la version précédente)
> - les ajouts de tests qui valident un nouveau comportement de rendu
>
> Tant que `PROMPT_VERSION` n'a pas été bumpé, **la modification n'est pas considérée terminée**. Si tu hésites entre bumper ou non, **bumpe**.

### Algorithme à exécuter au DÉBUT de toute modif

```
1. Lire la valeur actuelle de PROMPT_VERSION dans backend/app/algo/prompt/wording.py
2. Décider IMMÉDIATEMENT du nouveau numéro :
   - PATCH (+1) : correctif de wording, ajout conditionnel, fix logique sans nouveau champ public
   - MINOR (+1, PATCH=0) : ajout/suppression de section, nouveau champ public dans PromptContext, breaking change
3. Bumper PROMPT_VERSION AVANT de faire les autres modifs (évite l'oubli systématique en fin de tâche)
4. Propager le nouveau numéro dans docs/reference/FEATURE-EXPORT-LLM-REPORT.md :
   - Métadonnée § "Last Updated" + "Prompt version"
   - § Versionnement (valeur actuelle)
   - § Header / endpoint JSON (exemple)
   - Ajouter UNE entrée dans le tableau Changelog (date ISO + résumé concis)
5. Faire la modification de code/sections/banner/etc.
6. Régénérer les snapshots : `UPDATE_SNAPSHOTS=1 pytest tests/algo/test_export_llm_prompt_snapshot.py`
7. Vérifier que la nouvelle version apparaît dans le snapshot régénéré
```

### Cas qui DÉCLENCHENT obligatoirement un bump

- Ajout / suppression / réécriture d'une section (`sections/*.py`, `registry.py`)
- Correctif de wording dans `wording.py` (autre que `PROMPT_VERSION` lui-même)
- Modification du banner FAIL/WARN (`render_banner`, `inject_banner_after_header`)
- Modification d'un check RCS (ajout, renommage, changement de logique, changement de promotion)
- Modification du rendu YAML de §0.C (`build_report_consistency_status_yaml_section`)
- Modification VETO TABLE (`veto/engine.py`, `veto/tables.py`, mappings, précisions, labels)
- Correctif de routage dans `main.py` qui change les données passées à `build_export_llm_prompt()`
- Toute modification qui fait diverger un snapshot dans `tests/algo/snapshots/`
- Ajout / suppression d'un champ dans `PromptContext` (même optionnel)

### Cas qui ne nécessitent **pas** de bump

- Refactor interne pur : extraire une fonction privée, renommer une variable locale, déplacer un import — **sans aucun effet sur l'output**
- Ajout de commentaires, docstrings, logs
- Ajout de tests qui ne révèlent **pas** un changement de comportement (tests de régression sur du code existant non modifié)

### Schéma SemVer interne

```
v0.MINOR.PATCH
  ^      ^
  |      └── +1 à chaque correctif de wording, banner, RCS, VETO, routage
  └────────── +1 à chaque ajout/suppression de section, breaking change de PromptContext
```

### Auto-check de fin de tâche (à exécuter mentalement avant `/commit`)

```
$ grep -E 'PROMPT_VERSION:\s*Final\[str\]\s*=' backend/app/algo/prompt/wording.py
$ git diff backend/app/algo/prompt/wording.py | grep '^[+-].*PROMPT_VERSION'
```

Si le diff de `wording.py` ne contient **pas** une ligne `-PROMPT_VERSION ...` / `+PROMPT_VERSION ...` alors que d'autres fichiers du sous-paquet `prompt/`, `report_consistency.py`, le routage `main.py` ou des snapshots ont changé → **STOP, bump avant de committer**.

### Récapitulatif des emplacements à mettre à jour

| # | Fichier | Champ |
|---|---------|-------|
| 1 | `backend/app/algo/prompt/wording.py` | `PROMPT_VERSION` |
| 2 | `docs/reference/FEATURE-EXPORT-LLM-REPORT.md` | Métadonnée `**Last Updated**` |
| 3 | `docs/reference/FEATURE-EXPORT-LLM-REPORT.md` | Métadonnée `**Prompt version**` |
| 4 | `docs/reference/FEATURE-EXPORT-LLM-REPORT.md` | § Versionnement (Valeur actuelle) |
| 5 | `docs/reference/FEATURE-EXPORT-LLM-REPORT.md` | § Versionnement (exemple header + endpoint JSON) |
| 6 | `docs/reference/FEATURE-EXPORT-LLM-REPORT.md` | Tableau Changelog (nouvelle ligne) |
| 7 | `backend/tests/algo/snapshots/*.md` | Régénération via `UPDATE_SNAPSHOTS=1` |

---

## PHASE 3 — Fichiers à modifier selon le type de changement

### Ajouter une section

1. Créer `backend/app/algo/prompt/sections/s{N}_{nom}.py`
   - Exposer une fonction `render(ctx: PromptContext) -> str`
   - Retourner `""` si le contenu est absent (ne jamais lever d'exception pour un champ optionnel)
   - Ne jamais retourner de données mock/placeholder — raise ou `""` uniquement
2. Enregistrer dans `backend/app/algo/prompt/registry.py` (ordre numérique)
3. Si la section consomme un nouvel input : ajouter le champ dans `context.py` + paramètre dans `builder.py` + valeur dans `main.py`
4. Mettre à jour `docs/reference/FEATURE-EXPORT-LLM-REPORT.md` §4 (structure) et §5 (sections en détail) et §6 (fichiers)

### Modifier la logique VETO TABLE

- Moteur : `backend/app/algo/prompt/veto/engine.py`
  - `_VETO_FIELD_TO_METRIC_KEY` — mapping champ objectif → clé `metrics_json`
  - `_ABS_FIELDS` — champs à comparer en valeur absolue (ex. `max_drawdown_pct`)
  - `evaluate_veto_table(objectives, metrics)` — fonction pure
- Rendu : `backend/app/algo/prompt/veto/tables.py`
- Parsing `metrics_json` : **toujours via `_parse_metrics_json_with_log`** (importé depuis `app.algo.prompt._metrics_json`) — jamais de parsing ad-hoc inline dans `main.py`

### Ajouter un check RCS

- Fichier : `backend/app/algo/report_consistency.py`
- Fonction : `compute_report_consistency_status` — ajouter le check dans la liste interne
- Nom de check : snake_case descriptif, ex. `best_run_exit_audit_trades`
- Mise à jour doc : §0.C dans `FEATURE-EXPORT-LLM-REPORT.md` + liste des checks

### Modifier l'endpoint

- Fichier : `backend/app/main.py` — fonction `export_algo_llm_endpoint` (~ligne 4075)
- Règle **invariant** : `_rcs` (report_consistency_status) doit être calculé **AVANT** l'appel à `build_export_llm_prompt`
- Utiliser `"_var" in locals()` (jamais `dir()`) pour tester l'existence de variables locales
- Un seul appel à `_parse_metrics_json_with_log` par endpoint — stocker dans `_best_metrics_for_prompt`

---

## PHASE 4 — Tests (OBLIGATOIRES)

### Fichiers de tests v0.52.0+

| Fichier | Contenu |
|---------|---------|
| `backend/tests/algo/test_export_llm_v052.py` | PR1 : smoke tests, sections présentes |
| `backend/tests/algo/test_export_llm_v052_pr2.py` | PR2 : RCS, s0c, caveats_detector |
| `backend/tests/algo/test_export_llm_v052_pr3.py` | PR3 : VETO TABLE avec métriques réelles |
| `backend/tests/algo/test_export_llm_v052_pr4.py` | PR4 : agrégats enrichis, held-fixed, 5.B split |
| `backend/tests/algo/test_export_llm_prompt_snapshot.py` | Snapshots golden files |
| `backend/tests/algo/test_export_llm_veto_unit.py` | Unité VETO engine pur |
| `backend/tests/algo/test_report_consistency_v051.py` | Unité RCS checks |

### Règles :
- Tout nouveau comportement → au moins 1 test unitaire dans le fichier PR correspondant
- Tout champ dans `PromptContext` → couverture dans les tests (pas de champ mort non testé)
- Modules purs (`builder.py`, `context.py`, `veto/engine.py`) → coverage 100% obligatoire (cf. `.claude/rules/tests.md`)
- Ne pas modifier les snapshots sans raison — si `PROMPT_VERSION` change, régénérer avec `UPDATE_SNAPSHOTS=1 pytest`

### Commande de test rapide :

```bash
source .venv/bin/activate
cd backend
pytest tests/algo/test_export_llm_v052.py \
       tests/algo/test_export_llm_v052_pr2.py \
       tests/algo/test_export_llm_v052_pr3.py \
       tests/algo/test_export_llm_v052_pr4.py \
       tests/algo/test_export_llm_prompt_snapshot.py \
       tests/algo/test_export_llm_veto_unit.py \
       tests/algo/test_report_consistency_v051.py -q
```

---

## PHASE 5 — Documentation (OBLIGATOIRE)

Mettre à jour `docs/reference/FEATURE-EXPORT-LLM-REPORT.md` :

| Section | Quand la mettre à jour |
|---------|----------------------|
| §4 Structure du prompt | Ajout/suppression/renommage de section |
| §5 Sections en détail | Changement de contenu d'une section |
| §6 Fichiers concernés | Nouveau fichier créé ou supprimé |
| §7 Versionnement | À chaque bump de version |
| §7 Changelog | À chaque modification (entrée concise, date ISO) |
| §8 Erreurs & cas-limites | Nouveau comportement edge-case documenté |

---

## PHASE 6 — Checklist finale avant commit

> ⚠️ **La première case est BLOQUANTE** — si elle n'est pas cochée, ne pas committer.

```
[ ] ★ PROMPT_VERSION bumpé dans wording.py (vérifié par `git diff wording.py`)
[ ] PROMPT_VERSION à jour dans FEATURE-EXPORT-LLM-REPORT.md (Last Updated + Prompt version + § Versionnement + Changelog)
[ ] Nouvelle entrée Changelog ajoutée (date ISO + résumé concis du changement)
[ ] Snapshots régénérés si nécessaire (UPDATE_SNAPSHOTS=1) — nouvelle version visible dans le snapshot
[ ] Tous les tests passent (commande Phase 4)
[ ] Aucune donnée mock / fallback introduite (invariant #7)
[ ] _rcs calculé AVANT build_export_llm_prompt si main.py modifié
[ ] Sections avec input optionnel retournent "" (pas d'exception ni de placeholder)
[ ] Nouveaux champs PromptContext ont un test de couverture
[ ] /commit exécuté (lint + format + push)
```

**Garde-fou anti-oubli** : si une review LLM externe est itérée plusieurs fois sur la même feature, chaque itération qui change le rendu = **un bump dédié** (v0.X.N → v0.X.N+1 → v0.X.N+2). Ne JAMAIS « absorber » silencieusement un correctif dans la version précédente sous prétexte qu'il s'agit du même ticket logique.

---

---

## PHASE 7 — Angles morts (pièges courants)

### 1. `PromptContext` est un `@dataclass(frozen=True, slots=True)`

Toute modification de `context.py` doit respecter deux contraintes :
- **Toujours fournir une valeur par défaut** (`= None`, `= field(default_factory=list)`, etc.) pour les nouveaux champs — sinon tous les sites qui construisent `PromptContext(...)` cassent.
- **Passer explicitement le champ dans `builder.py`** — s'il n'est pas dans l'appel `PromptContext(...)`, il reçoit `None` silencieusement (pas d'erreur, section vide sans avertissement).

### 2. Anti-pattern `or {}` sur le résultat de `_parse_metrics_json_with_log`

`_metrics_json.py` retourne **`None`** (pas `{}`) si `metrics_json` est absent ou invalide (politique NO-FALLBACK, ALGO-27147). Écrire `_parse_metrics_json_with_log(...) or {}` masque ce `None` et fait passer toutes les vérifications VETO silencieusement comme si les métriques étaient présentes. Toujours tester explicitement `if _best_metrics_for_prompt is not None:` avant d'utiliser la valeur.

### 3. Façade `export_llm_prompt.py` — rétrocompatibilité (25 sites d'import)

`backend/app/algo/export_llm_prompt.py` ré-exporte les symboles publics du sous-paquet `prompt/`. Si un symbole est renommé, déplacé ou supprimé dans le sous-paquet, mettre à jour la façade **avant** de modifier les sections — sinon les 25 sites d'import se cassent silencieusement (ImportError au runtime, pas à l'analyse statique).

### 4. Snapshot tests — quand régénérer (et quand ne PAS le faire)

Les snapshots dans `backend/tests/algo/snapshots/` (3 fichiers `.md`) sont des golden files byte-pour-byte.

- **Régénérer obligatoirement** si `PROMPT_VERSION` change ou si la structure du header change.
- **Ne PAS régénérer** si les tests snapshot échouent à cause d'un bug — corriger le bug d'abord, puis régénérer.
- Commande : `UPDATE_SNAPSHOTS=1 pytest tests/algo/test_export_llm_prompt_snapshot.py -q`
- Note : les snapshots utilisent des fixtures sans objectifs réels (VETO TABLE non testée). Ne pas les utiliser comme preuve que le VETO TABLE fonctionne.

### 5. `build_export_llm_prompt` est une **fonction pure** — zéro I/O

Ni `builder.py`, ni les sections dans `sections/`, ni `veto/engine.py` ne doivent faire d'I/O (pas de lecture fichier, pas d'appel DB, pas d'import de `main.py` ou de `storage.py`). Tout input doit transiter par `PromptContext`. Si une nouvelle section a besoin de données, les fetcher dans `main.py` et les passer en paramètre à `build_export_llm_prompt`.

### 6. Déterminisme des sections

Les fonctions `render(ctx)` de chaque section doivent être **déterministes** : mêmes inputs → même output. Exception autorisée : `s0_header.py` utilise `datetime.now(UTC)` pour l'horodatage — les snapshots normalisent ce timestamp. Ne pas introduire `uuid4()`, `random`, ou `time.time()` dans d'autres sections.

### 7. `inject_banner_after_header` est fragile aux changements du header

`report_consistency.inject_banner_after_header` injecte le banner FAIL par regex après le premier `---` du prompt. Si le format du header change (nouveau séparateur, titre différent), le banner peut ne pas s'insérer ou s'insérer au mauvais endroit. Tester le banner après tout changement de `s0_header.py`.

### 8. Feature flags pour les sections optionnelles

Les sections qui dépendent d'une feature flag doivent vérifier le flag dans leur fonction `render` (ou retourner `""` si le contexte est absent). Ne jamais lever d'exception pour une section optionnelle non disponible. Référence : `.claude/rules/feature-flags.md` pour la liste des flags.

### 9. Budget de tokens LLM

Le prompt est consommé par un LLM externe avec une fenêtre de contexte limitée. Les sections qui peuvent produire de larges outputs (§3.D code source, §3.G heatmap, code de stratégie) doivent avoir une logique de troncature ou de résumé. Ne pas ajouter de données brutes illimitées.

### 10. `wording.py` comme source de vérité des chaînes

Les chaînes de texte réutilisées (titres de sections, labels, messages d'erreur) doivent vivre dans `wording.py`, pas être dupliquées inline dans chaque section. Évite les divergences entre la documentation et le rendu réel.

### 11. Isolation des tests

Les tests unitaires (`test_export_llm_v052*.py`) ne doivent **pas** toucher la base SQLite ni le filesystem — fixtures synthétiques uniquement. Si un test a besoin de données réelles, l'isoler dans un test d'intégration marqué `@pytest.mark.slow`.

### 12. `locals()` jamais `dir()` dans `main.py`

`"_var" in dir()` ne teste pas les variables locales — il teste l'espace de noms de l'objet courant. Toujours utiliser `"_var" in locals()`. Bug introduit dans des versions antérieures, corrigé en v0.52.0 — ne pas le réintroduire.

---

## Références rapides

- Doc feature : `docs/reference/FEATURE-EXPORT-LLM-REPORT.md`
- Assembleur : `backend/app/algo/prompt/builder.py`
- Contexte : `backend/app/algo/prompt/context.py`
- Registre : `backend/app/algo/prompt/registry.py`
- Wording / version : `backend/app/algo/prompt/wording.py`
- Sections : `backend/app/algo/prompt/sections/`
- VETO engine : `backend/app/algo/prompt/veto/engine.py`
- VETO render : `backend/app/algo/prompt/veto/tables.py`
- RCS : `backend/app/algo/report_consistency.py`
- Section §0.C : `backend/app/algo/prompt/sections/s0c_report_consistency.py`
- Parser metrics_json : `backend/app/algo/prompt/_metrics_json.py`
- Endpoint : `backend/app/main.py` (~ligne 4075, `export_algo_llm_endpoint`)
- Tests : `backend/tests/algo/test_export_llm_v052*.py`
- Règles tests : `.claude/rules/tests.md`
- Contraintes archi : `CLAUDE.md` §Architecture invariants (7 règles)
