---
name: 06-pivot
description: Prendre du recul face à un blocage Suggst, distinguer un vrai risque MVP d’une exigence excessive et choisir une seule prochaine direction.
---

# 06-pivot — Recul et décision face à un blocage

## Rôle

Tu interviens lorsqu’une sous-étape ou une fonctionnalité ne progresse plus.

Tu suspends les modifications, reconstruis la situation à partir des faits, identifies
la nature du blocage et proposes une décision simple : continuer, réduire, découper,
réviser, changer d’approche, reporter ou demander une décision propriétaire.

`06-pivot` n’est pas une étape obligatoire du cycle normal et ne doit pas être lancé
pour chaque erreur ou difficulté mineure.

Tu ne corriges pas automatiquement le code, tu ne modifies pas la spécification et tu
ne lances pas de validation coûteuse. Les modifications sont reprises par `01-spec`,
`03-split` ou `04-build` après la décision.

## Quand utiliser ce skill

Utilise `06-pivot` notamment lorsque :

- deux tentatives fondées sur la même hypothèse ont échoué ;
- une troisième correction équivalente est envisagée ;
- la sous-étape devient beaucoup plus large que prévu ;
- les critères semblent trop élevés pour le MVP ou l’alpha ;
- une correction spéculative est envisagée sans reproduction du problème ;
- la spécification, le code et les tests ne décrivent plus le même comportement ;
- un problème d’environnement est peut-être confondu avec un problème de code ;
- un artefact, un manifeste ou une preuve attendue est absent ;
- plusieurs sessions répètent la même hypothèse sans progrès.

Ne l’utilise pas uniquement parce qu’un test ponctuel est rouge si la cause est claire
et qu’une correction ciblée reste raisonnable.

## Première règle : arrêter l’escalade

Dès que le pivot est lancé :

- ne lance pas une nouvelle correction spéculative ;
- ne modifie pas les critères pour obtenir du vert ;
- ne relance pas une validation complète sans nouvelle question à résoudre ;
- ne modifie pas une gate, une preuve ou un résultat historique ;
- conserve les faits, logs et manifestes déjà produits ;
- préserve les modifications préexistantes de l’utilisateur.

Le but est de réduire l’incertitude, pas de produire davantage de changements.

## Lecture minimale

Lis uniquement ce qui permet de comprendre le blocage :

1. `AGENTS.md` et/ou `CLAUDE.md` ;
2. le bloc courant de `docs/rebuild/STATUS.md` ;
3. la spécification concernée ;
4. le `CHECK.md` et le plan `STEPS.md` s’ils existent ;
5. le rapport de `04-build`, le diff, le log ou le manifeste directement lié ;
6. un ou deux fichiers d’ancrage nécessaires pour vérifier une hypothèse.

Ne relis pas tout l’historique des conversations ou du rebuild. Ne lance pas de build,
de test ou de campagne payante pour « voir si cela passe ».

## Déroulement

### 1. Décrire la situation

Écris en quelques lignes :

- l’objectif initial ;
- la sous-étape concernée ;
- le résultat attendu ;
- le résultat réellement observé ;
- le moment où le blocage est apparu ;
- les tentatives déjà effectuées.

Sépare toujours :

- `FACTS` : observés directement dans le code, les logs, les tests ou les documents ;
- `HYPOTHESES` : explications encore incertaines ;
- `UNKNOWN` : informations manquantes ;
- `FAILED_ATTEMPTS` : approches déjà essayées et leur résultat.

Ne présente pas une hypothèse comme une cause démontrée.

### 2. Classer le blocage

Utilise une seule catégorie principale :

- `SCOPE` : l’exigence dépasse le niveau de maturité ou le périmètre ;
- `SPEC` : la spécification est ambiguë, contradictoire ou incomplète ;
- `SPLIT` : la sous-étape est trop grande ou mal découpée ;
- `CODE` : une cause technique est démontrée mais la correction n’est pas terminée ;
- `ARCHITECTURE` : les patterns ou frontières existants ne permettent pas directement
  la solution ;
- `TEST` : le test ou le critère ne mesure pas correctement le comportement ;
- `ENVIRONMENT` : outil, permission, matériel, secret ou configuration manquante ;
- `EVIDENCE` : la preuve est absente, périmée ou ne correspond pas à la session ;
- `OWNER_DECISION` : une décision produit ou d’autorité est nécessaire.

Une erreur de compilation n’est pas automatiquement un blocage d’architecture. Un
manifeste absent n’est pas automatiquement un bug produit.

### 3. Évaluer le risque MVP

Réponds explicitement à ces questions :

1. Le parcours principal est-il inutilisable sans résoudre ce problème ?
2. Y a-t-il un risque de données perdues, de secret exposé, de coût réseau incontrôlé,
   de résultat fondamentalement faux ou de régression démontrée ?
3. Le problème peut-il être reporté sans prétendre que la fonctionnalité est plus
   avancée qu’elle ne l’est réellement ?
4. Quel est le comportement le plus simple qui apporte déjà la valeur principale ?

Classe ensuite la situation :

- `MVP_BLOCKER` : impossible de poursuivre honnêtement sur le chemin principal ;
- `MVP_RISK` : risque important à traiter ou à faire accepter explicitement ;
- `NON_BLOCKING_DEBT` : amélioration, preuve ou robustesse reportable ;
- `NOT_A_PRODUCT_BLOCKER` : problème d’outil, de test, de documentation ou
  d’environnement qui ne justifie pas d’élargir le produit.

Ne transforme pas une exigence de perfection statistique, une preuve future ou un
durcissement non nécessaire en `MVP_BLOCKER`.

### 4. Formuler les options

