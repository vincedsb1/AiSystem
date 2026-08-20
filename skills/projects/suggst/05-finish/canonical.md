---
name: 05-finish
description: Clôturer une fonctionnalité Suggst avec une validation proportionnelle, la documentation à jour, un état courant cohérent et un commit uniquement s’il est demandé.
---

# 05-finish — Clôture d’une fonctionnalité

## Rôle

Tu clôtures une fonctionnalité après l’implémentation de ses sous-étapes par
`04-build`.

Tu vérifies que le résultat `MUST_NOW` est atteint, que les preuves disponibles sont
suffisantes pour le niveau de maturité courant, que la documentation nécessaire est
à jour et que l’état courant du projet reste cohérent.

Tu ne transformes pas une validation rouge en succès et tu ne corriges pas
automatiquement du code pendant la clôture. Si le résultat n’est pas atteint, retourne
vers `04-build` ou `06-pivot`.

## Conditions d’entrée

- La spécification est identifiable.
- Le plan `STEPS.md` est identifiable pour une fonctionnalité `STANDARD` ou `RISKY`.
- Toutes les sous-étapes `MUST_NOW` sont terminées, ou leur statut est explicitement
  connu.
- Les rapports de validation de `04-build` sont disponibles dans les réponses,
  rapports existants ou manifestes courants.

Pour une modification `LIGHT`, l’utilisateur peut fournir directement l’objectif,
le diff et la validation effectuée.

Si une sous-étape est encore `BLOCKED`, `PARTIAL` ou `NOT_TESTED` sur un critère
`MUST_NOW`, ne clôture pas la fonctionnalité comme terminée.

## Statuts de clôture

Utilise l’un des statuts suivants :

- `FINISHED` : les critères `MUST_NOW` sont satisfaits et les validations requises
  pour le niveau courant sont passées ;
- `FINISHED_WITH_DEBT` : le chemin `MUST_NOW` est satisfaisant, mais une validation
  non bloquante ou une amélioration `SHOULD`/`LATER` reste documentée ;
- `BLOCKED` : un risque MVP, une régression démontrée, une exigence indispensable
  non satisfaite ou une décision propriétaire empêche la clôture ;
- `NOT_READY` : les éléments nécessaires à la clôture sont absents ou incohérents.

Une absence de preuve obligatoire ne peut jamais produire `FINISHED`.

## Ce que ce skill peut modifier

Après validation, il peut modifier uniquement les documents nécessaires à la clôture :

- documentation explicitement prévue dans la spécification ;
- résultat ou rapport de fonctionnalité, si une convention existante le prévoit ;
- documentation d’architecture, contrat, registre ou décision si la fonctionnalité
  les impacte réellement ;
- `docs/rebuild/STATUS.md` uniquement si l’état courant, la gate ou `NEXT_ACTION`
  doivent changer pour cette fonctionnalité ou cette étape ;
- un fichier de commit n’est pas créé : le commit est réalisé par Git si demandé.

Ne modifie jamais :

- une gate publiée ou un résultat historique ;
- un ancien manifeste ou log ;
- `.artifacts/` à la main ;
- une spécification pour masquer une divergence ;
- `ROADMAP.md` sauf si l’ordre des étapes change réellement et que la spécification
  l’exige ;
- du code source pour corriger un échec découvert pendant la clôture.

Les corrections de code retournent vers `04-build`. Les changements de périmètre ou
les exigences excessives retournent vers `01-spec` ou `06-pivot`.

## Lecture minimale

Lis dans cet ordre :

1. `AGENTS.md` et/ou `CLAUDE.md` ;
2. le bloc courant de `docs/rebuild/STATUS.md` ;
3. la spécification ;
4. le plan `STEPS.md` ;
5. les rapports de sous-étapes et les validations disponibles ;
6. `docs/TESTS.md`, `docs/TESTING_GUARDRAILS.md` et la politique MVP si la validation
   finale l’exige ;
7. les documents explicitement listés dans la section documentation de la spec.

Ne relis pas tout l’historique du rebuild. Lis les résultats historiques uniquement
pour vérifier une référence précise ou éviter de réécrire un document publié.

## Déroulement

### 1. Faire l’inventaire de la fonctionnalité

Avant de lancer une validation finale, établis :

