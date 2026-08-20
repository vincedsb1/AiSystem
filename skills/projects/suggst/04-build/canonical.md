---
name: 04-build
description: Implémenter une seule sous-étape Suggst à la fois, avec des modifications minimales, une validation proportionnelle et un arrêt clair en cas de blocage.
---

# 04-build — Implémentation d’une sous-étape

## Rôle

Tu implémentes une seule sous-étape issue de `03-split`.

Tu dois produire un progrès concret et vérifiable, sans élargir spontanément le
périmètre. Tu respectes la spécification, les patterns Swift/SwiftUI existants et
les règles de validation du projet.

Une invocation de `04-build` ne doit pas essayer d’implémenter toute la fonctionnalité,
de refactorer l’architecture ou de résoudre une dette historique non liée.

## Conditions d’entrée

- La spécification fonctionnelle est identifiable.
- Le plan `STEPS.md` et la sous-étape ciblée sont identifiables pour une fonctionnalité
  `STANDARD` ou `RISKY`.
- La sous-étape n’est pas déjà terminée ou invalidée par une version plus récente de
  la spécification.
- Les critères « terminé » et la validation attendue sont compréhensibles.

Pour une modification `LIGHT`, l’utilisateur peut fournir directement l’objectif et
les fichiers concernés sans plan `STEPS.md`.

Si une condition manque, ne commence pas à coder au hasard. Indique l’élément manquant
et recommande `01-spec`, `03-split` ou `06-pivot` selon le cas.

## Ce que ce skill peut modifier

Modifie uniquement ce qui est nécessaire à la sous-étape :

- fichiers Swift ou SwiftUI concernés ;
- tests directement nécessaires au comportement ;
- ressources ou configuration explicitement incluses dans la sous-étape ;
- documentation locale explicitement demandée par la sous-étape.

Ne modifie pas par défaut :

- `STATUS.md`, `ROADMAP.md` ou une gate ;
- `.artifacts/` à la main ;
- les manifestes, logs ou résultats historiques ;
- les contrats ou seuils hors périmètre ;
- des fichiers non liés pour « nettoyer » le projet ;
- les spécifications pour masquer un échec ;
- les fichiers d’une autre sous-étape.

Les mises à jour globales de documentation, d’état et de clôture appartiennent à
`05-finish`.

## Lecture minimale avant toute écriture

Lis dans cet ordre :

1. `AGENTS.md` et/ou `CLAUDE.md` ;
2. le bloc courant de `docs/rebuild/STATUS.md` ;
3. la spécification fonctionnelle ;
4. le plan `STEPS.md` et la sous-étape ciblée ;
5. le `CHECK.md` correspondant si nécessaire ;
6. les contrats, décisions, briques et ancres directement concernés ;
7. au moins un ou deux exemples du pattern existant que tu vas modifier ou prolonger.

Ne relis pas tout l’historique du rebuild ou tout le dépôt si les fichiers pertinents
suffisent.

Avant d’écrire, reformule mentalement :

- le résultat attendu ;
- les fichiers autorisés ou probables ;
- ce qui est explicitement hors périmètre ;
- le critère qui permettra de déclarer la sous-étape terminée.

## Méthode d’implémentation

### 1. Confirmer le périmètre

Vérifie que la sous-étape correspond toujours à la version actuelle de la
spécification.

Si le dépôt ou la documentation montrent que l’objectif a changé :

- ne réinterprète pas silencieusement la demande ;
- signale la divergence ;
- retourne à `01-spec` ou `06-pivot`.

### 2. Comprendre le pattern existant

Avant de créer une nouvelle structure :

- cherche le pattern déjà utilisé pour un comportement équivalent ;
- lis un ou deux exemples pertinents ;
- conserve les conventions de nommage, de flux de données, de tests et de copie UI.

Dans Suggst :

- respecte Swift 6.2 et SwiftUI ;
- conserve les textes d’interface en français via `UIText.t(_:)` ;
- respecte les contrats d’identité de capture et les formats audio existants ;
- ne crée pas de données fictives ou de fallback silencieux ;
- ne place pas de contenu audio, professionnel, de job posting, d’UID complet,
  de secret ou de chemin absolu dans les diagnostics.

### 3. Implémenter le minimum nécessaire

Réalise la modification la plus petite qui satisfait le comportement `MUST_NOW`.

- N’ajoute pas une abstraction parce qu’elle pourrait être utile plus tard.
- Ne traite pas `SHOULD` ou `LATER` si cela n’est pas nécessaire au chemin principal.
- Ne refactorise pas un fichier volumineux uniquement pour réduire son nombre de lignes.
- Ne modifie pas plusieurs architectures possibles en parallèle.
- Si une amélioration non indispensable apparaît, note-la pour plus tard.

Une sous-étape peut modifier plusieurs fichiers, mais tous doivent avoir une raison
directe et vérifiable dans la sous-étape.

### 4. Vérifier localement

Après la modification :

- relis le diff de la sous-étape ;
- vérifie les chemins, noms, types et contrats concernés ;
- vérifie que le code n’introduit pas de comportement hors périmètre ;
- vérifie que les textes, erreurs et états UI sont cohérents ;
- vérifie les tests directement liés lorsqu’ils existent.

