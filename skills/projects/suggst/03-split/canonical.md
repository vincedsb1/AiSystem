---
name: 03-split
description: Découper une spécification Suggst validée en sous-étapes d’implémentation concrètes, indépendantes et adaptées au niveau MVP ou alpha.
---

# 03-split — Découpage en sous-étapes

## Rôle

Tu transformes une spécification fonctionnelle validée en un petit nombre de
sous-étapes réalisables par `04-build`.

Le découpage doit rendre l’avancement visible sans créer une procédure lourde. Une
sous-étape correspond à une unité de travail qu’un agent peut comprendre, implémenter
et vérifier dans une session ciblée.

Cette étape ne modifie pas le code, ne lance aucun test ou build, ne modifie pas
`STATUS.md`, ne modifie aucune gate et ne crée pas de commit.

## Conditions d’entrée

- La spécification doit exister et être identifiable.
- Pour une spécification `STANDARD` ou `RISKY`, un rapport `02-check` de même version
  doit indiquer `READY`.
- Une spécification `LIGHT` peut être découpée sans fichier `CHECK.md` si son périmètre
  est évident et que l’utilisateur le demande explicitement.
- Si `02-check` indique `REVISE` ou `BLOCKED`, ne contourne pas le verdict : retourne
  vers `01-spec` ou `06-pivot`.

Vérifie la version de la spécification et du rapport de contrôle. Un plan construit
sur une ancienne version est périmé.

## Règle principale : découper pour avancer

Le découpage doit :

- isoler le chemin `MUST_NOW` ;
- laisser `SHOULD`, `LATER` et `OUT` en dehors de la chaîne obligatoire ;
- produire un résultat observable à chaque sous-étape ;
- respecter les dépendances réelles du code ;
- permettre une validation ciblée ;
- éviter qu’une sous-étape exige toute la fonctionnalité pour être considérée comme
  terminée.

Ne transforme pas chaque fichier ou chaque fonction en sous-étape. Une sous-étape peut
modifier plusieurs fichiers lorsque ces fichiers forment une même unité logique.

Ne crée pas non plus une sous-étape énorme qui regroupe toute la fonctionnalité.

## Taille et nombre recommandés

- Une petite fonctionnalité peut produire une seule sous-étape.
- Une fonctionnalité standard produit généralement deux à six sous-étapes.
- Au-delà de six sous-étapes, vérifie si le découpage est réellement nécessaire ou si
  la spécification est trop large.
- Une sous-étape doit normalement être réalisable par un seul appel de `04-build`.

Ces nombres sont des repères, pas des gates. La cohérence et la progression observable
priment sur le nombre exact.

## Lecture minimale

Lis dans cet ordre :

1. `AGENTS.md` et/ou `CLAUDE.md` pour les règles stables ;
2. le bloc courant de `docs/rebuild/STATUS.md` pour connaître l’étape active et les
   limites de validation ;
3. la spécification complète ;
4. le rapport `CHECK.md` correspondant, s’il existe ;
5. les contrats, décisions, briques et ancres de code cités par la spécification ;
6. les patterns de deux fonctionnalités proches uniquement si cela aide à ordonner
   les sous-étapes.

Ne relis pas l’intégralité de l’historique ou des résultats passés si une lecture
ciblée suffit. Ne lance pas de commande de build pour comprendre le découpage.

## Déroulement

### 1. Déterminer le périmètre réel

Identifie :

- l’objectif de la fonctionnalité ;
- les exigences `MUST_NOW` ;
- les dépendances obligatoires ;
- les éléments explicitement reportés ;
- les risques ou inconnues signalés par `02-check`.

Si la spécification mélange le MVP et des évolutions futures, sépare-les dans le plan.
Les éléments `LATER` ne doivent pas apparaître comme des prérequis cachés.

### 2. Choisir une stratégie de découpage

Privilégie, selon le cas :

- une tranche verticale qui rend une partie du parcours utilisable ;
- un découpage par dépendance lorsque les contrats ou données doivent exister avant
  l’interface ;
- un découpage par risque lorsqu’une inconnue technique peut invalider la solution ;
- une seule sous-étape lorsque la fonctionnalité est locale et évidente.

Évite le découpage purement théorique « modèles puis logique puis interface » si cela
ne produit aucun résultat vérifiable avant la fin. Utilise cet ordre uniquement lorsque
les dépendances du projet le rendent nécessaire.

### 3. Traiter les inconnues sans bloquer inutilement

Lorsqu’une inconnue peut être levée par une lecture ou une expérimentation limitée,
crée une sous-étape `DISCOVERY` avec :

- la question précise à résoudre ;
- le périmètre de l’investigation ;
- le résultat attendu ;
- la condition de sortie ;
- l’action après la découverte.

Une sous-étape `DISCOVERY` ne doit pas devenir une recherche ouverte ou une
refactorisation exploratoire.

Si l’inconnue correspond à une décision produit, une modification de périmètre, une
autorisation propriétaire ou une exigence contradictoire, arrête le découpage et
recommande `01-spec` ou `06-pivot`.

### 4. Définir chaque sous-étape

Pour chaque sous-étape, indique uniquement ce qui est nécessaire à son exécution :

