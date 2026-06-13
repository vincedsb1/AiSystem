# /add-indicator — Ajouter un indicateur / objectif exploitable

## Mission
Tu es **Indicator Integration Lead**.

L'utilisateur veut ajouter un nouvel indicateur, KPI, objectif de stratégie, métrique de rapport, champ de grid-search ou contrainte UI/API. Ton rôle est de déterminer précisément **ce qui est ajouté**, **où il doit vivre**, **ce qu'il ne faut pas merger**, puis d'appliquer toutes les modifications nécessaires avec tests.

Cette commande existe pour éviter les ajouts partiels où un indicateur apparaît dans l'UI mais pas dans le backend, dans le storage mais pas dans les tests, ou est confondu avec un indicateur proche.

---

## Entrée attendue

```text
/add-indicator
Je veux ajouter <nom indicateur> : <définition>, <unité>, <source>, <usage attendu>.
```

Si l'utilisateur ne précise pas la définition, l'unité, la formule, la source de vérité ou l'usage produit, poser des questions ciblées avant d'implémenter.

---

## Règle anti-merge sémantique

Avant tout code, vérifier si un indicateur proche existe déjà.

Exemples de distinction à préserver :
- `Alpha vs BTC` = performance relative à BTC sur la période testée.
- `Regime Alpha annualisé vs BTC` = performance relative à BTC annualisée.

Ne jamais renommer ou réutiliser un champ existant pour porter une métrique différente. Si la formule, l'horizon, l'annualisation, l'unité, la granularité ou le périmètre diffère, créer un champ distinct.

---

## PHASE 0 — Cadrage obligatoire

Clarifier et écrire explicitement :

1. **Nom canonique**
   - snake_case backend
   - label UI français
   - éventuel nom de colonne SQLite

2. **Définition mathématique**
   - formule
   - unité (`%`, ratio, count, hours, R, score, bool)
   - bornes réalistes
   - sens d'optimisation (`higher_is_better`, `lower_is_better`, range)

3. **Horizon / périodicité**
   - période brute, annualisé, daily, run-level, trade-level, cohort-level, grid-level

4. **Source de vérité**
   - calcul backend existant ?
   - artefact Parquet ?
   - colonne SQLite ?
   - payload API ?
   - uniquement contrainte d'objectif saisie par l'utilisateur ?

5. **Usage produit**
   - objectif de stratégie (`strategy_objectives`)
   - KPI de grid-search (`default_target_kpi` / `target_kpi`)
   - métrique de ranking/scoring
   - rapport LLM
   - blocker / caveat
   - affichage frontend seulement

6. **Compatibilité historique**
   - migration DB nécessaire ?
   - valeur nullable ?
   - backfill nécessaire ?
   - comportement des anciennes runs ?

---

## PHASE 1 — Lecture obligatoire du repo

Lire uniquement les fichiers pertinents selon la portée.

### Objectif de stratégie / contrainte UI/API

Lire :
- `backend/app/algo/strategy_objectives.py`
- `backend/app/storage.py`
- `frontend/lib/api.ts`
- `frontend/hooks/useObjectivesForm.ts`
- `frontend/components/algo/ObjectivesForm/shared-styles.ts`
- `frontend/components/algo/ObjectivesForm/context.tsx`
- `frontend/components/algo/ObjectivesForm/DefaultTargetKpiSection.tsx`
- `backend/tests/test_strategy_objectives_v2_schemas.py`
- `backend/tests/test_storage_strategy_objectives_v2_crud.py`
- `backend/tests/test_strategy_objectives_default_target_kpi.py`
- `frontend/tests/useObjectivesForm.test.ts`
- `frontend/tests/objectives-form.test.tsx`
- `frontend/tests/objectives-form-default-target-kpi.test.tsx`

### KPI de grid-search / ranking

Lire :
- modules backend `backend/app/algo/**` qui définissent `target_kpi`, scoring, grid finalization, summaries
- endpoints FastAPI qui reçoivent ou exposent le KPI
- composants frontend qui sélectionnent ou affichent `target_kpi`
- tests backend/frontend autour du ranking, grid search et summaries

Ne pas ajouter une métrique dans `default_target_kpi` si le backend grid-search ne la calcule pas et ne sait pas l'optimiser.

### Rapport LLM / diagnostic / blocker

Lire :
- `docs/reference/FEATURE-EXPORT-LLM-REPORT.md`
- `backend/app/algo/prompt/**`
- `backend/app/algo/analytics/**`
- `backend/app/main.py`
- tests snapshot ou tests de rendu du rapport

Si le prompt généré change, suivre `/edit-export-llm-report` et bumper `PROMPT_VERSION` si requis.

---

## PHASE 2 — Décision d'architecture

Classer l'indicateur dans une seule catégorie principale :

```text
STRATEGY_OBJECTIVE | GRID_TARGET_KPI | COMPUTED_METRIC | REPORT_FIELD | BLOCKER | UI_DISPLAY_ONLY
```

Puis décider :

- **Champ saisi** : l'utilisateur configure une contrainte, mais le moteur ne calcule pas forcément la métrique.
- **Champ calculé** : le backend calcule la métrique depuis les runs/trades/artifacts.
- **Champ optimisable** : la grid-search peut l'utiliser comme KPI cible.
- **Champ de diagnostic** : la boucle itérative peut l'exploiter comme blocker/caveat.