Ne considère pas une compilation comme une preuve suffisante du comportement produit.

## Validation proportionnelle

Choisis le plus petit niveau qui répond à la question de la sous-étape.

### Documentation ou analyse uniquement

Aucun build. Retourne une confirmation de lecture ou de documentation.

### Modification Swift locale

Selon la sous-étape :

1. test ciblé avec `-only-testing` si un test pertinent existe ;
2. `./scripts/build.sh` après une modification compilable.

Le test ciblé ne doit pas être inventé si aucun test adapté n’existe. Indique alors
`NOT_RUN` et explique pourquoi.

### Modification de configuration ou de projet

Pour `.pbxproj`, `.entitlements`, `.xcscheme`, `.xcconfig` ou `Info.plist` :

```bash
./scripts/build.sh
./scripts/build-xcode-parity.sh
```

### Modification large ou transverse

Ne lance pas automatiquement `./scripts/verify.sh` pendant l’itération. Indique que
la validation complète est à réaliser par `05-finish` ou lors de la clôture d’étape.

### Règles de preuve

Pour annoncer un succès de build ou de test :

- utilise le manifeste produit par la session courante ;
- vérifie le code de sortie et les critères du manifeste ;
- vérifie la stabilité de l’arbre source ;
- rapporte `testCount` et `failureCount` depuis le manifeste ;
- indique explicitement ce qui n’a pas pu être exécuté.

Une absence de preuve est `NOT_RUN`, jamais `PASS`.

Les validations matérielles Core Audio/TCC, les appels fournisseurs payants et les
secrets absents restent des limites explicites. Ne les contourne pas avec une preuve
fabriquée ou un seuil modifié.

## Gestion des échecs et des blocages

Après un échec :

1. distingue le fait observé de l’hypothèse sur la cause ;
2. lis le log ou le manifeste disponible ;
3. vérifie que l’échec concerne bien la sous-étape ;
4. applique au maximum une correction fondée sur cette hypothèse ;
5. relance uniquement la validation nécessaire.

Après deux échecs consécutifs fondés sur la même hypothèse :

- n’empile pas une troisième variante équivalente ;
- conserve la preuve de l’échec ;
- laisse les changements non validés dans l’état le plus sûr possible, sans supprimer
  les modifications préexistantes de l’utilisateur ;
- retourne `BLOCKED` ou `PARTIAL` ;
- recommande `06-pivot`.

Utilise également `06-pivot` si :

- les critères dépassent le niveau MVP/alpha ;
- la solution nécessite une décision produit ;
- la sous-étape devient plus large que prévu ;
- un problème d’environnement est confondu avec un problème de code ;
- le comportement réel ne peut pas être reproduit mais l’agent s’apprête à appliquer
  des corrections spéculatives.

Ne modifie pas la spécification ou les critères d’acceptation pour faire passer une
validation rouge. Une réduction de périmètre passe par `01-spec` ou `06-pivot`.

## Cas particulier : cockpit et règles propriétaires

Si la sous-étape touche `CockpitView` ou une zone soumise à une règle read-only :

- vérifie la portée exacte de la règle dans les documents actuels ;
- n’assume pas qu’elle est permanente ni qu’elle est levée ;
- si la modification exige une décision propriétaire, arrête-toi avant l’écriture ;
- indique la décision nécessaire et retourne vers `01-spec` ou `06-pivot`.

## Rapport de fin de sous-étape

Ne modifie pas `STATUS.md` ni une gate pour publier ce rapport. Retourne un résumé
structuré dans la réponse :

```text
SPEC_PATH: <chemin>
STEPS_PATH: <chemin ou absent>
SUBSTEP: <numéro et titre>
STATUS: IMPLEMENTED | PARTIAL | BLOCKED | NOT_TESTED

FILES_CREATED:
- <chemin> — <raison>

FILES_MODIFIED:
- <chemin> — <raison>

VALIDATION:
- Niveau: NONE | TARGETED | BUILD | PARITY | MANUAL | DEFERRED
- Commande(s): <commande ou N/A>
- Résultat: PASS | FAIL | NOT_RUN
- Manifeste(s): <chemin ou N/A>
- testCount: <valeur ou N/A>
- failureCount: <valeur ou N/A>

DONE_WHEN:
- <critère du plan> — PASS | FAIL | NOT_TESTED

DOCS_FOR_05_FINISH:
- <mise à jour documentaire à prévoir ou aucune>

LIMITATIONS:
- <ce qui n’a pas été vérifié>

NEXT:
- 04-build sous-étape suivante
- 05-finish si toutes les sous-étapes sont terminées
- 06-pivot en cas de blocage
```

Utilise `IMPLEMENTED` seulement si le changement est réalisé et que la validation
appropriée est passée. Utilise `PARTIAL` si le code est présent mais qu’un critère ou
une validation reste ouvert. Utilise `NOT_TESTED` lorsqu’aucune validation pertinente
n’a pu être exécutée.

Ne prétends pas que la fonctionnalité complète est terminée tant que toutes les
sous-étapes et `05-finish` ne sont pas terminées.
