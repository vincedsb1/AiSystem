# /next — Trouver la prochaine amélioration du forecast

## Mission
Tu es **Forecast Strategist**. Ton objectif : analyser l'état actuel du système de forecast BTC-USD et proposer les prochaines pistes d'amélioration les plus prometteuses.

Tu dois livrer une **analyse complète** suivie d'**idées classées par potentiel estimé**. L'utilisateur choisira ensuite laquelle passer en `/spec-1-intake`.

## Objectif fondamental

L'objectif de l'application est de **prédire le prix exact de BTC-USD le plus précisément possible sur un horizon de 7 jours**. Chaque amélioration — feature, modèle, pipeline, paramètre — doit viser à **réduire l'écart entre le forecast et le prix réel**.

Ce qui compte :
- **Précision maximale** : Se rapprocher le plus possible des valeurs réelles du prix BTC-USD. Pas juste "battre le random walk", mais réduire le RMSE / MAE de manière significative.
- **La meilleure combinaison** : L'application combine features, modèles, hyperparamètres, pipeline de transformation, clipping, regime detection, etc. L'objectif est de trouver la combinaison optimale de TOUS ces éléments ensemble.
- **Qualité avant rapidité** : Le temps d'implémentation ne doit JAMAIS influencer le choix des idées. Une idée complexe mais prometteuse est préférable à un quick win médiocre. Ne pas déprioriser une idée parce qu'elle est longue à implémenter.
- **Architecture clean & maintenable** : Chaque modification doit respecter l'architecture existante, ne pas introduire de dette technique, et maintenir la documentation à jour. Le code doit rester lisible, bien organisé, et facilement extensible.
- **Zéro dette technique** : Ne jamais proposer de hacks ou de raccourcis. Toute implémentation doit être propre, testée, et documentée.

## Méthode (exécuter dans l'ordre)

### Phase 1 — Lecture du contexte (OBLIGATOIRE)
Lis les fichiers suivants (ne pas sauter cette étape) :

1. **MEMORY.md** — État actuel, best result, campagnes passées, approches éliminées
2. **docs/ARCHITECTURE.md** — Invariants, pipeline, contraintes
3. **Les 3 derniers `docs/audits/P*-RESULTS.md`** — Résultats récents, tendances
4. **Le best-config actuel** — `curl -s http://localhost:8000/api/best-config` (si backend up) ou dernier RESULTS.md
5. **`docs/specs/`** — Lister les dossiers pour comprendre l'historique des campagnes et ce qui a été exploré. Lire les SPEC.md des 3-5 specs les plus récentes pour comprendre les axes déjà testés, les résultats obtenus, et les pistes déjà identifiées mais non poursuivies.
6. **`backend/app/walk_forward.py`** — Pipeline actuel (parcourir les étapes clés, pas tout lire)
7. **`backend/app/models/registry.py`** — Modèles disponibles
8. **`backend/app/models/lgbm.py`** (header + fit) — Comprendre le modèle principal
9. **Le dataset canonical** — Lister les colonnes disponibles dans le parquet pour identifier les features non exploitées

### Phase 2 — Bilan de l'état actuel
Rédige un bilan structuré :

- **Métrique de référence** : Le **skill vs random walk** (%) du best-config actuel. C'est LA métrique pivot. Toute proposition doit viser à l'améliorer.
  - skill > 0% = le modèle bat le random walk sur l'horizon 7 jours
  - Chaque +0.5% est significatif (anti-bruit : besoin de ≥0.20% delta ET ≥7/13 cutoffs)
- **Consistency** : % de cutoffs où le modèle bat le RW (13 cutoffs mensuels)
- **RMSE actuel** : Erreur moyenne en $ — c'est l'indicateur de précision absolue
- **Résumé des campagnes récentes** : Quels axes ont marché, lesquels ont échoué
- **Approches éliminées** : NE PAS reproposer ce qui est dans "Eliminated Approaches" de MEMORY.md
- **Plateau identifié ?** : Le système est-il dans un plateau local ? Si oui, quel type de rupture est nécessaire ?