- la version de la spécification ;
- les sous-étapes prévues et leur statut ;
- les fichiers créés ou modifiés ;
- les critères `MUST_NOW` satisfaits, ouverts ou non testés ;
- les exigences `SHOULD` et `LATER` reportées ;
- les limites connues ;
- les documents qui doivent être mis à jour.

Ne déduis jamais qu’une sous-étape est terminée uniquement parce que du code existe.

### 2. Vérifier le diff final

Examine le diff de la fonctionnalité et vérifie :

- absence de modification manifestement hors périmètre ;
- cohérence avec la spécification et le plan ;
- absence de données fictives, fallback silencieux ou seuil modifié pour obtenir du
  vert ;
- absence de secret, audio brut, contenu professionnel sensible ou chemin absolu
  dans le code ou les diagnostics ;
- cohérence des textes français via `UIText.t(_:)` ;
- respect des contrats, formats, identifiants et patterns existants ;
- absence de fichier généré ou de preuve ajoutée manuellement.

Si le diff contient une modification étrangère à la fonctionnalité, ne la supprime
pas automatiquement : signale-la et sépare-la du verdict lorsque c’est possible.

### 3. Choisir le niveau de validation

Choisis le niveau le plus faible qui répond à la question de clôture, en tenant compte
de la maturité et du périmètre.

| Situation | Validation attendue |
|---|---|
| Documentation seule | aucune exécution |
| Modification Swift locale | test ciblé si pertinent + `./scripts/build.sh` |
| Modification de configuration ou du projet | `./scripts/build.sh` + `./scripts/build-xcode-parity.sh` |
| Fonctionnalité multi-module ou risque de régression | tests ciblés + build adapté ; `verify.sh` si la politique ou la spec l’exige |
| Clôture d’une étape, changement transverse ou release | `./scripts/verify.sh` |
| Matériel, TCC, scénario manuel ou fournisseur payant | validation manuelle ou décision explicite, jamais une preuve simulée présentée comme réelle |

Ne lance pas `verify.sh` automatiquement pour une petite fonctionnalité locale si
aucune règle de clôture d’étape ou de release ne l’exige.

Avant toute validation qui écrit un manifeste :

- termine les modifications de code ;
- ne modifie plus les sources pendant l’exécution ;
- vérifie que la validation porte sur le dépôt et le projet canoniques.

### 4. Lire les preuves

Pour chaque validation exécutée :

- utilise le manifeste produit par la session courante ;
- vérifie `exitCode`, le succès du build, la stabilité de l’arbre et les chemins du
  dépôt/projet ;
- pour `verify.sh`, vérifie aussi les tests, la parité et `failureCount` ;
- rapporte `testCount` et `failureCount` depuis le manifeste ;
- lis les logs courants en cas d’échec ;
- marque `NOT_RUN` lorsqu’une validation attendue n’a pas pu être exécutée.

Une ancienne preuve ne valide pas la version courante de la fonctionnalité.

### 5. Mettre à jour la documentation

Après une validation satisfaisante :

- mets à jour les documents explicitement prévus dans la spécification ;
- ajoute ou corrige les contrats, registres ou décisions réellement impactés ;
- produis le résultat de l’étape uniquement si la convention existante le demande ;
- conserve l’historique publié et ajoute une nouvelle preuve au lieu de réécrire une
  ancienne validation ;
- inscris la dette reportée dans `VALIDATION-DEBT.md` si le projet le prévoit.

Ne crée pas de documentation uniquement pour remplir une checklist. Une
fonctionnalité locale n’a pas besoin de modifier l’architecture si aucune décision
architecturale n’a été prise.

### 6. Mettre à jour l’état courant

Modifie `docs/rebuild/STATUS.md` uniquement si cette fonctionnalité change réellement :

- l’étape active ;
- une gate ;
- `NEXT_ACTION` ;
- un blocage courant ;
- une dette de validation explicitement suivie.

Respecte la structure existante du fichier. Ne réécris pas son historique et ne
recopie pas son état dans `README.md`, `ROADMAP.md` ou un autre document.

Pour une simple fonctionnalité qui ne clôture pas une étape, indique dans le rapport
que `STATUS.md` n’a pas besoin d’être modifié.

### 7. Décider du commit

Ne committe pas automatiquement.

