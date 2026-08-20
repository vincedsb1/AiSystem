---
name: 01-spec
description: Créer ou réviser une spécification fonctionnelle Suggst, avec un périmètre MVP explicite et des critères d’acceptation vérifiables sans sur-spécifier la solution.
---

# 01-spec — Spécification fonctionnelle

## Rôle

Tu aides à transformer une idée de fonctionnalité en spécification fonctionnelle
compréhensible, limitée et implémentable.

Cette étape ne code pas la fonctionnalité. Elle ne lance pas de build, ne lance pas
`verify.sh`, ne modifie pas `STATUS.md` et ne crée pas de commit.

La spécification doit permettre à `02-check` de décider si le besoin est suffisamment
clair, puis à `03-split` de le découper en sous-étapes.

## Quand utiliser ce skill

Utilise `01-spec` pour :

- une nouvelle fonctionnalité ;
- une évolution importante d’un comportement existant ;
- une modification qui touche plusieurs écrans, contrats ou modules ;
- la révision d’une spécification après un audit ou un blocage ;
- la réduction d’une exigence devenue trop ambitieuse pour le niveau de maturité courant.

Pour une correction très locale et évidente, il est possible de passer directement à
`04-build`, puis à `05-finish`.

## Règle principale : le MVP doit pouvoir avancer

Pour chaque exigence, classe-la dans une seule catégorie :

- `MUST_NOW` : indispensable au parcours principal du niveau de maturité courant ;
- `SHOULD` : utile, mais ne doit pas bloquer l’avancement ;
- `LATER` : amélioration postérieure au MVP ou à l’alpha ;
- `OUT` : explicitement exclue du périmètre.

Une exigence `SHOULD` ou `LATER` ne doit jamais rendre la spécification non
implémentable. Si la fonctionnalité devient trop ambitieuse, réduis le périmètre au
lieu d’ajouter des contrôles ou des exigences.

Le niveau de maturité est, par ordre de priorité :

1. celui indiqué par l’utilisateur ;
2. celui qui ressort de `STATUS.md` ;
3. une question unique à l’utilisateur si les deux sont indéterminables.

Ne remplace jamais silencieusement une exigence MVP par une exigence alpha, bêta ou
commerciale.

## Lecture minimale du projet

Lis uniquement ce qui est nécessaire, dans cet ordre :

1. `AGENTS.md` et/ou `CLAUDE.md` pour les règles stables ;
2. le début ou le bloc courant de `docs/rebuild/STATUS.md` pour connaître l’étape,
   les gates et le périmètre actuel ;
3. `docs/rebuild/README.md` et `ROADMAP.md` si la place de la fonctionnalité dans le
   rebuild n’est pas claire ;
4. `FUNCTIONAL_MVP_REFERENCE.md` si la fonctionnalité concerne le comportement produit ;
5. les contrats, décisions, briques, spécifications et résultats directement liés ;
6. les fichiers de code servant d’ancres pour comprendre le comportement existant.

Ne lis pas intégralement l’historique de `STATUS.md`, les anciens résultats ou les
manifestes si une recherche ciblée suffit.

Dans Suggst, ne suppose jamais l’existence de `docs/specs/`, de `.state.json`, d’un
backend ou d’un frontend JavaScript. Utilise les conventions réelles de
`docs/rebuild/`.

## Déterminer le fichier de spécification

- Si l’utilisateur donne un chemin, utilise ce chemin.
- Si l’utilisateur donne un numéro d’étape, utilise la spécification correspondante
  dans `docs/rebuild/steps/STEP-XX-SPEC.md`.
- Si un fichier de spécification existant est explicitement mentionné, révise ce fichier
  en conservant sa structure compatible.
- Si aucun emplacement n’est identifiable, pose une seule question sur l’étape ou le
  chemin cible avant d’écrire.

Ne crée pas un second système de spécifications et ne déplace pas les spécifications
existantes sans demande explicite.

## Déroulement

### 1. Comprendre le besoin

À partir de la demande et du dépôt :

- reformule le résultat attendu pour l’utilisateur ;
- identifie le problème actuel ;
- distingue les faits observés, les décisions déjà prises et les hypothèses ;
- indique les fichiers ou modules concernés avec un niveau de confiance ;
- vérifie si une fonctionnalité similaire existe déjà.

Ne pose pas une question dont la réponse est déjà lisible dans le dépôt.

### 2. Poser les questions bloquantes

Pose au maximum huit questions, uniquement si leur réponse change réellement la
spécification ou son périmètre.

Privilégie les choix simples :

```text
Q1 [Périmètre] ...
A) ...
B) ...
C) ...
```

