---
name: update-strategy
description: Update an explicitly selected AIMOTO strategy across registered families with version bump, descriptor validation,
  tests, and validation-grid handoff. Requires an explicit strategy target; never infer silently from previous context.
---

# /update-strategy — Mise à jour générique d'une stratégie

## Mission

Appliquer une mise à jour cohérente de **n'importe quelle stratégie enregistrée**
(bar, bar_artefact, mmxm, silver_bullet) en suivant le workflow universel
décrit ici, puis en délégant les étapes spécifiques à l'adapter de famille.

Si `$ARGUMENTS` identifie une stratégie (ex : `strategy=wma_dual_slope`,
`strategy=mmxm`, `strategy=silver_bullet`), résoudre cette stratégie en
PHASE -2. Si `$ARGUMENTS` ne précise pas la stratégie et que le contexte
est MMXM, appliquer l'adapter MMXM uniquement après résolution explicite du profil. Dans tous les cas, demander
les détails manquants avant de commencer.

---

## PHASE -2 — Résolution du profil et routage vers l'adapter (OBLIGATOIRE, PREMIÈRE)

### Étapes

1. **Identifier la stratégie cible** depuis `$ARGUMENTS` (clé `strategy=<nom>`)
   ou depuis le contexte courant. Toute stratégie cible doit être explicitement fournie ou confirmée par l'utilisateur avant exécution.
   Si ambigu, demander à l'utilisateur.

2. **Charger le profil** depuis `.claude/strategy-profiles/<strategy_key>.md`.
   Profils disponibles :

   | Profil | Famille | Adapter |
   |---|---|---|
   | `mmxm.md` | `mmxm` (SMC) | → §ADAPTER-MMXM |
   | `silver_bullet.md` | `silver_bullet` (SMC) | → §ADAPTER-SMC-NON-MMXM |
   | `forecast_signal_driven_long_only.md` | `bar_artefact` | → §ADAPTER-BAR |
   | `wma_dual_slope.md` | `bar` | → §ADAPTER-BAR |
   | `market_regime_search_price_above_ma100.md` | `bar` | → §ADAPTER-BAR |

3. **Vérifier le descriptor** dans le catalogue :
   ```python
   from app.algo.catalogue import STRATEGY_CATALOG
   d = STRATEGY_CATALOG.resolve("<strategy_name>")
   # Confirme : d.family, d.engine_type, d.grid_searchable, d.supported_objectives
   ```
   Si `UnknownStrategyError` → arrêter et signaler.

4. **Lancer le preflight générique** :
   ```bash
   source .venv/bin/activate && cd backend && python -c "
   import app.algo._catalogue_bootstrap
   from app.algo.strategy_update_preflight import run_preflight
   r = run_preflight('<strategy_name>', '<current_version>', '<target_version>')
   print('ok:', r.ok, '| warnings:', r.warnings)
   "
   ```
   Si `VersionBumpRequired` → **ABORT**. Résoudre la version cible d'abord.
   Si `descriptor_found=False` → **ABORT**. Enregistrer la stratégie dans `_catalogue_bootstrap.py` d'abord.

5. **Router vers l'adapter** selon la famille résolue :
   - `family == "mmxm"` → exécuter **§ADAPTER-MMXM** (PHASE -1 à PHASE 6)
   - `family in ("bar", "bar_artefact")` → exécuter **§ADAPTER-BAR**
   - `family == "silver_bullet"` → exécuter **§ADAPTER-SMC-NON-MMXM**

---

## Invariants universels (s'appliquent à TOUTES les familles)

Ces invariants ne peuvent pas être contournés, quelle que soit la famille :

| Invariant | Vérification | Blocage si absent |
|---|---|---|
| Bump de version | `target_version != current_version` | Oui — preflight bloque |
| Héritage des objectifs | `strategy_objectives: true` dans profil | Oui — étape obligatoire |
| Tests ciblés | Commandes `test_commands.targeted` du profil | Oui — ne pas déclarer terminé avant |
| Grid de validation | Proposition dans le résumé final | Oui — sortie structurée requise |
| Trace AIMIA | `aimia_closure: true` dans profil | Oui si applicable |

---

---

## ══ ADAPTER MMXM — SMC family=mmxm ══

> Exécuter cette section uniquement si PHASE -2 a résolu `family == "mmxm"`.
> Toutes les PHASEs ci-dessous (-1 à 6) sont spécifiques à MMXMStrategy.

---

## Statut d'implémentation des PHASEs (audit `2026-05-30`)

Toutes les PHASEs référencées par ce slash sont **implémentées et opérationnelles** dans la base de code :

| PHASE | Sujet | Statut | Évidence |
| --- | --- | --- | --- |
| -1 | Circuit Breaker pre-flight | ✅ | [`scripts/check_circuit_breaker.py`](../../scripts/check_circuit_breaker.py) |
| 0 | Lecture contexte (mmxm.py, registry, etc.) | ✅ | code source à jour |
| 0.5 | Inheritance `strategy_objectives` | ✅ | [`scripts/inherit_strategy_objectives.py`](../../scripts/inherit_strategy_objectives.py) + colonne `default_target_kpi` (migration appliquée) |
| 0.6 | Mono-causal patch flag | ✅ | `PROMPT_RULE_S6_MONO_CAUSAL_ENABLED` (default `False`) — [`backend/app/algo/config/feature_flags.py:31`](../../backend/app/algo/config/feature_flags.py) ; whitelist + détecteur dans `prompt/sections/s6_decision_rules.py:35,99` |
| 0.7 | AIMIA recommendation status | ✅ | module `backend/app/algo/aimia/` + table `aimia_recommendation_status` |
| 0.8 | Cohort funnel breakdown | ✅ | section `s3c_cohort_funnel.py` + champ optionnel `cohort_funnel_breakdown` (`llm_report_schema.py:285`) |

> ⚠️ Les sections « Problème historique » disséminées dans le slash décrivent
> des incidents passés et leur résolution. Elles ne sont **pas** des TODO en
> attente. Consulter le tableau ci-dessus avant de réintroduire un correctif
> déjà en place.

---

## PHASE -1 — Gate Circuit Breaker (OBLIGATOIRE, AVANT TOUTE MODIFICATION)

SPEC P9 (`docs/specs/2026-05-22__algo__circuit-breaker-v2-anti-loop/P9-SPEC.md`) Étape 8.

**Avant toute modification de la stratégie**, exécuter le pre-flight gate qui lit le `convergence_log` et bloque l'application si le Circuit Breaker (v1 ou v2) est triggered :

```bash
.venv/bin/python scripts/check_circuit_breaker.py --strategy mmxm --asset BTC-USD
```

- **Exit code 0** : verdict non-triggered OU log absent → PROCÉDER avec la mise à jour.
- **Exit code 1** : verdict triggered → **ABORT**. Lire `pivot_instruction` (stdout) et appliquer la consigne avant de relancer.
- **Exit code 2** : erreur technique → corriger avant de procéder.

### Bypass explicite (réservé aux cas exceptionnels)

Si l'utilisateur demande explicitement à passer outre (ex : reset volontaire après pivot) :

```bash
.venv/bin/python scripts/check_circuit_breaker.py --strategy mmxm --asset BTC-USD --force-circuit-breaker
```