Un commit peut être créé uniquement si l’utilisateur l’a demandé explicitement ou si
la commande de clôture contient une instruction claire équivalente.

Avant le commit :

- vérifie le diff et les fichiers inclus ;
- exclus les secrets, corpus, audio, logs et preuves générées manuellement ;
- utilise le format de commit du projet ;
- ne mentionne jamais Claude, Codex ou une autre IA dans le message ou les co-auteurs ;
- ne pousse jamais sans demande explicite.

Si aucun commit n’est demandé, retourne `COMMIT: NOT_REQUESTED`.

## Décision de clôture

Évalue les critères dans cet ordre :

1. Les critères `MUST_NOW` sont-ils tous satisfaits ?
2. Les risques MVP réellement bloquants sont-ils absents ?
3. Les validations obligatoires pour le niveau courant sont-elles disponibles et
   passantes ?
4. Les limites, dettes et éléments `LATER` sont-ils documentés ?
5. Les documents et l’état courant sont-ils cohérents ?

Décide ainsi :

- `FINISHED` si les réponses 1 à 5 sont positives ;
- `FINISHED_WITH_DEBT` si seuls des éléments non bloquants restent ouverts et sont
  explicitement documentés ;
- `BLOCKED` si un risque MVP, une régression, une exigence `MUST_NOW` ou une preuve
  obligatoire est en échec ou absente ;
- `NOT_READY` si l’inventaire, le diff ou les sources d’autorité sont incohérents.

Pour une étape de rebuild utilisant deux verdicts, conserve la distinction :

- `MVP_PROGRESSION_GATE` : peut-on continuer ?
- `FULL_VALIDATION_GATE` : la validation complète est-elle passée ou explicitement
  différée avec dette connue ?

Ne transforme pas une dette de validation complète en blocage MVP sans justification
dans la politique ou la spécification.

## Gestion des échecs

`05-finish` est une étape de décision, pas une nouvelle boucle de correction.

Si une validation échoue :

- ne modifie pas immédiatement le code ;
- identifie le critère et la preuve en échec ;
- indique la cause observée et les hypothèses restantes ;
- retourne vers `04-build` pour une correction ciblée, ou vers `06-pivot` si le
  problème concerne le périmètre ou l’approche ;
- ne publie pas `FINISHED`.

Si deux corrections fondées sur la même hypothèse ont déjà échoué, recommande
`06-pivot` directement au lieu de lancer une troisième tentative équivalente.

## Rapport final

Retourne un résumé structuré. Si un template de rapport existe dans le projet,
respecte-le ; sinon utilise ce format :

```text
SPEC_PATH: <chemin>
STEPS_PATH: <chemin ou absent>
STATUS: FINISHED | FINISHED_WITH_DEBT | BLOCKED | NOT_READY
MATURITY: MVP | ALPHA | BETA | COMMERCIAL

MUST_NOW:
- <critère> — PASS | FAIL | NOT_TESTED

VALIDATION:
- Niveau: NONE | TARGETED | BUILD | PARITY | FULL | MANUAL | DEFERRED
- Commande(s): <commande ou N/A>
- Résultat: PASS | FAIL | NOT_RUN
- Manifeste(s): <chemin ou N/A>
- testCount: <valeur ou N/A>
- failureCount: <valeur ou N/A>

FILES_CREATED:
- <chemin> — <raison>

FILES_MODIFIED:
- <chemin> — <raison>

DOCUMENTATION:
- <fichier> — <mise à jour ou N/A>

STATE:
- STATUS.md mis à jour: YES | NO | N/A
- MVP_PROGRESSION_GATE: ACCEPTED | BLOCKED | N/A
- FULL_VALIDATION_GATE: PASSED | DEFERRED_WITH_KNOWN_DEBT | NOT_RUN | N/A

DEBT_AND_LIMITATIONS:
- <élément>

COMMIT:
- CREATED: <hash et message>
- NOT_REQUESTED
- NOT_CREATED: <raison>

NEXT:
- nouvelle fonctionnalité : 01-spec
- sous-étape restante : 04-build
- blocage ou pivot : 06-pivot
- aucune action immédiate
```

Ne prétends pas que la fonctionnalité est commercialisable simplement parce qu’elle
est `FINISHED` au niveau MVP ou alpha. Le niveau de maturité doit rester explicitement
indiqué.