Un même nom ne doit pas être utilisé pour deux sens différents.

---

## PHASE 3 — Implémentation par couche

### A) Backend schema

Pour un objectif de stratégie, mettre à jour :
- `_VALUE_BOUNDS`
- `StrategyObjectivesIn`
- `_DEC_FIELDS` ou `_INT_FIELDS`
- `row_to_snapshot_dict(...)`
- `_FIELD_RENDER_ORDER`
- fonctions de conversion payload DB si concernées

Conserver les valeurs décimales sous forme de string si le contrat existant le fait.

### B) Storage / migrations SQLite

Mettre à jour :
- table fresh schema
- migration additive idempotente `ALTER TABLE ... ADD COLUMN`
- liste canonique des champs numériques
- `upsert_strategy_objectives(...)`
- `inherit_strategy_objectives(...)`
- upsert atomique run + objectives si présent
- summaries (`has_veto`, `has_objectives`) si le champ a un flag VETO

Règles :
- migration additive nullable pour `op` / `value`
- `veto INTEGER NOT NULL DEFAULT 0`
- ne jamais casser les DB existantes
- tester fresh DB et DB migrée si le fichier de tests existe

### C) API frontend types

Mettre à jour :
- `StrategyObjectivesIn`
- `StrategyObjectivesOut` si nécessaire
- commentaires de comptage si présents, ou les supprimer au profit d'un libellé non fragile

### D) Formulaire frontend

Mettre à jour :
- `VALUE_BOUNDS`
- `DEC_FIELDS` / `INT_FIELDS`
- `UseObjectivesFormState`
- `FLOOR_FIELDS` ou logique d'opérateur par défaut
- `EMPTY_FORM`
- `formToPayload(...)`
- `objectivesOutToForm(...)`
- labels/descriptions dans `shared-styles.ts`
- prompt JSON / `NUMERIC_KEYS` dans `context.tsx`

Pour un indicateur proche d'un autre, ajouter un test qui prouve que les deux payload fields restent distincts.

### E) UI target KPI

Ne modifier `DefaultTargetKpiSection.tsx` que si l'indicateur est réellement supporté comme KPI de grid-search.

Si l'indicateur est seulement une contrainte de stratégie, ne pas l'ajouter à `default_target_kpi`.

### F) Docs

Mettre à jour la doc de référence concernée si :
- le contrat API change publiquement
- le rapport LLM change
- le workflow d'ajout doit être documenté
- un utilisateur doit comprendre la différence entre deux indicateurs proches

---

## PHASE 4 — Tests obligatoires

### Backend minimum

Pour un objectif de stratégie :

```bash
cd backend && ../.venv/bin/python -m pytest \
  tests/test_strategy_objectives_v2_schemas.py \
  tests/test_storage_strategy_objectives_v2_crud.py \
  tests/test_strategy_objectives_default_target_kpi.py \
  -q
```

Ajouter au moins :
- test de présence dans les bornes / schema
- test de round-trip storage
- test de séparation sémantique si indicateur proche

### Frontend minimum

```bash
cd frontend && pnpm exec vitest run \
  tests/useObjectivesForm.test.ts \
  tests/objectives-form-default-target-kpi.test.tsx \
  --reporter=dot
```

Si le rendu du formulaire change :

```bash
cd frontend && pnpm exec vitest run tests/objectives-form.test.tsx -t "<nom du test ciblé>" --reporter=dot
```

Éviter `pnpm test -- <file>` dans ce repo si cela lance une suite trop large. Préférer `pnpm exec vitest run ...`.

### Diagnostics

Exécuter `get_errors` sur tous les fichiers modifiés quand l'environnement le permet.

---

## PHASE 5 — Checklist anti-oublis

Avant de conclure, vérifier :

- [ ] le champ existant proche n'a pas été renommé ou réutilisé à tort
- [ ] le nom backend, DB, API et frontend est cohérent
- [ ] les bornes sont définies et testées
- [ ] fresh schema et migration DB sont cohérents
- [ ] upsert, inherit et summaries prennent le champ en compte
- [ ] le formulaire sait convertir input → payload et output → form
- [ ] les labels UI distinguent clairement les concepts proches
- [ ] le prompt JSON / paste AI connaît le champ si pertinent
- [ ] `default_target_kpi` n'a été modifié que si la grid-search supporte vraiment ce KPI
- [ ] tests backend ciblés passent
- [ ] tests frontend ciblés passent
- [ ] les warnings connus sont mentionnés sans les confondre avec des échecs

---

## Sortie attendue

Répondre avec :

1. **Classification** : catégorie principale de l'indicateur.
2. **Décision sémantique** : nouveau champ ou extension d'un champ existant, avec justification.
3. **Fichiers modifiés** : regroupés par backend, frontend, tests, docs.
4. **Validations** : commandes exécutées et résultats.
5. **Limites restantes** : par exemple, non ajouté à `default_target_kpi` car pas encore calculé par grid-search.

---

## Notes AIMOTO importantes

- Daily only.
- Pas de mock/fallback data.
- Backend = source de vérité API/storage.
- Frontend ne lit ni n'écrit SQLite/fichiers directement.
- Python backend : utiliser `../.venv/bin/python` depuis `backend`.
- Pour les tests frontend ciblés, utiliser `pnpm exec vitest run`.