Le bypass émet un structlog event `update_strategy.force_circuit_breaker` et requiert que l'utilisateur confirme explicitement (jamais en silence).

---

## PHASE 0 — Chargement du contexte (OBLIGATOIRE, lire avant tout)

Lire ces fichiers dans l'ordre :

1. `backend/app/algo/smc/mmxm.py` — constants block + `MmxmParams` dataclass + `MMXMStrategy`
2. `backend/app/algo/smc/tunable_registry.py` — `MMXM_TUNABLE_VARS`, `REGISTRY_META`, `MMXM_HARD_FLOORS`
3. `backend/tests/algo/smc/conftest.py` — autouse fixtures qui patchent des constantes globalement
4. `backend/tests/algo/smc/test_mmxm_params.py` — snapshots et sentinel field count
5. `backend/tests/algo/smc/test_mmxm_strategy.py` — `_force_h1_entries_legacy` autouse fixture

---

## PHASE 0.5 — Persister le rapport LLM (JSON_BLOCK → API)

SPEC `docs/specs/2026-05-18__algo__grid-search-evolution-tracking/SPEC.md` Étape 9.

Si `$ARGUMENTS` (ou la réponse LLM courante) contient un bloc ```json fenced
conforme au schéma `LlmReportPayload` v1 (cf. section 9 du prompt
`/api/algo/grid-searches/{id}/export-llm-prompt`), persister ce rapport via
l'API **avant** d'appliquer les patches code.

### Étapes

1. **Identifier la `grid_search_id`** ciblée — soit dans `$ARGUMENTS`
   (`grid_id=GRID-XXXXX`), soit dans le contexte récent (dernière grid
   complétée).
2. **Extraire** le dernier bloc ```json du message LLM (regex
   `r"```json\s*\n(.*?)\n\s*```"` en mode DOTALL, prendre la dernière
   occurrence).
3. **Valider** localement le JSON (clés du schéma `LlmReportPayload` v1 :
   `schema_version="1"`, `verdict ∈ {REJECT_ALL, ACCEPT_PARTIAL, PATCH_READY,
   RESEARCH_ONLY}`, `hypothesis_validated ∈ {validated, rejected, partial,
   inconclusive}`).
4. **POST** vers le backend :

   ```bash
   curl -X POST "http://localhost:8001/api/algo/grid-searches/${GRID_ID}/llm-reports" \
     -H 'Content-Type: application/json' \
     -d "$(jq -n --argjson p "$PAYLOAD_JSON" \
       '{payload: $p, source: "update_strategy_slash", raw_markdown: null}')"
   ```

   - `source` **DOIT** valoir `"update_strategy_slash"` (allow-list backend).