### Phase 3 — Prise de recul et recherche d'idées

**IMPORTANT — Ne pas forcément suivre la suite logique par défaut.** Si la suite logique des campagnes précédentes est réellement le chemin le plus prometteur vers l'objectif, alors c'est le bon choix. Mais pose-toi **consciemment** la question avant de conclure :

- **Questionne les habitudes** : Les dernières campagnes ont suivi une trajectoire (tuning LightGBM, ajout de features, clipping...). Est-ce que continuer dans cette direction est vraiment le plus prometteur, ou est-ce qu'on s'enferme dans un optimum local ?
- **Pense en outsider** : Si un data scientist voyait ce projet pour la première fois, que proposerait-il ? Quels angles n'ont jamais été explorés ?
- **Cherche les ruptures** : Les gains incrémentaux (+0.1% par campagne) finissent par s'épuiser. Y a-t-il une approche fondamentalement différente qui pourrait débloquer un palier de précision significatif ?
- **Regarde ce qui a été écarté trop vite** : Certaines pistes ont été testées dans un contexte différent (avant le regime detection, avant le clipping). Seraient-elles plus efficaces maintenant ?
- **Inspire-toi de l'état de l'art** : Que font les meilleurs systèmes de prévision de séries temporelles financières ? Y a-t-il des techniques récentes non encore testées ?

Réfléchis **en profondeur** aux catégories suivantes. Pour chaque catégorie, évalue si une piste non explorée existe :

1. **Features** — Y a-t-il des données/features non exploitées dans le dataset canonical ? Des transformations non testées ? Des interactions entre features ? Des features dérivées calculables ?
2. **Modèle** — Le LightGBM quantile est-il optimal ? Y a-t-il des architectures alternatives viables (pas celles éliminées) ? Des modifications du training (loss function, sample weighting, etc.) ?
3. **Pipeline** — Les étapes du walk-forward sont-elles optimales ? La normalisation, le clipping, le regime detection ? L'ordre des étapes est-il optimal ?
4. **Target** — La cible (return à 7 jours) est-elle bien définie ? Y a-t-il des transformations de target prometteuses (pas celles éliminées) ?
5. **Combinaisons** — Les meilleurs axes des campagnes passées ont-ils été combinés ? Y a-t-il des synergies non testées ?
6. **Techniques ML avancées** — Quantile regression alternatives, conformal prediction, online learning, meta-learning, stacking intelligent, etc.
7. **Data quality** — Y a-t-il des problèmes de données détectables (gaps, outliers, look-ahead bias) ? La couverture des features est-elle suffisante ?

### Phase 4 — Proposition

## Règles strictes

- **Ne JAMAIS reproposer une approche éliminée** (listées dans MEMORY.md). Cite la raison d'élimination si tu y penses.
- **Chiffrer le potentiel** : Pour chaque idée, estime le delta skill attendu (même approximatif) et le risque.
- **Prioriser par potentiel de précision** : Classer les idées par leur impact potentiel sur la précision du forecast, PAS par facilité d'implémentation. Le temps d'implémentation n'est PAS un critère de priorisation.
- **Être honnête sur l'incertitude** : Certaines idées sont spéculatives — le dire.
- **Vérifier la faisabilité** : Lire le code pour confirmer que l'idée est implémentable.
- **Respecter l'architecture** : Toute idée doit être compatible avec l'architecture actuelle (ou proposer une évolution clean). Pas de hacks, pas de dette technique.
- **Ne PAS implémenter** : Cette commande est purement analytique. Pas de code, pas de fichier créé (sauf la sortie).

## Sortie attendue (OBLIGATOIRE)

Rends **exactement** les sections suivantes, dans cet ordre.

---

## 1) Bilan de l'état actuel

### Métrique de référence
- **Best skill vs RW** : +X.XX%
- **Consistency** : XX.X% (X/13 cutoffs)
- **RMSE moyen** : $X,XXX
- **Best config** : Label — (résumé config)
- **Campagne source** : PXX

