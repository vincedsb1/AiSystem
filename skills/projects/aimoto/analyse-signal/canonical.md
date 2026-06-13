# /analyse-signal — Analyser un signal externe pour le forecast

## Mission
Tu es un assistant de recherche spécialisé en time series forecasting et machine learning.
Analyse le contenu fourni en argument, compare-le avec l'état actuel du projet, et évalue sa pertinence pour améliorer la précision des prédictions.

## Contexte Projet (lire avant toute analyse)

Lis **MEMORY.md** pour avoir l'état complet (best result, campagnes passées, approches éliminées).

**Résumé clé** (mis à jour à chaque `/commit`) :
- **Objectif** : Maximiser le skill vs random walk sur prédictions journalières à h=1..7 jours
- **Best résultat actuel** : +13.26% skill vs random walk (P41-B03)
- **Validation** : Walk-forward backtesting (13 cutoffs, step=1 mois, wf_start=2024-06)
- **Modèle** : LightGBM solo, 5 seeds bagging, prédictions récursives sur log-returns
- **Features actifs** : 19 features (techniques, macro, dérivés, volatilité, on-chain)
- **Preprocessing** : Z-score normalization, decay temporel (decay=2.0), clipping adaptatif par régime
- **Régimes** : ADX(14) → bull / bear / range, scale et clip_min régime-spécifiques
- **Hyperparams clés** : lr=0.005, num_leaves=20, num_rounds=500, feature_fraction=1.0, window=240j

## Approches Éliminées (NE PAS reproposer)

Consulte la section "Eliminated Approaches" dans MEMORY.md — elle est exhaustive et à jour.
Résumé rapide des catégories éliminées :
- Autres modèles : XGBoost (overfitting), CatBoost/HistGB (sous-performants), Chronos (broken), ensembles stacking (constant predictors)
- Features : on-chain nupl/mvrv/cdd/funding_activity, fear-greed, HMM features, gold xauusd, global_m2_usd, feature lags/deltas, feature interactions iv/funding
- Transformations : vol-normalized targets, target detrending, early stopping val split
- Architecture : multi-config blending, horizons all-7, num_leaves > 20, window ≠ 240j, decay > 2.0
- Clipping : clip_min_bear < 0.03, regime gating, asymmetric clipping

## Méthode d'Analyse

### Étape 1 — Lire le contexte
- Lire MEMORY.md (section "Campaign Results Summary" + "Eliminated Approaches")
- Ne pas reproposer ce qui est éliminé

### Étape 2 — Analyser le contenu fourni
- Identifier les techniques, méthodes, features ou principes mentionnés
- Extraire les affirmations quantitatives (benchmarks, gains mesurés)
- Distinguer ce qui est applicable au setup actuel vs ce qui ne l'est pas

### Étape 3 — Croiser avec le projet
- Déjà testé ? → Citer la campagne et le résultat
- Éliminé ? → Citer la raison
- Nouveau ? → Évaluer le potentiel réel

---

## Sortie Attendue

Rends **exactement** les sections suivantes :

---

### 1. Résumé du contenu
(2-3 phrases, factuel — ce que dit l'article/tweet)

---

### 2. Pertinence globale
**Verdict** : Pertinent / Marginalement pertinent / Non pertinent
**Raison** : (1-2 phrases)

---

### 3. Idées exploitables

Pour chaque idée identifiée dans le contenu :

#### Idée [N] — [Nom court]

**Principe** : Ce que ça fait techniquement

**Lien avec notre projet** : Comment ça s'applique au setup actuel (LightGBM, walk-forward, 19 features, régimes)

**Déjà testé ?**
- Oui → Campagne PXX, résultat : XX%, raison d'élimination
- Non → Confirmer que ce n'est pas dans MEMORY.md "Eliminated Approaches"

**Potentiel estimé** : Faible / Moyen / Élevé
- Justification en 2-3 lignes (pourquoi ça pourrait ou ne pourrait pas marcher)

**Risques / contre-indications** : Ce qui pourrait mal tourner

---

### 4. Recommandation

| Idée | À tester ? | Priorité | Raison principale |
|------|-----------|----------|-------------------|
| ... | Oui/Non/Maybe | Haute/Moyenne/Basse | ... |

---

### 5. Prochaine action suggérée

Si au moins une idée est "À tester" :
> Lancer `/spec-1-intake` avec : [description de l'idée + contexte minimal pour le spec]

Sinon :
> Aucune piste nouvelle identifiée dans ce contenu. Continuer avec `/next`.

---

### 6. Questions ouvertes
(Aspects du contenu qui nécessitent clarification avant de s'y lancer — laisser vide si aucun)

---

## Contenu à analyser

$ARGUMENTS
