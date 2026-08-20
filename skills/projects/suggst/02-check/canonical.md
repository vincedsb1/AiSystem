---
name: 02-check
description: Vérifier une spécification fonctionnelle Suggst, identifier les vrais blocages et donner un verdict READY, REVISE ou BLOCKED sans imposer de sur-qualité au MVP.
---

# 02-check — Vérification de la spécification

## Rôle

Tu relis une spécification produite par `01-spec` et tu détermines si elle est
suffisamment claire et réaliste pour être découpée par `03-split`.

Tu ne réécris pas la spécification, tu ne codes pas la fonctionnalité et tu ne
lances aucun build ou test. Tu produis un avis structuré, éventuellement enregistré
dans un fichier `CHECK.md` à côté de la spécification.

Le but est d’éviter deux erreurs opposées :

- commencer à coder avec une spécification réellement ambiguë ;
- bloquer une fonctionnalité MVP pour des exigences secondaires ou prématurées.

## Verdicts

Utilise exactement l’un des verdicts suivants :

- `READY` : la spécification peut passer à `03-split` ;
- `REVISE` : la spécification doit être corrigée par `01-spec` ;
- `BLOCKED` : le contrôle ne peut pas être mené correctement ou dépend d’une
  décision propriétaire absente.

La note est indicative. Elle ne peut jamais transformer un `BLOCKER` en `READY`.

Repère par défaut :

- `80–100` : qualité généralement suffisante, sous réserve de l’absence de blocker ;
- `60–79` : révision recommandée ;
- `<60` : révision nécessaire.

Le verdict final dépend surtout des blockers, du périmètre `MUST_NOW` et de la
testabilité des critères d’acceptation. Une spécification peut être `READY` avec une
dette explicitement classée `SHOULD` ou `LATER`.

Règle pratique par défaut :

- `READY` si la note est au moins `80`, qu’il n’y a aucun `BLOCKER`, qu’aucun point
  `MAJOR` ne concerne un élément `MUST_NOW` et qu’aucune question bloquante ne reste
  ouverte ;
- `REVISE` dans les autres cas où le contrôle a pu être mené.

Le seuil `80` est un repère de départ, pas une exigence de perfection. Il pourra être
ajusté après quelques fonctionnalités réelles.

## Quand utiliser ce skill

Utilise `02-check` :

- après la première rédaction de `01-spec` ;
- après une révision de la spécification ;
- après une décision de réduction de périmètre ;
- avant de lancer `03-split` ;
- lorsqu’une spécification semble trop ambitieuse ou contradictoire.

Pour une correction locale et évidente qui passe directement par `04-build`, ce
contrôle complet peut être omis.

## Lecture minimale

Lis dans cet ordre :

1. `AGENTS.md` et/ou `CLAUDE.md` pour les règles stables ;
2. le bloc courant de `docs/rebuild/STATUS.md` pour le niveau de maturité, l’étape
   active et les limites connues ;
3. la spécification complète à contrôler ;
4. `docs/rebuild/README.md` et `ROADMAP.md` uniquement si le rattachement de la
   spécification au rebuild n’est pas clair ;
5. les contrats, décisions, briques et ancres de code directement cités ;
6. `docs/TESTS.md`, `docs/TESTING_GUARDRAILS.md` ou
   `POLICY-MVP-VALIDATION.md` seulement lorsqu’ils sont pertinents pour la validation.

Ne relis pas toute l’histoire de `STATUS.md`, les anciens résultats ou les manifestes
si une recherche ciblée suffit.

Dans Suggst, ne suppose pas l’existence de `docs/specs/`, `.state.json`, d’un backend
ou d’un frontend JavaScript.

## Déterminer la spécification à contrôler

- Si l’utilisateur donne un chemin, utilise-le.
- Sinon, utilise la spécification indiquée par le contexte courant ou la dernière
  spécification produite par `01-spec`.
- Si plusieurs spécifications sont candidates, demande laquelle contrôler.
- Ne sélectionne jamais un fichier uniquement parce qu’il est le plus récent ou parce
  que son nom ressemble à l’objectif.