5. **Traitement des réponses** :
   - **201 Created** → rapport persisté, noter `llm_report_id` et `version`.
   - **409 DUPLICATE_REPORT** → idempotent : le rapport existe déjà
     (même `payload_hash`). Lire `existing.llm_report_id` + `existing.version`
     dans la réponse, **continuer** sans erreur — c'est le replay attendu.
   - **400 INVALID_LLM_REPORT_SCHEMA** → log les `details[]`, NE PAS
     continuer le slash. Demander à l'utilisateur de régénérer le bloc JSON.
   - **404 GRID_NOT_FOUND** → vérifier `grid_search_id`.
   - **Connection refused** → vérifier que le backend tourne sur `8001`
     (`./scripts/dev.sh` ou alias `aimoto-backend`). Continuer le slash en
     mode dégradé (warning à l'utilisateur, pas de blocage des PHASES 1+).
6. **Aucune autre modification** ne dépend de cette persistance : continuer
   PHASES 1+ même si elle a échoué en mode dégradé. La trace doit néanmoins
   être visible dans le résumé final (PHASE 6).

### ⚠️ Ne PAS générer `cohort_summary` ni `grid_spec_signature` (enrichissement backend)

Le contrat LLM (§9 du prompt) reste strictement `LlmReportPayload` v1 — 10
clés maximum, `extra="forbid"` côté backend. **Ne jamais** tenter d'ajouter
manuellement `cohort_summary` ou `grid_spec_signature` au JSON envoyé : ces
deux blocs sont calculés **déterministiquement** par le backend dans
`app.algo.llm_report_enrichment.enrich_payload` au moment du POST, puis
sérialisés dans la colonne `payload_json` aux côtés des champs LLM. Le
`payload_hash` (idempotence C-006) reste calculé sur le payload LLM brut,
indépendant de l'enrichissement.

Phase A (actuelle) : ces deux blocs sont remplis à `null` ; Phase B
(prochaine SPEC dédiée) implémentera l'agrégation cohorte + spec_hash.
La lecture frontend (`PersistedLlmReportPayload`) tolère leur absence.

### Bypass

Si `$ARGUMENTS` contient `--skip-llm-report`, sauter PHASE 0.5 et émettre
un warning explicite dans le résumé PHASE 6.

---

## PHASE 0.6 — Résolution de `STRATEGY_VERSION` cible (OBLIGATOIRE)

**Problème historique** : avant cette phase, le slash gardait silencieusement
`STRATEGY_VERSION` inchangé si l'utilisateur ne précisait pas explicitement
`version=X.Y.Z` dans `$ARGUMENTS`. Conséquence : un patch était appliqué sans
bump, désynchronisant le rapport LLM (qui affichait `plan pour vX.(Y+1).0`
calculé par `_next_minor_ver` dans `backend/app/main.py`) et le code réel
(qui restait sur `vX.Y.0`).

Cette phase résout `target_version` selon une hiérarchie **stricte** et
**unique**, et **abort si le résultat est égal à la version courante**
(empêchant un patch sans bump silencieux).

### ⚠️ Anti-interprétation (lire avant la hiérarchie)

Le bump minor de `STRATEGY_VERSION` est **systématique à chaque cycle**, peu importe le verdict du rapport LLM. Cette application est **single-user, single-environment** (pas de prod externe) : `STRATEGY_VERSION` ici joue le rôle de **compteur d'itération de recherche**, pas de "version déployée".

**Ne JAMAIS interpréter les marqueurs suivants comme "ne pas bumper"** :
- `verdict: REJECT_ALL` dans le JSON_BLOCK → trace que la cohorte n'a produit aucun candidat ACCEPT. **Bump quand même** (l'itération a eu lieu).
- `NO_PATCH_DEFAULT_FROM_THIS_REPORT` dans §7 → interdit de patcher des constantes stratégie. **N'interdit PAS le bump version**.
- `STRATEGY_VERSION: KEEP_UNCHANGED_AS_LEVER` dans §6 → interdit d'utiliser `STRATEGY_VERSION` comme **levier d'optimisation** (i.e. faire semblant qu'un bump est un fix). **Le rapport autorise explicitement le "bump technique possible hors optimisation".**
- `RELEASE_METADATA` taxonomy → idem, classifie la nature du champ, pas le droit de bumper.

**Conséquence opérationnelle** : sur un cycle `REJECT_ALL`, le slash doit :
- ❌ Ne pas modifier la moindre constante stratégie (sauf `STRATEGY_VERSION`).
- ✅ Bumper `STRATEGY_VERSION` minor (`0.68.0` → `0.69.0`) pour marquer la frontière d'itération.
- ✅ Ajouter une entrée `CHANGELOG-mmxm.md` du type : `v0.69.0 — iteration boundary, cohort 0.68.0 REJECT_ALL, no parameter patch, next grid candidates: <liste>`.
- ✅ Persister le rapport via PHASE 0.5 (audit trail du verdict).

Le **diff code de ce cycle = uniquement** le bump version + l'entrée changelog. Aucun test d'assertion sur les valeurs des constantes ne doit changer.

### Source de vérité — hiérarchie de priorité

Évaluer dans cet ordre, **prendre la première valeur non-vide** :

1. **`$ARGUMENTS` contient `version=X.Y.Z`** (override manuel explicite) →
   `target_version = "X.Y.Z"` (sans préfixe `v`). C'est le contrôle utilisateur
   le plus fort, surcharge tout le reste.
2. **PHASE 0.5 a extrait un `payload.target_version`** depuis le bloc
   ```json``` du LLM (canal recommandé) → `target_version = payload.target_version`
   (strip `v` préfixe). Le LLM choisit normalement le `next_version` injecté
   dans le prompt (`_next_minor_ver(strategy_version)`), mais peut diverger
   (ex : patch `.1` au lieu de minor `.0` si verdict `ACCEPT_PARTIAL`).
3. **Absence de version cible explicite** → **STOP** : demander `target_version` ou un payload LLM contenant `target_version`.
   bump minor automatique, idem au comportement backend. Calculer en lisant
   `STRATEGY_VERSION` dans `backend/app/algo/smc/mmxm.py` puis appliquer
   `+1` sur le minor + reset patch à `0`.

### Gate anti no-op

Après résolution, **comparer** `target_version` à `STRATEGY_VERSION` courant
(strip `v` des deux côtés).

- Si **identiques** → **ABORT** le slash avec ce message :
  ```
  ❌ PHASE 0.6 — STRATEGY_VERSION cible identique à la courante (vX.Y.Z).
  Un patch sans bump corromprait la traçabilité. Choisis explicitement :
    /update-strategy "version=X.Y.Z+1, <reste des args>"
  Ou laisse vide pour bump auto minor (+1).
  ```
- Si **différents** → enregistrer `TARGET_VERSION` pour les PHASES 3a / 3e
  (cocher l'item « Mettre à jour `STRATEGY_VERSION` » avec cette valeur).

### Bypass

Si `$ARGUMENTS` contient `--allow-no-bump`, sauter la gate anti no-op
(cas exceptionnel : reset volontaire ou rejeu test). Émettre un warning
explicite dans le résumé PHASE 6.

### Trace dans PHASE 6

Le résumé final doit indiquer la source retenue :
```
STRATEGY_VERSION : v0.68.0 → v0.69.0 (source: llm_report.target_version)
```
Valeurs possibles pour `source` : `arguments_override` | `llm_report.target_version`. Si aucune source explicite n'est disponible, arrêter l'exécution.

---

## PHASE 0.7 — Héritage des objectifs de stratégie (OBLIGATOIRE)

**Problème historique (incident 2026-05-29)** : avant cette phase, le slash bumpait `STRATEGY_VERSION` (PHASE 0.6) mais n'écrivait **jamais** dans la table `strategy_objectives` pour la nouvelle version. Conséquence : les 8 versions `v0.69.0` → `v0.75.0` ont tourné **sans aucune row d'objectifs**, donc :

- `Storage.get_strategy_objectives(MMXMStrategy, vX.Y.0)` → `None` silencieux.
- Lecteurs (`_portfolio.build_item`, `resolve_effective_target_kpi`, `llm_report_enrichment._compute_veto_pass_rate`) → fallback silencieux vers défauts globaux ou aucun VETO actif.
- Section §KPI_TARGETS du prompt LLM → vide ou par défaut → le LLM **optimise à l'aveugle** vers une cible inconnue → stagnation observée (5 cycles avec Jaccard overlap ≥ 0.8 sur les `next_grid_candidates`).

Cette phase garantit qu'à chaque bump, la row d'objectifs est copiée depuis la version précédente, avec préservation totale si une row existe déjà pour la nouvelle version (INSERT OR IGNORE).

### Exécution

Après PHASE 0.6 (TARGET_VERSION résolu et différent de STRATEGY_VERSION courant), exécuter :

```bash
.venv/bin/python scripts/inherit_strategy_objectives.py \
  --name MMXMStrategy \
  --from <STRATEGY_VERSION_courant_strip_v> \
  --to <TARGET_VERSION_strip_v>
```

Exemple concret pour `v0.68.0 → v0.69.0` :

```bash
.venv/bin/python scripts/inherit_strategy_objectives.py \
  --name MMXMStrategy --from 0.68.0 --to 0.69.0
```

### Sémantique attendue

- **`[inherit-objectives] copied objectives MMXMStrategy 0.68.0 -> 0.69.0`** → nouvelle row créée par héritage. ✅ continuer.
- **`[inherit-objectives] objectives already exist for to_version; skip`** → l'utilisateur a customisé manuellement les objectifs de la cible avant le slash. ✅ continuer (zéro écrasement par design — `INSERT OR IGNORE`).
- **`[inherit-objectives] no source objectives found; no-op`** → première version de la stratégie. ⚠ avertir l'utilisateur dans PHASE 6 ("aucun objectif hérité — pense à les définir manuellement via `/algo/strategies`") mais ne PAS bloquer.

### Garde-fou anti-écrasement

`Storage.inherit_strategy_objectives` utilise `INSERT OR IGNORE` : si une row existe déjà pour `to_version`, elle est **strictement préservée** (l'utilisateur peut donc pré-customiser les objectifs avant le slash sans risque). Le slash ne doit **JAMAIS** utiliser `upsert_strategy_objectives` à la place — ce serait destructif.

### Bypass

Si `$ARGUMENTS` contient `--skip-inherit-objectives`, sauter PHASE 0.7 et émettre un warning explicite dans PHASE 6. À réserver aux cas exceptionnels (test de régression du slash, première version d'une stratégie créée à la main).

### Trace dans PHASE 6

Le résumé final doit inclure :

```
Objectifs hérités : MMXMStrategy v0.68.0 → v0.69.0 (status: copied | skipped_already_exists | no_source)
```

---

## PHASE 0.8 — AIMIA Apply Plan : pré-calcul + persistance des recommandations PENDING (OBLIGATOIRE)

SPEC `docs/specs/2026-05-29__algo__aimia-apply-plan/SPEC.md` (Étape 3 du plan d'intégration).

**Problème historique** : avant cette phase, les recommandations VETO issues de l'historique (`Storage.compute_strategy_evolution_summary`) étaient :

- Re-scorées **à la volée** dans le rapport LLM (donc invisibles côté DB),
- Aucun mécanisme de **budget** (queue → 1 reco par cycle, sans tenir compte du flux entrant),
- Aucun **marquage PENDING / APPLIED / OBSOLETE** persistant → impossible de tracer le couple « recommandation proposée par AIMIA » ↔ « patch effectif du slash ».

Cette phase appelle l'endpoint backend qui **persiste** le plan d'application (table `aimia_recommendation_status`) **avant** d'appliquer les patches code de PHASE 3. Les lignes deviennent :

- `selected[]` → marquées **PENDING** dans la DB (priority_score figé, hash de valeur canonique),
- `pruned_obsolete[]` → marquées **OBSOLETE** (raison: `age_cycles=N > max_age=10`).

### Exécution

Après PHASE 0.7 (objectifs hérités), avant PHASE 1, appeler :

```bash
curl -sS "http://localhost:8001/api/algo/strategies/MMXMStrategy/aimia-apply-plan?strategy_version=${TARGET_VERSION}&limit=20&horizon=5&k_max=5" \
  | jq '{queue: .queue_size, budget: .computed_budget, incoming: .incoming_rate, selected: [.selected[] | {param, value: .recommended_value, score: .priority_score, status: .apply_status}], pruned: [.pruned_obsolete[] | {param, reason}]}'
```

### Sémantique

- **`computed_budget`** = `clamp(ceil(incoming_rate * horizon), 1, k_max)` où `incoming_rate` = moyenne du nombre de nouvelles recos par grid sur les 3 derniers cycles.
- **`selected[]`** = top-`computed_budget` candidats après `resolve_param_conflicts` (un seul candidat par param, le meilleur score gagne).
- **`pruned_obsolete[]`** = candidats survivants à `is_obsolete(age_cycles, max_age=10)` mais purgés. Persistés comme **OBSOLETE** (audit trail).
- L'endpoint est **idempotent** : appelable plusieurs fois sans changer le `payload_hash`. Les rows déjà `APPLIED` ou `PLANNED` voient leur `priority_score` re-calculé mais leur `apply_status` est **strictement préservé** par l'UPSERT (cf. `storage.upsert_recommendation_status`).

### Traitement des réponses

- **200 OK** → log les paramètres extraits (`selected[]`) dans le résumé PHASE 6. Ces recos sont les **candidats prioritaires** pour le patch de PHASE 3 — l'opérateur (humain ou LLM) doit les considérer en priorité.
- **400 INVALID_LIMIT / INVALID_HORIZON / INVALID_K_MAX** → corriger les paramètres de l'appel.
- **404** → vérifier `strategy_name` (MMXMStrategy par défaut).
- **Connection refused** → vérifier que le backend tourne sur `8001`. Continuer le slash en mode dégradé (warning PHASE 6, pas de blocage de PHASE 1+).

### Articulation avec le rapport LLM (PHASE 0.5)

- **PHASE 0.5** persiste le **verdict LLM** (`LlmReportPayload v1`) — c'est l'output qualitatif d'un cycle d'analyse.
- **PHASE 0.8** persiste le **plan AIMIA** (recommandations historiques re-scorées + budget queue) — c'est l'output quantitatif basé sur l'agrégation multi-cycles.

Les deux artefacts sont **complémentaires** : un patch idéal applique des paramètres qui sont **à la fois** dans `selected[]` (AIMIA) **et** alignés avec le verdict LLM. Une divergence (param sélectionné par AIMIA mais ignoré par le LLM, ou inversement) doit apparaître dans le résumé PHASE 6 comme alerte.

### Bypass

Si `$ARGUMENTS` contient `--skip-aimia-apply-plan`, sauter PHASE 0.8 et émettre un warning explicite dans PHASE 6. À réserver aux cas exceptionnels (backend down, première version d'une stratégie sans historique, test de régression du slash).

### Trace dans PHASE 6

Le résumé final doit inclure :

```
AIMIA Apply Plan : queue=12 budget=3 incoming_rate=2.7
  selected[0] PENDING  lookback=50    score=+5.0 (chronic_veto+3, cross_val+1, age_decay-1)
  selected[1] PENDING  atr_mult=0.45  score=+4.0 (chronic_veto+3, recent_veto+2, conflict-2)
  selected[2] PENDING  vol_z=2.1      score=+3.0 (chronic_veto+3, age_decay-1)
  pruned_obsolete: 2 (rsi_threshold, ema_fast — age_cycles>10)
```

---

## PHASE 1 — Cartographie des fichiers

### Fichiers à modifier (toujours)

| Fichier | Rôle | Ce qu'on y change |
|---------|------|-------------------|
| `backend/app/algo/smc/mmxm.py` | Cœur stratégie | Constants, `MmxmParams` fields, `STRATEGY_VERSION`, logique filtres |
| `backend/app/algo/smc/tunable_registry.py` | Grid search bounds | `MMXM_TUNABLE_VARS` (min/max/step/presets), `REGISTRY_META` |
| `backend/tests/algo/smc/test_mmxm_params.py` | Tests snapshot | Golden snapshot, field count, assertions sur valeurs par défaut |
| `backend/tests/algo/smc/test_mmxm_strategy.py` | Tests comportementaux | Assertions sur constantes, monkeypatches si nécessaire |
| `backend/tests/algo/smc/test_orchestrator_mmxm.py` | Tests découverte | `STRATEGY_VERSION` |
| `backend/tests/algo/smc/test_tunable_registry.py` | Tests registry | Comptage des vars, assertions REGISTRY_META |
| `backend/tests/test_api_grid_search.py` | Tests API | Comptage des tunable vars retournées |

### Fichiers à modifier (si nouveau filtre/gate)

| Fichier | Rôle | Ce qu'on y change |
|---------|------|-------------------|
| `backend/app/algo/smc/funnel_diagnostics.py` | Compteurs rejets | Ajouter `rejects_pN_nom: int = 0` + entrée dans `to_dict()` |
| `backend/app/algo/smc/mmxm.py` | Logique filtre | Ajouter la gate `P{N}` dans `_try_emit_for_cycle` |

### Fichiers à modifier (si nouveau champ `MmxmParams` — non-exclu du hash)

| Fichier | Rôle | Ce qu'on y change |
|---------|------|-------------------|
| `backend/app/algo/analytics/engine_version.py` | Hash canonique | **Ne rien modifier ici** — seul `scripts/promote_engine_version.py` doit toucher `_GOLDEN_HASH_VERSION_MAP`. Si le nouveau champ doit être **exclu du hash** (runtime-tunable), l'ajouter à `_HASH_EXCLUDED_FIELDS` (justification obligatoire). |
| `scripts/promote_engine_version.py` *(à lancer)* | Promotion hash | Voir PHASE 3h — calculer le nouveau hash et lancer le script |
| `.claude/rules/engine-version.md` | Référence règles | Mettre à jour « Current canonical hash » + version |
| `backend/app/algo/smc/CHANGELOG-mmxm.md` | Historique | Ajouter l'entrée de version |

---

## PHASE 2 — Patterns clés (lire avant de coder)

### Pattern 1 — Sentinel `_DEFAULT` dans `MmxmParams`

Les champs de `MmxmParams` utilisent un sentinel `_DEFAULT` qui est résolu automatiquement depuis les constantes module dans `__post_init__` :

```python
# mmxm.py — constante module (ajouter dans le bon groupe P0..P10)
NOUVEAU_PARAM: Decimal = Decimal("0.50")   # ou int, bool

# MmxmParams dataclass — champ correspondant
nouveau_param: Any = _DEFAULT              # _DEFAULT résolu → mmxm.NOUVEAU_PARAM
```

**La résolution est automatique** : `__post_init__` cherche `mmxm.NOUVEAU_PARAM_UPPER` pour le champ `nouveau_param`. Pas besoin d'écrire la résolution manuellement.

**Ajouter un champ = incrémenter le sentinel de comptage :**
```python
# test_mmxm_params.py
def test_mmxm_params_dataclass_field_count() -> None:
    assert len(fields(MmxmParams)) == 31  # ← changer ce nombre
```

### Pattern 2 — Ajouter une tunable var

```python
# tunable_registry.py — dans MMXM_TUNABLE_VARS
"nouveau_param": TunableVar(
    key="nouveau_param",
    label="Nouveau Param",
    type="decimal",          # "decimal" | "int" | "bool"
    default=_d("0.50"),      # doit matcher MmxmParams().nouveau_param exactement
    min=_d("0.10"),
    max=_d("2.00"),
    step_default=_d("0.05"),
    presets={
        "quick":  {"min": _d("0.45"), "max": _d("0.55"), "step": _d("0.05")},
        "medium": {"min": _d("0.40"), "max": _d("0.60"), "step": _d("0.05")},
        "deep":   {"min": _d("0.35"), "max": _d("0.65"), "step": _d("0.05")},
    },
    description="Description courte",
    tags=["risk"],           # tags libres
),
```

`REGISTRY_META["n_tunable_vars_v1"]` = `len(MMXM_TUNABLE_VARS)` — **auto-calculé, ne pas toucher**.

### Pattern 3 — Ajouter un filtre/gate dans le funnel

Les gates sont dans `_try_emit_for_cycle` dans `mmxm.py`. Ordre actuel :
- P0 : account gate (FunnelFilter)
- P1 : KZ (Kill Zone)
- P2 : cycle cadence (min bars between entries)
- P3 : zone retest
- P4 : PDR (concordants)
- P5 : ATR entry filter ← dernière gate ajoutée (v0.17.0)
- RR check (final)

Pour ajouter un nouveau filtre P6 :
1. Ajouter `rejects_p6_nom: int = 0` dans `FunnelDiagnostics` + dans `to_dict()`
2. Ajouter la constante `REJECT_MMXM_NOM = "MMXM_NOM"` dans `mmxm.py`
3. Insérer la gate dans `_try_emit_for_cycle` après P5 :
```python
# --- P6 : description ---
if condition:
    ctx.funnel_diag.rejects_p6_nom += 1
    return False
```

---

## PHASE 3 — Checklist de mise à jour complète

Cocher chaque item au fur et à mesure. **Ne pas marquer terminé tant que les tests n'ont pas été lancés.**

### 3a — `backend/app/algo/smc/mmxm.py`
- [ ] Mettre à jour `STRATEGY_VERSION` → valeur `TARGET_VERSION` résolue en PHASE 0.6 (ne PAS inventer une autre valeur ici)
- [ ] Mettre à jour les constantes modifiées dans leur groupe (P0..P10)
- [ ] Ajouter les nouvelles constantes avec commentaire de groupe
- [ ] Ajouter les nouveaux champs dans `MmxmParams` (avec `_DEFAULT`)
- [ ] Ajouter la logique de filtre dans `_try_emit_for_cycle` si nouveau gate

### 3b — `backend/app/algo/smc/tunable_registry.py`
- [ ] Mettre à jour `default` de chaque var modifiée (doit matcher `MmxmParams().<field>` exactement)
- [ ] Mettre à jour `min`, `max`, `step_default` si les bornes changent
- [ ] Mettre à jour les `presets` (quick/medium/deep) en cohérence avec les nouvelles bornes
- [ ] Ajouter les nouvelles vars si besoin
- [ ] Mettre à jour `REGISTRY_META["last_calibrated_at"]` si recalibré
- [ ] Mettre à jour `REGISTRY_META["t_avg_seconds"]` si recalibré
- [ ] Mettre à jour `MMXM_HARD_FLOORS` si nouvelle contrainte dure

### 3c — `backend/tests/algo/smc/test_mmxm_params.py`
- [ ] `test_mmxm_params_default_construct_succeeds` — vérifier les valeurs par défaut des champs clés
- [ ] `test_mmxm_params_to_dict_decimal_as_str` — vérifier la sérialisation des champs Decimal/bool/int
- [ ] `test_mmxm_params_dataclass_field_count` — incrémenter si champ ajouté
- [ ] `test_mmxm_params_a95_baseline_snapshot` — **mettre à jour le golden snapshot complet**
  - ⚠️ `use_partial_tp` doit être `False` dans le snapshot (patché par conftest autouse)
  - ⚠️ `use_breakeven` doit être `False` dans le snapshot (patché par conftest autouse)
  - ⚠️ `use_outer_edge_entry` doit être `False` dans le snapshot (patché par conftest autouse)

> `test_mmxm_params_pydantic_migration.py` : itère sur `MmxmParams.model_fields`. Normalement robuste, mais si un nouveau champ a une validation type inhabituelle, vérifier manuellement après ajout.

### 3d — `backend/tests/algo/smc/test_mmxm_strategy.py`
- [ ] `test_rr_constants_within_spec_range` — vérifier les bornes RR
- [ ] `test_b1b_fix_constants_exposed` — vérifier les constantes exposées
- [ ] Tests utilisant des constantes modifiées — ajouter monkeypatch si nécessaire
- [ ] Vérifier que `_force_h1_entries_legacy` autouse est à jour :
  - Doit patcher `USE_M15_ENTRIES=False` (force H1, pas M15)
  - Doit patcher `ENTRY_ATR_MAX_PCT=Decimal("999.0")` (désactive ATR filter pour les barres legacy ~1%)

### 3e — `backend/tests/algo/smc/test_orchestrator_mmxm.py`
- [ ] `test_mmxm_version_is_v0_1_0_experimental` → mettre à jour la version attendue à `TARGET_VERSION` (PHASE 0.6)

### 3f — `backend/tests/algo/smc/test_tunable_registry.py`
- [ ] `test_registry_has_exactly_8_vars_v1` — mettre à jour le commentaire + le count `len(MMXM_TUNABLE_VARS)`
- [ ] `test_registry_meta_includes_calibration_metadata` — `n_tunable_vars_v1`, dates, hashes si changés
- [ ] Ajouter des tests `values_for_preset` pour les nouvelles vars si pertinent

### 3g — `backend/tests/test_api_grid_search.py`
- [ ] `test_get_tunable_vars_mmxm_returns_8_vars` — mettre à jour le count + ajouter les nouvelles clés dans `keys`

### 3h — Engine hash promotion (si champ non-exclu modifié/ajouté)

> **À ne faire qu'après** que `mmxm.py` et `tunable_registry.py` sont finalisés.

- [ ] Calculer le nouveau hash canonique :
  ```bash
  source .venv/bin/activate && cd backend
  python -c "from app.algo.analytics.engine_version import _canonical_engine_hash; print(_canonical_engine_hash())"
  ```
- [ ] Lancer la promotion (hash hex 64 chars, format `vX.Y.Z`) :
  ```bash
  source .venv/bin/activate
  python scripts/promote_engine_version.py <hash_hex_64> <vX.Y.Z>
  ```
  Le script modifie `_GOLDEN_HASH_VERSION_MAP` dans `engine_version.py` de façon atomique.
- [ ] Mettre à jour le « Current canonical hash » dans `.claude/rules/engine-version.md`
- [ ] Ajouter l'entrée dans `backend/app/algo/smc/CHANGELOG-mmxm.md`
- [ ] Vérifier que `tests/algo/analytics/test_engine_version_hash.py` passe (voir Phase 5)

> Si le champ est **exclu du hash** (runtime-tunable sans impact stratégie), l'ajouter à `_HASH_EXCLUDED_FIELDS` dans `engine_version.py` au lieu de promouvoir. Toute modification de `_HASH_EXCLUDED_FIELDS` est CI-blocking : justifier dans le commentaire et mettre à jour le tableau dans `.claude/rules/engine-version.md`.

---

## PHASE 3.5 — AIMIA closure : auto-mark PLANNED pour les recos appliquées (OBLIGATOIRE)

SPEC `docs/specs/2026-05-29__algo__aimia-apply-plan/SPEC.md` §Étape 6.

**Problème historique** : avant cette phase, le bouton "Apply" du frontend obligeait l'opérateur à marquer manuellement chaque reco AIMIA comme PLANNED. Conséquence : friction, recos qui restaient PENDING indéfiniment dans la DB, queue qui ne décroissait jamais visuellement → l'opérateur ne pouvait pas faire confiance au compteur.

**Nouvelle règle** : le bouton est supprimé. **C'est ce slash qui scelle la transition** PENDING → PLANNED, **automatiquement**, pour chaque (param, valeur) qui vient d'être patché en PHASE 3. Une fois marquées PLANNED, ces recos disparaissent du `selected[]` au prochain refresh de la section AimiaRecommendationSection (filtrage backend : `app/algo/aimia/plan.py` étape 5b).

### Exécution

Pour **chaque** `(param, recommended_value)` effectivement patché dans `backend/app/algo/smc/mmxm.py` (ou dans la `MmxmParams` dataclass) en PHASE 3 :

1. **Retrouver le `grid_search_id` source** : c'est celui listé dans la table `selected[]` de PHASE 0.8 pour ce param. Si le param ne figurait pas dans `selected[]` mais a quand même été patché (cas exceptionnel : décision LLM hors recommandation AIMIA), **sauter** ce param (rien à marquer).
2. **Calculer le `recommended_value_hash`** :
   - Soit le reprendre tel quel depuis la réponse PHASE 0.8 (champ `recommended_value_hash` de la ligne `selected[]` correspondante — c'est le plus sûr).
   - Soit recalculer localement avec `python -c "from app.algo.aimia.storage import canonical_value_hash; print(canonical_value_hash(<value>))"`.
3. **POST `/mark`** :

   ```bash
   curl -X POST "http://localhost:8001/api/algo/strategies/MMXMStrategy/aimia-apply-plan/mark" \
     -H 'Content-Type: application/json' \
     -d '{
       "grid_search_id": "<GRID-XXXXX>",
       "param": "<param_name>",
       "recommended_value_hash": "<sha1_canonical_hex>",
       "action": "PLANNED"
     }'
   ```

### Sémantique

- **PENDING → PLANNED** est idempotent côté storage : un second appel sur une row déjà PLANNED est un no-op silencieux. Pas de risque à appeler deux fois.
- **PLANNED → APPLIED** n'est PAS la responsabilité du slash. C'est le **worker grid-search** qui scelle cette transition la prochaine fois qu'un grid démarre avec `strategy_version = TARGET_VERSION` et que ses paramètres baseline matchent une row PLANNED (hook prévu, cf. SPEC §Étape 7 — TODO).

### Traitement des réponses

- **200 OK** → reco marquée PLANNED, loguée dans le résumé PHASE 6.
- **404 RECOMMENDATION_NOT_FOUND** → le `(grid_search_id, param, hash)` n'existe pas dans `aimia_recommendation_status`. **Skip silencieux** : cela arrive si la PHASE 0.8 a échoué en mode dégradé (backend down) — pas de blocage.
- **400** → log l'erreur et continuer. Le patch code est déjà appliqué ; l'audit AIMIA est dégradé mais non critique.
- **Connection refused** → mode dégradé (warning PHASE 6, pas de blocage).

### Bypass

Si `$ARGUMENTS` contient `--skip-aimia-closure`, sauter PHASE 3.5 et émettre un warning explicite dans PHASE 6. Utile uniquement pour le test du slash lui-même.

### Trace dans PHASE 6

Le résumé final doit inclure :

```
AIMIA closure : 3 reco marquées PLANNED
  - lookback=50          (GRID-00012, h=a1b2c3...)  PENDING → PLANNED
  - atr_mult=0.45        (GRID-00014, h=d4e5f6...)  PENDING → PLANNED
  - vol_z=2.1            (GRID-00011, h=78901a...)  already PLANNED (idempotent)
```

---

## PHASE 4 — Gotchas critiques

### G1 — conftest.py patche 3 constantes pour TOUS les tests SMC
```
backend/tests/algo/smc/conftest.py  ← autouse fixture
```
Les 3 constantes suivantes sont **toujours False** pendant tous les tests dans `tests/algo/smc/` :
- `USE_PARTIAL_TP = False`
- `USE_BREAKEVEN = False`
- `USE_OUTER_EDGE_ENTRY = False`

**Impact sur le golden snapshot :** `test_mmxm_params_a95_baseline_snapshot` doit utiliser `False` pour ces 3 champs, même si la valeur production est `True`.

### G2 — `_force_h1_entries_legacy` dans `test_mmxm_strategy.py`
Autouse fixture active pour TOUS les tests comportementaux dans ce fichier. Elle patche :
- `USE_M15_ENTRIES = False` → force entrées H1 uniquement
- `ENTRY_ATR_MAX_PCT = Decimal("999.0")` → désactive le filtre ATR

**Pourquoi ATR 999.0 ?** Les barres de test standard (`_bar(ts, 100_000, 100_500, 99_500, 100_000)`) ont un ATR% ≈ 1.0% (range 1000 pts / close 100_000), ce qui dépasse le seuil production de 0.50%. Sans ce patch, TOUTES les barres legacy seraient rejetées par le filtre ATR.

### G3 — RR_MAX=200 affecte les tests de seuil H4
Avec `RR_MAX=200.0`, une barre standard dans une zone bien construite peut atteindre RR≈200.
Si un test doit **forcer le rejet H4 via H4_RR_MIN**, il faut patcher `H4_RR_MIN` à une valeur **supérieure à RR_MAX** :
```python
monkeypatch.setattr(mmxm_mod, "H4_RR_MIN", Decimal("300.0"))  # > RR_MAX=200
```
⚠️ Ne pas utiliser `Decimal("5.0")` — la barre peut atteindre 5.0 facilement.

### G4 — `REQUIRE_ZONE_EXIT_BETWEEN_ENTRIES = False` en production
Si un test vérifie que la gate de sortie de zone bloque une 2e entrée, il faut la réactiver :
```python
monkeypatch.setattr(mmxm_mod, "REQUIRE_ZONE_EXIT_BETWEEN_ENTRIES", True)
```

### G5 — `MAX_TRADES_PER_D_CYCLE=6` en production
Un test qui veut que D soit "épuisé" après N trades doit patcher :
```python
monkeypatch.setattr(mmxm_mod, "MAX_TRADES_PER_D_CYCLE", 1)  # ou N voulu
```

### G6 — Cohérence `registry.default` vs `MmxmParams().<field>`
Le test `test_registry_defaults_match_mmxm_params` vérifie que chaque `var.default` dans `MMXM_TUNABLE_VARS` est **identique** à `MmxmParams().<field>`. Si les deux sont désynchronisés, ce test fail.
Toujours mettre à jour les deux en même temps.

---

## PHASE 5 — Lancer les tests

```bash
cd /Users/vincentdesbrosses/Documents/Misc/aimoto/backend
pytest tests/algo/smc/ tests/algo/analytics/test_engine_version_hash.py tests/test_api_grid_search.py -x --tb=short
```

> `tests/algo/analytics/test_engine_version_hash.py` est marqué `regression` — toujours sélectionné. Il vérifie que le hash courant de `MmxmParams()` est dans `_GOLDEN_HASH_VERSION_MAP`. Si ce test fail après une mise à jour, c'est que la promotion hash (Phase 3h) n'a pas été faite.

Si des tests échouent, corriger avant de conclure. Une mise à jour de stratégie non testée n'est pas terminée.

Pour un test isolé :
```bash
pytest tests/algo/smc/test_mmxm_params.py -x --tb=long
pytest tests/algo/smc/test_mmxm_strategy.py -x --tb=long -k "nom_du_test"
```

---

## PHASE 6 — Résumé final

Afficher :

```
## Mise à jour MMXM v{X.Y.Z} terminée

### Version bump
- STRATEGY_VERSION : v{ANCIEN} → v{X.Y.Z} (source: {arguments_override|llm_report.target_version})

### Constantes modifiées (mmxm.py)
- CONSTANTE : ancienne_valeur → nouvelle_valeur

### Champs MmxmParams ajoutés
- nom_champ : type, default

### Tunable vars modifiées (tunable_registry.py)
- nom_var : bounds et/ou presets mis à jour

### Tests mis à jour
- test_mmxm_params.py : snapshot v{X.Y.Z}, field_count={N}
- test_mmxm_strategy.py : {liste des tests touchés}
- test_orchestrator_mmxm.py : version → {X.Y.Z}
- test_tunable_registry.py : n_vars → {N}
- test_api_grid_search.py : count → {N}

### Vérification
- [ ] pytest 408 passed (ou N passed)
- [ ] Aucune régression
```

---

## ══ ADAPTER BAR — engine_type="bar", family="bar" ou "bar_artefact" ══

> Exécuter cette section si PHASE -2 a résolu `family in ("bar", "bar_artefact")`.
> Concerne : `wma_dual_slope`, `forecast_signal_driven_long_only`,
> `market_regime_search_price_above_ma100`.

---

### BAR PHASE 0 — Chargement du contexte

Lire dans l'ordre :

1. Le module de la stratégie (`strategy_module_path` du profil).
2. `params_class` si `pydantic_params: true` dans le profil.
3. Le fichier de tests actif (`test_commands.targeted` du profil).
4. Objectifs actuels si `strategy_objectives: true` :
   ```bash
   curl -s "http://localhost:8001/api/algo/strategies/<StrategyClassName>/<current_version>/objectives" | jq .
   ```

### BAR PHASE 0.5 — Rapport LLM (conditionnel)

Si `$ARGUMENTS` contient un bloc `json` conforme au schéma `LlmReportPayload v1` :
Persister via `POST /api/algo/grid-searches/{id}/llm-reports` (même mécanique que
MMXM PHASE 0.5) si la stratégie est liée à une grid.
Si aucun rapport LLM n'est applicable (stratégie sans grid search), sauter cette phase.

### BAR PHASE 0.6 — Résolution de la version cible (OBLIGATOIRE)

Même hiérarchie que MMXM : arguments explicites → payload LLM explicite. Si aucune version cible explicite n'est disponible, arrêter l'exécution.
**Règle anti-no-op** : la version cible doit différer de la version courante.
Vérifier avec :
```bash
source .venv/bin/activate && cd backend && python -c "
import app.algo._catalogue_bootstrap
from app.algo.strategy_update_preflight import check_version_bump
check_version_bump('<current>', '<target>')
print('Version bump OK')
"
```

### BAR PHASE 0.7 — Héritage des objectifs (OBLIGATOIRE si strategy_objectives:true)

```bash
.venv/bin/python scripts/inherit_strategy_objectives.py \
  --name <StrategyClassName> \
  --from <current_version_strip_v> \
  --to <target_version_strip_v>
```

Sémantique : identique à MMXM PHASE 0.7 (INSERT OR IGNORE, idempotent).

### BAR PHASE 1 — Cartographie des fichiers

| Fichier | Rôle | Ce qu'on y change |
|---|---|---|
| `<strategy_module_path>` | Cœur stratégie | `STRATEGY_VERSION`, constantes, `params_class` fields |
| `<tunable_registry_path>` (si `tunable_registry: true`) | Manifest tunables | Bounds, defaults, steps |
| Tests actifs du profil | Tests stratégie | Assertions sur version, params, comportements |

**Hors périmètre bar** : pas de `FunnelDiagnostics`, pas de circuit breaker, pas
de promotion engine hash (sauf si le profil déclare explicitement `engine_hash: true`).

### BAR PHASE 2 — Patterns clés

#### Pattern A — Bump de version bar (class attribute)

```python
# Dans le module stratégie
class MyStrategy(BaseStrategy):
    STRATEGY_VERSION = "1.4.6"   # ← remplacer la valeur précédente
```

#### Pattern B — Modifier les params Pydantic (si pydantic_params:true)

Ajouter ou modifier un champ dans `params_class`. Garder le `default`
du manifest synchronisé avec le défaut du `params_class`.

#### Pattern C — Modifier le manifest tunables (si tunable_registry:true)

Même structure que MMXM PHASE 2 Pattern 2, adapté au nom des vars.

### BAR PHASE 3 — Checklist de mise à jour

#### 3a — Module principal
- [ ] Bumper `STRATEGY_VERSION` à la valeur cible
- [ ] Modifier les constantes / paramètres demandés
- [ ] Ajouter les nouveaux champs `params_class` si nécessaire

#### 3b — Manifest tunables (si `tunable_registry: true`)
- [ ] Synchroniser `default` avec `params_class` défaut
- [ ] Mettre à jour `min`, `max`, `step` si les bornes changent
- [ ] Mettre à jour les presets (quick/medium/deep)

#### 3c — Tests
- [ ] Mettre à jour l'assertion de version dans le test actif
- [ ] Mettre à jour les assertions sur les valeurs par défaut
- [ ] Ajouter des tests pour tout nouveau comportement

### BAR PHASE 4 — Lancer les tests

```bash
cd /path/to/repo && source .venv/bin/activate && cd backend
# Utiliser test_commands.targeted du profil, ex :
pytest tests/algo/strategies/test_forecast_signal_driven_long_only.py -x --tb=short
```

Si des tests échouent, corriger avant de conclure.

### BAR PHASE 5 — Grid de validation (si la stratégie est grid_searchable)

Si `grid_searchable: true` (ex: `ForecastSignalDrivenLongOnly`,
`MarketRegimeSearchPriceAboveMA100`) et que la mise à jour concerne les params :

Proposer la prochaine grid de validation avec les bounds mises à jour.
Format de sortie (dans le résumé final) :
```
Grid de validation proposée :
  - strategy : <StrategyClassName>
  - params modifiés : <liste>
  - preset suggéré : quick | medium | deep
  - priorité : MMXM-analogue / exploratory
```

Si `grid_searchable: false` (ex: `WmaDualSlope`), la grid handoff est non applicable
— indiquer explicitement dans le résumé.

### BAR PHASE 6 — Résumé final

```
## Mise à jour <StrategyName> v{ANCIEN} → v{CIBLE} terminée

### Version bump
- STRATEGY_VERSION : v{ANCIEN} → v{CIBLE} (source: {arguments|llm_report|auto})

### Constantes / params modifiés
- <nom> : <ancienne_valeur> → <nouvelle_valeur>

### Objectifs hérités
- <StrategyClassName> : {copied|skipped_already_exists|no_source}

### Tests
- [ ] pytest N passed, 0 failed

### Grid de validation
- {proposition ou "non applicable (grid_searchable: false)"}
```

---

## ══ ADAPTER SMC non-MMXM — family="silver_bullet" ══

> Exécuter cette section si PHASE -2 a résolu `family == "silver_bullet"`.
> Concerne : `SilverBulletStrategy`.
> Ce workflow est plus léger que MMXM : pas de circuit breaker, pas de tunable
> registry, pas d'AIMIA, pas de promotion de hash engine.

---

### SMC-NM PHASE 0 — Chargement du contexte

Lire dans l'ordre :

1. `backend/app/algo/smc/silver_bullet.py` — constantes + `STRATEGY_VERSION` + `SilverBulletStrategy`
2. `backend/tests/algo/smc/test_silver_bullet.py` — assertions version et comportements
3. `backend/app/algo/smc/registry.py` — confirmer que `SilverBulletStrategy` est bien enregistrée

### SMC-NM PHASE 0.6 — Résolution de la version cible (OBLIGATOIRE)

Même hiérarchie que MMXM : arguments explicites → payload LLM explicite. Si aucune version cible explicite n'est disponible, arrêter l'exécution.
Anti-no-op : la version cible doit différer de la version courante.

```bash
source .venv/bin/activate && cd backend && python -c "
import app.algo._catalogue_bootstrap
from app.algo.strategy_update_preflight import check_version_bump
check_version_bump('<current>', '<target>')
print('Version bump OK')
"
```

### SMC-NM PHASE 0.7 — Héritage des objectifs (OBLIGATOIRE)

SilverBullet supporte les `strategy_objectives` (voir profil). Hériter pour la
version cible avant tout patch :

```bash
.venv/bin/python scripts/inherit_strategy_objectives.py \
  --name SilverBulletStrategy \
  --from <current_version_strip_v> \
  --to <target_version_strip_v>
```

### SMC-NM PHASE 1 — Cartographie des fichiers

| Fichier | Rôle | Ce qu'on y change |
|---|---|---|
| `backend/app/algo/smc/silver_bullet.py` | Cœur stratégie | `STRATEGY_VERSION`, constantes, logique |
| `backend/tests/algo/smc/test_silver_bullet.py` | Tests comportementaux | Assertions version et comportements |

**Hors périmètre silver_bullet** : pas de `MmxmParams`, pas de `tunable_registry`,
pas de `FunnelDiagnostics`, pas de circuit breaker, pas de promotion engine hash,
pas d'AIMIA plan/closure.

### SMC-NM PHASE 2 — Patterns clés

#### Pattern — Bump de version (module-level constant)

```python
# silver_bullet.py
STRATEGY_VERSION: str = "v1.1.0"   # ← remplacer la valeur précédente
```

#### Pattern — Modifier la logique SMC

Les modifications de logique (nouveau filtre, nouvelle gate, nouveau paramètre)
suivent les patterns SMC généraux. Ne pas copier les patterns MmxmParams
(sentinel `_DEFAULT`, `__post_init__`) — SilverBullet n'a pas cette architecture.

### SMC-NM PHASE 3 — Checklist de mise à jour

#### 3a — `backend/app/algo/smc/silver_bullet.py`
- [ ] Bumper `STRATEGY_VERSION` à la valeur cible
- [ ] Modifier les constantes demandées
- [ ] Ajouter la logique de nouveau filtre si applicable

#### 3b — `backend/tests/algo/smc/test_silver_bullet.py`
- [ ] Mettre à jour l'assertion sur `STRATEGY_VERSION`
- [ ] Ajouter les tests comportementaux pour les nouvelles gates
- [ ] Vérifier que les fixtures de test sont cohérentes avec les nouvelles constantes

### SMC-NM PHASE 4 — Lancer les tests

```bash
cd /path/to/repo && source .venv/bin/activate && cd backend
pytest tests/algo/smc/test_silver_bullet.py tests/test_algo_listing.py -x --tb=short
```

### SMC-NM PHASE 5 — Grid de validation

SilverBulletStrategy n'est pas grid_searchable (pas de tunable vars). La grid
handoff est non applicable. Indiquer dans le résumé : `grid_searchable: false`.

### SMC-NM PHASE 6 — Résumé final

```
## Mise à jour SilverBulletStrategy v{ANCIEN} → v{CIBLE} terminée

### Version bump
- STRATEGY_VERSION : v{ANCIEN} → v{CIBLE} (source: {arguments|llm_report|auto})

### Constantes modifiées (silver_bullet.py)
- <CONSTANTE> : <ancienne_valeur> → <nouvelle_valeur>

### Objectifs hérités
- SilverBulletStrategy : {copied|skipped_already_exists|no_source}

### Tests
- [ ] pytest N passed, 0 failed

### Grid de validation
- non applicable (grid_searchable: false)
```

---

## ══ PHASE POSTFLIGHT — Toutes familles ══

> Cette section s'exécute après l'adapter de famille, quelle que soit la famille.

### Checklist de conformité universelle

Avant de déclarer la mise à jour terminée, vérifier **chaque item** :

- [ ] **Version bumpée** : `target_version != current_version` (vérifié en PHASE -2)
- [ ] **Objectifs hérités** (si `strategy_objectives: true`) : script exécuté, résultat `copied | skipped_already_exists`
- [ ] **Tests passent** : commande `test_commands.targeted` du profil exécutée sans échec
- [ ] **Grid de validation** : proposition incluse dans le résumé final (ou "non applicable" justifié)
- [ ] **AIMIA trace** (si `aimia_closure: true`) : recos marquées PLANNED avant fin
- [ ] **Aucune autre stratégie modifiée** : vérifier `git status` — seuls les fichiers du profil actif

### Format du journal d'exécution (sortie structurée)

```
## Journal d'exécution — update-strategy

Stratégie : <strategy_name> (family=<famille>, engine=<engine>)
Version   : <current> → <target>
Adapter   : MMXM | BAR | SMC-NON-MMXM

| Étape | Résultat | Note |
|---|---|---|
| PHASE -2 : résolution profil | ✅ PASS | family=<famille> |
| PHASE -1 : circuit breaker | ✅/⏭️ | PASS ou skipped (feature disabled) |
| PHASE 0.6 : version cible | ✅ PASS | source=<source> |
| PHASE 0.7 : héritage objectifs | ✅ PASS | `copied` / `skipped` / `no_source` |
| PHASE 0.8 : AIMIA apply plan | ✅/⏭️ | PASS ou skipped |
| Adapter : edits code | ✅ PASS | N fichiers modifiés |
| Tests ciblés | ✅ PASS | N passed, 0 failed |
| Grid de validation | ✅/⏭️ | proposition ou non applicable |
| AIMIA closure | ✅/⏭️ | N recos PLANNED ou skipped |

Risques résiduels :
- <liste ou "aucun">
```