- un résultat attendu ;
- le type : `IMPLEMENT`, `DISCOVERY` ou `DOCS` ;
- ce qui est inclus ;
- ce qui est explicitement exclu ;
- les dépendances ;
- les ancres ou fichiers probables ;
- les changements fonctionnels attendus ;
- les critères « terminé » ;
- la validation proportionnelle suggérée ;
- la condition d’arrêt ou de pivot ;
- la sous-étape suivante.

Ne prescris pas ligne par ligne l’implémentation. `04-build` choisit les détails tout
en respectant la spécification et les patterns existants.

## Critères d’une bonne sous-étape

Une sous-étape est suffisamment bonne si :

- son objectif tient en une phrase ;
- son résultat peut être observé ou vérifié ;
- ses dépendances sont connues ;
- son périmètre est limité ;
- elle ne contient pas d’exigence `LATER` obligatoire ;
- elle ne dépend pas d’une hypothèse non signalée ;
- elle peut être arrêtée sans invalider tout le projet ;
- elle indique ce qui permettra de décider de la suite.

Le critère « terminé » doit décrire le résultat, pas seulement une action comme
« modifier trois fichiers ».

## Validation proportionnelle

Le plan peut proposer l’un des niveaux suivants :

- `NONE` : documentation ou analyse uniquement ;
- `TARGETED` : test ciblé ou vérification locale ;
- `BUILD` : build isolé après modification de code ;
- `MANUAL` : scénario humain nécessaire ;
- `PARITY` : build de parité nécessaire pour la nature du changement ;
- `DEFERRED` : preuve reportée explicitement avec raison.

Ne prescris pas `verify.sh` à chaque sous-étape. La validation complète appartient
normalement à `05-finish` ou à une clôture d’étape, selon la politique du projet.

## Plan de sortie

Si le chemin de la spécification est connu, écris le plan dans le même dossier :

- `STEP-XX-SPEC.md` → `STEP-XX-STEPS.md` ;
- `<slug>.md` → `<slug>-STEPS.md`.

Si un fichier de steps actuel existe, conserve ses décisions valides et sa structure
utile. Ne réécris pas un plan historique ou une gate publiée ; demande un nouveau
fichier ou une nouvelle version si nécessaire.

Le plan doit respecter cette structure :

```md
---
id: <identifiant>
spec_path: <chemin>
spec_version: <version>
check_path: <chemin ou null>
status: READY_TO_BUILD | REVISE_SPEC | BLOCKED
step_count: <nombre>
created_at: <YYYY-MM-DD>
---

# Steps — <identifiant>

## Objectif du découpage

## Ordre d’exécution

### Sous-étape 1 — <titre>
- Type: IMPLEMENT | DISCOVERY | DOCS
- Résultat attendu:
- Inclus:
- Exclu:
- Dépendances:
- Ancres:
- Critères terminé:
- Validation suggérée: NONE | TARGETED | BUILD | MANUAL | PARITY | DEFERRED
- Condition d’arrêt ou de pivot:
- Suite:

### Sous-étape 2 — <titre>
...

## Contraintes communes

## Éléments reportés

## Risques de découpage

## Prochaine action
```

Les champs non pertinents peuvent être indiqués `N/A — raison`. Ne remplis pas les
sections artificiellement.

## Contrôle final du découpage

Avant de terminer, vérifie seulement :

- toutes les exigences `MUST_NOW` sont couvertes par une sous-étape ou explicitement
  signalées comme non couvertes ;
- aucune exigence `LATER` ne bloque implicitement une sous-étape ;
- l’ordre respecte les dépendances ;
- chaque sous-étape possède un résultat et un critère « terminé » ;
- les inconnues sont soit bornées par une `DISCOVERY`, soit signalées comme décision
  nécessaire ;
- la validation proposée est proportionnelle ;
- le premier appel de `04-build` est évident.

Cette vérification ne prouve pas que le code est correct et ne lance aucun test.

## Arrêt obligatoire

Retourne `REVISE_SPEC` ou `BLOCKED` sans produire un plan exécutable si :

- la spécification n’est pas `READY` pour une fonctionnalité `STANDARD` ou `RISKY` ;
- le fichier cible ou la version de la spécification sont ambigus ;
- un conflit d’autorité concerne le périmètre ;
- une dépendance indispensable est absente et ne peut pas être créée dans une
  sous-étape bornée ;
- le chemin `MUST_NOW` ne peut pas être séparé des exigences reportées ;
- le découpage exige une décision produit ou une modification de gate ;
- une sous-étape resterait trop grande pour un appel ciblé de `04-build` malgré un
  découpage raisonnable.

Dans ces cas, indique l’action minimale : `01-spec`, `02-check`, `06-pivot` ou une
réponse de l’utilisateur.

## Réponse finale

Retourne un résumé court :

```text
SPEC_PATH: <chemin>
CHECK_PATH: <chemin ou absent>
STEPS_PATH: <chemin ou réponse uniquement>
SPEC_VERSION: <version>
STATUS: READY_TO_BUILD | REVISE_SPEC | BLOCKED
STEP_COUNT: <nombre>
DISCOVERY_STEPS: <nombre>
MUST_NOW_COVERED: YES | NO
VALIDATION_LEVELS: <résumé>
NEXT: 04-build sous-étape 1 | 01-spec | 02-check | 06-pivot | réponse utilisateur
```

Ne prétends pas que la fonctionnalité est implémentée, testée ou validée.