Propose au maximum quatre options, dont au moins une option de simplification lorsque
le problème concerne le périmètre.

Options possibles :

- `CONTINUE` : poursuivre avec l’hypothèse actuelle, si elle reste raisonnable ;
- `REDUCE_SCOPE` : conserver le chemin principal et classer le reste `LATER` ;
- `SPLIT` : créer une sous-étape `DISCOVERY` ou découper davantage ;
- `REVISE_SPEC` : clarifier ou modifier le comportement attendu ;
- `CHANGE_APPROACH` : abandonner l’hypothèse actuelle et choisir une autre solution ;
- `DEFER` : documenter la dette et continuer sur la suite ;
- `ASK_OWNER` : demander une décision produit, de sécurité, de coût ou d’autorité ;
- `FIX_ENVIRONMENT` : corriger l’environnement sans modifier le produit.

Pour chaque option, indique brièvement :

- ce qu’elle permet ;
- ce qu’elle coûte ;
- le risque qu’elle conserve ;
- la commande ou étape qui reprend ensuite.

Ne propose pas plusieurs variantes techniques détaillées à implémenter en parallèle.

### 5. Recommander une seule direction

Choisis une option recommandée et justifie-la en quelques lignes.

La recommandation doit privilégier, dans cet ordre :

1. préserver le parcours `MUST_NOW` ;
2. réduire la complexité inutile ;
3. éviter une troisième tentative équivalente ;
4. conserver les preuves et décisions déjà prises ;
5. maintenir une prochaine action réalisable.

Si aucune option ne permet d’avancer honnêtement, recommande `ASK_OWNER` ou
`REVISE_SPEC` plutôt qu’une correction spéculative.

## Règles de reprise

La recommandation doit indiquer une seule prochaine étape :

- `01-spec` si le besoin, le périmètre ou le niveau de maturité doit changer ;
- `02-check` si la spécification a été révisée et doit être recontrôlée ;
- `03-split` si le problème vient du découpage ;
- `04-build` si une nouvelle correction ciblée est justifiée par une hypothèse
  différente et testable ;
- `05-finish` si le chemin `MUST_NOW` est suffisant et que seule la clôture reste ;
- réponse de l’utilisateur si une décision propriétaire est indispensable.

La reprise doit préciser sa condition de départ, par exemple :

```text
Reprendre 04-build uniquement lorsque l’option REDUCE_SCOPE a été intégrée à la spec
et que le critère C-003 est remplacé par un comportement vérifiable localement.
```

## Rapport de pivot

Par défaut, retourne le rapport dans la réponse. Écris un fichier `PIVOT.md` à côté
de la spécification uniquement si le pivot entraîne une décision de périmètre, une
dette importante ou une nouvelle approche qui doit être conservée.

Si le chemin est identifiable :

- `STEP-XX-SPEC.md` → `STEP-XX-PIVOT.md` ;
- `<slug>.md` → `<slug>-PIVOT.md`.

Ne crée pas de dossier ou de convention supplémentaire si le chemin est ambigu.

Structure recommandée :

```md
---
id: <identifiant>
spec_path: <chemin>
steps_path: <chemin ou null>
substep: <numéro ou null>
status: CONTINUE | REDUCE_SCOPE | SPLIT | REVISE_SPEC | CHANGE_APPROACH | DEFER | ASK_OWNER | FIX_ENVIRONMENT
blocker_type: SCOPE | SPEC | SPLIT | CODE | ARCHITECTURE | TEST | ENVIRONMENT | EVIDENCE | OWNER_DECISION
mvp_assessment: MVP_BLOCKER | MVP_RISK | NON_BLOCKING_DEBT | NOT_A_PRODUCT_BLOCKER
created_at: <YYYY-MM-DD>
---

# Pivot — <identifiant>

## Situation

## Faits

## Hypothèses

## Inconnues

## Tentatives échouées

## Classification du blocage

## Évaluation MVP

## Options

## Recommandation

## Décision attendue

## Condition de reprise

## Prochaine étape
```

Ne modifie pas la spécification dans ce rapport. La modification est réalisée par
`01-spec` après décision.

## Arrêt obligatoire

Arrête-toi et demande une décision si :

- les faits disponibles sont insuffisants pour distinguer deux causes majeures ;
- le choix modifie le périmètre produit ou le niveau de maturité ;
- le choix touche une gate, une preuve historique, un seuil critique ou une donnée
  sensible ;
- aucune option ne permet de préserver le parcours principal ou de documenter
  honnêtement une dette ;
- le problème semble venir d’un conflit entre `STATUS.md`, une spécification et une
  règle permanente.

Ne résous pas ces conflits par récence, intuition ou préférence d’implémentation.

## Réponse finale

Retourne un résumé court :

```text
SPEC_PATH: <chemin>
STEPS_PATH: <chemin ou absent>
SUBSTEP: <numéro et titre ou null>
STATUS: CONTINUE | REDUCE_SCOPE | SPLIT | REVISE_SPEC | CHANGE_APPROACH | DEFER | ASK_OWNER | FIX_ENVIRONMENT
BLOCKER_TYPE: <catégorie>
MVP_ASSESSMENT: MVP_BLOCKER | MVP_RISK | NON_BLOCKING_DEBT | NOT_A_PRODUCT_BLOCKER
FACTS: <résumé>
FAILED_ATTEMPTS: <nombre>
RECOMMENDATION: <une seule option>
NEXT: 01-spec | 02-check | 03-split | 04-build | 05-finish | réponse utilisateur
RESUME_WHEN: <condition précise>
PIVOT_PATH: <chemin ou réponse uniquement>
```

Ne prétends pas que le blocage est résolu tant qu’une action de reprise n’a pas été
exécutée et vérifiée.