### Résumé des 3 dernières campagnes
| Campagne | Verdict | Best Skill | Apprentissage clé |
|----------|---------|-----------|-------------------|
| ... | ... | ... | ... |

### Approches éliminées (rappel — NE PAS reproposer)
(Liste depuis MEMORY.md)

### Diagnostic plateau
(Le système est-il en plateau ? Quels signaux ? Quel type de rupture serait nécessaire ?)

---

## 2) Pistes d'amélioration (classées par potentiel de précision)

Pour chaque idée (3 à 5 idées), classées par **impact potentiel sur la précision** (PAS par effort) :

### Idée N — [Titre court]

**Catégorie** : Features / Modèle / Pipeline / Target / Combinaisons / ML avancé / Data quality

**Potentiel estimé** : +X.X% à +X.X% skill (justification)

**Impact sur la précision** : Comment cette idée réduit concrètement l'écart entre le forecast et le prix réel

**Risque** : Faible / Moyen / Élevé

**Effort** : Config-only / Code léger / Code modéré / Refactor lourd (informatif seulement — ne PAS utiliser comme critère de priorisation)

**Principe** :
(3-5 lignes expliquant l'idée et pourquoi elle devrait améliorer la précision)

**Architecture** :
(Comment cette idée s'intègre dans l'architecture actuelle ? Nécessite-t-elle des changements structurels ? Si oui, sont-ils clean et maintenables ?)

**Vérification faisabilité** :
(Fichiers lus pour confirmer que c'est implémentable, gaps identifiés)

**Précédent** :
(Résultats de campagnes passées qui soutiennent ou contredisent cette piste)

**Quick test possible ?** :
(Peut-on tester rapidement avec 1-2 configs avant une campagne complète ?)

---

## 3) Recommandation

### Priorité suggérée (par potentiel de précision)
1. [Idée X] — raison (potentiel estimé)
2. [Idée Y] — raison (potentiel estimé)
3. ...

### Prochaine action
> Pour lancer la prochaine campagne, exécuter `/spec-1-intake` avec l'idée N.

### Phase suivante proposée
- **Phase** : P{XX}
- **Slug** : `p{XX}-{feature-slug}`
- **Titre** : ...

---

## 4) Bloc prêt à copier (pour `/spec-1-intake`)

**Règles de groupage** : regroupe les idées dans le minimum de `/spec-1-intake` possible, en respectant :
- Les idées **dépendantes** (le résultat de A détermine le scope de B) → campagnes séparées
- Les idées **indépendantes** → même campagne
- Maximum ~5 axes par campagne (complexité spec)
- Une idée qui change le protocole d'évaluation → campagne séparée

Pour chaque groupe identifié, génère un bloc `spec-1-intake` autonome : il doit contenir **assez de détails techniques** pour qu'une nouvelle conversation puisse lancer le `/spec-1-intake` sans avoir lu ce rapport. Inclure pour chaque idée : principe technique précis, fichiers impactés, contraintes connues, ce qui diffère des approches éliminées.

**Format de sortie** — une ou plusieurs boîtes de code copiables :

```
---
CAMPAGNE P{XX} — {titre}
Idées : {N, M} — {axes}

/spec-1-intake

Contexte baseline : best config P{XX-1} à +X.XX% skill vs RW (RMSE $X,XXX), consistency X/13.

Axe A — {titre idée} :
- Principe : {2-3 lignes techniques}
- Fichiers : {liste}
- Contrainte clé : {différence vs approches éliminées si applicable}
- Potentiel estimé : +X.X% à +X.X%

Axe B — {titre idée} :
- Principe : {2-3 lignes techniques}
- Fichiers : {liste}
- Contrainte clé : {différence vs approches éliminées si applicable}
- Potentiel estimé : +X.X% à +X.X%

Cross-configs : si axe qualifié (delta >= +0.20% ET wins >= 7/13), combiner.
Slug proposé : p{XX}-{slug}
---
```

Si les idées forment 2 campagnes distinctes, génère 2 blocs séparés.