Si aucune question n’est bloquante, indique explicitement : `Questions bloquantes :
aucune`.

### 3. Rédiger ou réviser la spécification

Écris ou mets à jour uniquement le fichier de spécification ciblé.

Si le fichier existe déjà :

- conserve les décisions valides ;
- augmente la version ;
- ajoute une entrée au changelog ;
- ne réécris pas les sections sans raison ;
- intègre les retours de `02-check` ou `06-pivot` item par item lorsque ceux-ci sont
  fournis.

Ne modifie jamais un résultat de validation, une gate publiée ou un manifeste
historique pour faire correspondre la spécification.

## Structure recommandée de la spécification

Adapte cette structure au projet et au niveau de complexité. Une section non pertinente
peut contenir `N/A — raison`. Ne remplis pas artificiellement une section pour donner
une impression de complétude.

```md
---
id: <identifiant>
version: <version>
status: DRAFT
maturity: MVP | ALPHA | BETA | COMMERCIAL
scope: LIGHT | STANDARD | RISKY
last_updated: <YYYY-MM-DD>
---

# <Titre de la fonctionnalité>

## 1. Résultat utilisateur

## 2. Problème actuel

## 3. Périmètre
### MUST_NOW
### SHOULD
### LATER
### OUT

## 4. Comportement fonctionnel

## 5. États et cas limites

## 6. Données, contrats et source de vérité

## 7. Ancres du dépôt

## 8. Critères d’acceptation

## 9. Validation proportionnelle

## 10. Documentation à mettre à jour

## 11. Risques et décisions ouvertes

## 12. Questions restantes

## Changelog
```

## Règles de rédaction

- Les critères d’acceptation décrivent un résultat observable et vérifiable.
- Le chemin principal doit être clair avant de détailler les cas secondaires.
- Les erreurs, états vides, chargement et récupération ne sont détaillés que lorsqu’ils
  sont pertinents pour la fonctionnalité.
- Les schémas, wireframes et diagrammes sont facultatifs ; ajoute-les seulement s’ils
  clarifient réellement un flux ou un état.
- Ne transforme pas la spécification en plan d’implémentation détaillé : le découpage
  appartient à `03-split`.
- Mentionne les fichiers probables, mais ne transforme pas une liste de fichiers en
  allowlist artificielle avant l’analyse de `03-split`.
- Pour une modification du cockpit, vérifie la portée de la règle read-only dans les
  documents actuels et signale toute décision propriétaire nécessaire. Ne suppose ni
  qu’elle est permanente ni qu’elle est levée.
- Pour une fonctionnalité avec fournisseur distant, audio, données sensibles ou coût,
  indique les limites et les conditions d’exécution sans rendre automatiquement toute
  la fonctionnalité bloquante.
- Préfère une solution simple et cohérente avec les patterns existants à une nouvelle
  abstraction prématurée.

## Validation de la spécification

Avant de terminer, vérifie seulement :

- le résultat utilisateur est compréhensible ;
- le périmètre `MUST_NOW` est limité ;
- les exclusions sont explicites ;
- les critères d’acceptation sont observables ;
- les hypothèses importantes sont signalées ;
- les questions réellement bloquantes sont listées ;
- aucun conflit avec `STATUS.md`, les règles du projet ou un contrat existant n’est
  laissé implicite.

Cette vérification est documentaire. Elle ne remplace pas `02-check` et ne lance aucun
test ou build.

## Arrêt obligatoire

Arrête-toi et signale le problème sans écrire de code si :

- l’étape ou le fichier cible ne peut pas être identifié ;
- `STATUS.md` et une autre source d’autorité se contredisent sur le périmètre ;
- un artefact cité comme existant est absent ;
- la demande exige une modification d’une gate ou d’une preuve historique ;
- la fonctionnalité ne peut être rendue compatible avec le niveau de maturité courant
  sans décision de l’utilisateur ;
- une exigence excessive empêche le chemin MVP d’être défini.

Dans ce dernier cas, propose une réduction `MUST_NOW` / `LATER` ou recommande `06-pivot`.

## Réponse finale

Après l’écriture ou la révision, retourne un résumé court :

```text
SPEC_PATH: <chemin>
VERSION: <version>
MATURITY: MVP | ALPHA | BETA | COMMERCIAL
SCOPE: LIGHT | STANDARD | RISKY
MUST_NOW: <résumé>
LATER: <résumé ou aucun>
QUESTIONS_BLOCKING: <nombre>
STATUS: DRAFT | READY_FOR_CHECK | BLOCKED
NEXT: 02-check | réponse utilisateur | 06-pivot
```

Ne prétends pas que la fonctionnalité est implémentée ou validée.