Vérifie la version de la spécification. Si un `CHECK.md` existe déjà pour une version
antérieure, il ne vaut pas automatiquement pour la nouvelle version.

## Déroulement du contrôle

### 1. Vérifier le cadrage

Contrôle que la spécification indique clairement :

- le résultat attendu pour l’utilisateur ;
- le problème traité ;
- le niveau de maturité (`MVP`, `ALPHA`, `BETA` ou `COMMERCIAL`) ;
- les exigences `MUST_NOW` ;
- les éléments `SHOULD`, `LATER` et `OUT` ;
- ce qui est explicitement hors périmètre.

Une exigence non indispensable au parcours principal ne doit pas être classée
`MUST_NOW` sans justification.

### 2. Vérifier la cohérence fonctionnelle

Contrôle que :

- les comportements décrits ne se contredisent pas ;
- les états importants sont couverts lorsqu’ils sont pertinents ;
- les cas limites critiques sont identifiés ;
- les erreurs attendues ont un comportement défini ;
- la source de vérité des données est claire lorsqu’il y en a une ;
- les contrats existants ne sont pas contredits ;
- la spécification ne dépend pas d’un artefact absent ou obsolète.

Ne demande pas une exhaustivité théorique pour une fonctionnalité simple.

### 3. Vérifier la faisabilité dans Suggst

À partir des ancres et de la documentation :

- vérifie que les modules ou écrans cités existent ;
- vérifie que les patterns nécessaires existent ou sont raisonnablement dérivables ;
- signale les conflits avec `AGENTS.md`, `CLAUDE.md`, `STATUS.md`, les contrats ou
  les décisions ;
- vérifie que la solution proposée ne suppose pas une architecture absente ;
- vérifie que les exigences de coût, de confidentialité, d’audio ou de fournisseur
  sont explicites lorsqu’elles s’appliquent.

Ne rejette pas une spécification uniquement parce qu’elle ne choisit pas encore le
détail d’implémentation. Le choix détaillé appartient à `03-split` et `04-build`.

### 4. Vérifier les critères d’acceptation

Chaque critère `MUST_NOW` doit être :

- observable par un utilisateur, un test ou une vérification manuelle définie ;
- suffisamment précis pour distinguer succès et échec ;
- compatible avec le niveau de maturité courant ;
- associé à une validation proportionnelle.

Un critère qui exige une preuve coûteuse, statistiquement parfaite ou non disponible
doit être reclassé `SHOULD`, `LATER` ou `VALIDATION_DEBT` s’il ne protège pas un risque
MVP réel.

### 5. Challenger les exigences

Pose implicitement les questions suivantes pour chaque exigence importante :

- Est-elle nécessaire au parcours principal ?
- Quel est le risque si elle est reportée ?
- Peut-elle être simplifiée sans rendre la fonctionnalité fausse ou inutilisable ?
- Est-elle une exigence produit ou seulement une préférence d’implémentation ?
- Est-elle déjà couverte par une règle existante ?

Si une exigence paraît trop élevée, ne la supprime pas silencieusement. Signale-la
comme proposition de réduction et recommande `01-spec` ou `06-pivot`.

## Classification des findings

Chaque finding doit avoir un identifiant, une sévérité, une catégorie et une action.

Pour rester actionnable, limite le rapport à trois `BLOCKER`, cinq `MAJOR` et cinq
`MINOR` ou `LATER`. Regroupe les observations qui ont la même cause. Ne crée pas de
finding pour une préférence stylistique ou une amélioration qui ne change ni le
résultat utilisateur ni le risque du niveau de maturité courant.

### `BLOCKER`

À utiliser uniquement si :

- le résultat utilisateur est indéterminable ;
- deux exigences se contredisent ;
- une décision propriétaire est indispensable ;
- une dépendance ou un artefact cité n’existe pas ;
- un critère `MUST_NOW` est impossible à vérifier ;
- le chemin principal est inutilisable, dangereux ou incompatible avec une règle
  stricte du projet.

### `MAJOR`

Problème important qui risque de provoquer une reprise ou une mauvaise implémentation,
mais qui peut être corrigé dans `01-spec` sans changer l’objectif général.

### `MINOR`

Amélioration de clarté, cas secondaire ou dette documentaire qui ne doit pas bloquer
`03-split` si le périmètre principal reste clair.

### `LATER`

Exigence utile mais explicitement reportable au regard du niveau de maturité courant.
Elle ne bloque pas le MVP ou l’alpha.

Catégories autorisées :

```text
Scope | UX | Behavior | States | Data | Contracts | Architecture | Tests |
Docs | Risk | Security | Cost | Performance | Compatibility | MVP
```

Format obligatoire :

```md
### C-001 [BLOCKER] [Scope]
**What:** ...
**Evidence:** ...
**Why it matters:** ...
**Recommended action:** ...
**Target section:** `## ...`
```

## Rapport de contrôle

Si la spécification possède un dossier identifiable, écris le rapport dans le même
dossier :

- `STEP-XX-SPEC.md` → `STEP-XX-CHECK.md` ;
- `<slug>.md` → `<slug>-CHECK.md`.

Si le chemin de sortie est ambigu, ne crée pas un nouveau dossier : retourne le
rapport dans la réponse et demande le chemin à utiliser.

Le rapport doit respecter cette structure :

```md
---
id: <identifiant>
spec_path: <chemin>
spec_version: <version>
status: READY | REVISE | BLOCKED
score: <0-100>
maturity: MVP | ALPHA | BETA | COMMERCIAL
checked_at: <YYYY-MM-DD>
---

# Check — <identifiant>

## Verdict

## Résumé

## Blockers

## Points majeurs

## Points mineurs et dette reportable

## Décisions MVP

## Questions restantes

## Recommandation
```

Le rapport doit indiquer explicitement :

- le nombre de blockers, points majeurs et points mineurs ;
- les exigences reclassées `LATER` ou `VALIDATION_DEBT` ;
- les questions qui nécessitent réellement l’utilisateur ;
- si `03-split` peut commencer.

Ne modifie pas la spécification pendant ce contrôle. La révision est faite par
`01-spec` à partir du rapport.

## Revue indépendante optionnelle

Par défaut, un seul contrôle structuré suffit.

Une seconde revue par Claude, Codex ou une autre IA est pertinente uniquement si :

- la spécification est classée `RISKY` ;
- elle touche l’audio, les données sensibles, un contrat critique ou un coût réel ;
- l’utilisateur demande explicitement un challenge indépendant.

Dans ce cas :

- transmets exactement la version contrôlée ;
- demande des findings, pas une réécriture ;
- conserve les deux avis séparés ;
- ne transforme pas automatiquement un finding en blocker ;
- laisse la décision de périmètre à `01-spec` et la clôture à `05-finish`.

## Arrêt obligatoire

Retourne `BLOCKED` sans lancer d’autre action si :

- la spécification ou sa version ne peut pas être identifiée ;
- `STATUS.md` et la spécification se contredisent sur l’étape ou le périmètre ;
- une source d’autorité citée est absente ;
- un fichier ou artefact nécessaire n’existe pas ;
- le contrôle nécessiterait de modifier du code, une gate ou une preuve historique ;
- une décision propriétaire est nécessaire pour poursuivre.

Dans ces cas, indique l’action minimale attendue : répondre à une question, corriger
`01-spec` ou utiliser `06-pivot`.

## Réponse finale

Retourne un résumé court :

```text
SPEC_PATH: <chemin>
CHECK_PATH: <chemin ou réponse uniquement>
SPEC_VERSION: <version>
SCORE: <0-100>
VERDICT: READY | REVISE | BLOCKED
BLOCKERS: <nombre>
MAJORS: <nombre>
MINORS_OR_LATER: <nombre>
MVP_DECISION: CONTINUE | REDUCE_SCOPE | ASK_OWNER
NEXT: 03-split | 01-spec | 06-pivot | réponse utilisateur
```

Ne prétends pas que la fonctionnalité est implémentée, testée ou validée.
