# implement-remediation-spec

## Quand utiliser ce skill

Utiliser ce skill pour implémenter exactement une spec `Sxx-*.md` du dossier :
`docs/audits/algo-architecture/remediation-specs/`.

Ne pas utiliser ce skill pour corriger, renommer ou réécrire une spec, exécuter
un chapeau ou une archive, ni regrouper plusieurs specs.

## Entrée requise

Exiger une entrée explicite :

```text
SPEC_PATH=docs/audits/algo-architecture/remediation-specs/Sxx-<nom>.md
```

Résoudre le chemin depuis la racine du dépôt. Refuser de continuer si :

- `SPEC_PATH` est absent ou ambigu ;
- le fichier n'existe pas ou sort du dossier `remediation-specs/` ;
- le nom ne correspond pas à `S[0-9][0-9]-*.md` ;
- le nom commence par `ZZ-CHAPEAU-` ou `ZZ-ARCHIVE-` ;
- plusieurs specs sont fournies.

Exception temporaire unique : accepter
`docs/audits/algo-architecture/remediation-specs/FIX-001-recommendation-payload-contract.md`
si ce fichier existe et si la roadmap ou la demande documente encore cette
transition. Ne généraliser cette exception à aucun autre fichier `FIX-*`.

## Interdits

- Ne traiter qu'une seule spec et ne jamais commencer, compléter ou corriger une autre spec.
- Ne jamais exécuter un fichier `ZZ-CHAPEAU-*` ou `ZZ-ARCHIVE-*`.
- Ne jamais modifier, renommer ou corriger les fichiers de spec.
- Ne faire aucune correction opportuniste ni refactor global.
- Ne pas étendre le périmètre au-delà des objectifs, fichiers, tests et critères de `SPEC_PATH`.
- Préserver le legacy selon les règles de compatibilité de la spec.
- Ne pas inventer de backfill, migration, valeur historique ou reconstruction.
- Ne pas ajouter de fallback silencieux, mock, placeholder ou donnée factice.
- Refuser toute ambiguïté avec une erreur contrôlée ou une question ciblée.
- Ne jamais créer de test E2E automatisé.
- Ne jamais imposer Playwright ou Cypress pour un parcours navigateur complet.
- Ne pas lancer une suite globale coûteuse sans justification liée au risque de la spec.

## Procédure

### 1. Préflight

1. Se placer à la racine du dépôt et exécuter `git status --short`.
2. Inventorier les changements préexistants sans les modifier ni les annuler.
3. S'arrêter et demander confirmation en présence de changements inattendus,
   ambigus ou susceptibles de se mélanger à `SPEC_PATH`.
4. S'arrêter si des changements non commités d'une autre remediation spec sont
   présents. En particulier, ne jamais mélanger S02 avec FIX-001.
5. Valider `SPEC_PATH` selon les règles de la section "Entrée requise".
6. Lire `00-PRIORITIZED-CORRECTIONS.md` et confirmer que la spec est exécutable,
   que ses dépendances sont satisfaites et que son exécution respecte l'ordre
   courant de la roadmap. Ne pas implémenter les dépendances manquantes.
7. Lire `AGENTS.md`, `CLAUDE.md` s'ils existent, puis les règles path-scoped qui
   s'appliquent aux fichiers susceptibles d'être modifiés.

### 2. Lecture obligatoire

Avant toute modification :

1. Lire `SPEC_PATH` intégralement, sans se limiter à son prompt final.
2. Lire les dépendances, documents de référence et audits Pxx explicitement
   mentionnés par la spec.
3. Lire les contrats détaillés requis par `AGENTS.md` ou `CLAUDE.md` pour les
   domaines touchés : API, storage, settings, architecture, tests ou docs.
4. Inspecter le code et les tests existants cités par la spec.
5. Utiliser les recherches proposées par la spec, puis compléter avec `rg`
   uniquement pour comprendre le périmètre direct.

### 3. Analyse de périmètre

Extraire de `SPEC_PATH` et reformuler avant de coder :

- objectifs fonctionnels et techniques ;
- invariants et contrats à préserver ;
- dépendances et préconditions ;
- fichiers probablement concernés ;
- hors périmètre explicite ;
- plan d'implémentation ;
- migrations ou compatibilité historique autorisées ;
- tests requis ;
- tests manuels interface ;
- critères d'acceptation et rollback.

Construire une matrice courte `exigence -> fichiers -> tests`. Toute modification
non rattachable à une exigence de la spec est hors périmètre. Si la spec ne
permet pas de trancher une décision qui change un contrat, arrêter et poser une
question ciblée.

### 4. Plan court

Présenter un plan limité à la spec :

1. changements de contrat ou d'invariant ;
2. modifications d'implémentation ;
3. compatibilité et gestion d'erreur ;
4. tests ciblés ;
5. vérification finale.

Ne pas ajouter au plan de travaux réservés à une spec suivante. Si une
dépendance manque, signaler le blocage au lieu de la réaliser.

### 5. Implémentation

- Modifier uniquement les fichiers nécessaires à `SPEC_PATH`.
- Suivre les abstractions et sources de vérité existantes du dépôt.
- Préserver les comportements legacy exigés ; rendre tout statut incomplet ou
  inconnu explicite plutôt que d'inventer une donnée.
- Utiliser des erreurs contrôlées pour les entrées ou états ambigus.
- Appliquer les migrations uniquement si la spec les exige explicitement, avec
  compatibilité et rollback documentés. Aucune migration destructive implicite.
- Garder chaque changement traçable vers une exigence et un critère
  d'acceptation de la spec.
- Ne pas modifier une autre spec, même pour corriger une incohérence découverte.
  La rapporter comme risque ou question séparée.

### 6. Tests

Politique obligatoire :

- tests unitaires : autorisés et attendus selon la spec ;
- tests d'intégration : autorisés et attendus si plusieurs couches sont touchées ;
- tests frontend ciblés de composants ou helpers : autorisés ;
- typecheck et build : autorisés lorsque pertinents ;
- E2E automatisé : interdit ;
- Playwright/Cypress pour un parcours navigateur complet : interdit ;
- validation UI : checklist manuelle uniquement.

Lire les règles de tests applicables avant d'ajouter ou lancer des tests.
Commencer par les tests les plus ciblés, puis élargir selon le risque et les
critères d'acceptation. Utiliser le venv racine pour Python. Ne pas déclarer un
test réussi s'il n'a pas été exécuté ; documenter tout test impossible à lancer.

### 7. Tests manuels interface

Si la spec touche l'interface, produire ou reprendre une courte checklist
manuelle couvrant les états nominaux, erreurs, chargement, données absentes et
régressions visibles demandés par la spec. Ne pas automatiser le parcours
navigateur et ne pas introduire Playwright/Cypress.

Si l'interface n'est pas concernée, indiquer explicitement que cette section est
non applicable.

### 8. Rapport final

1. Exécuter `git status --short`.
2. Vérifier que chaque fichier modifié appartient au périmètre de `SPEC_PATH`.
3. Répondre avec :
   - spec exécutée et confirmation qu'elle est la seule traitée ;
   - résumé de l'implémentation ;
   - fichiers modifiés ;
   - invariants ou contrats ajoutés/modifiés ;
   - tests ajoutés ou modifiés ;
   - commandes exécutées et résultats ;
   - checklist UI manuelle ou mention non applicable ;
   - migrations, changements storage et compatibilité legacy ;
   - risques résiduels, ambiguïtés ou validations non exécutées ;
   - résultat final exact de `git status --short`.

Ne pas masquer les changements préexistants : les distinguer explicitement des
changements réalisés pour la spec.

## Template de prompt interne

```text
Nous travaillons sur le projet aimoto.

Objectif :
Implémenter exclusivement la spec suivante :

SPEC_PATH

Mantra qualité :
On veut une app qui soit fiable, robuste, et facilement maintenable. La qualité de l'architecture et du code n'est pas négociable : on prend le temps qu'il faut.

Règle principale :
Exécuter uniquement SPEC_PATH.
Ne traiter aucune autre spec.
Ne faire aucune correction opportuniste.

Avant toute modification :
1. Exécuter `git status --short`.
2. Vérifier que le worktree ne contient pas de changements inattendus.
3. Lire intégralement SPEC_PATH.
4. Lire `00-PRIORITIZED-CORRECTIONS.md`.
5. Lire les dépendances et audits explicitement mentionnés par SPEC_PATH.
6. Lire AGENTS.md / CLAUDE.md et règles applicables.
7. Rechercher les fichiers probablement concernés à partir de la section 8 de la spec.

Périmètre :
Extraire depuis SPEC_PATH :
- objectifs fonctionnels ;
- objectifs techniques ;
- fichiers concernés ;
- hors périmètre ;
- plan d'implémentation ;
- tests ;
- critères d'acceptation ;
- dépendances.

Interdits :
- aucune autre spec ;
- aucun fichier `ZZ-CHAPEAU-*` ;
- aucun fichier `ZZ-ARCHIVE-*` ;
- aucun refactor opportuniste ;
- aucun test E2E automatisé ;
- aucun Playwright/Cypress navigateur complet ;
- aucun fallback silencieux ;
- aucune migration destructive ;
- aucun backfill inventé.

Tests :
- unitaires et intégration selon la spec ;
- frontend ciblé si pertinent ;
- typecheck/build si pertinent ;
- checklist manuelle UI si l'interface est concernée.

À la fin :
- `git status --short` ;
- résumé ;
- fichiers modifiés ;
- tests exécutés ;
- résultats ;
- risques résiduels ;
- confirmation qu'une seule spec a été traitée.
```

## Exemple calibré : S02 grid lifecycle

Cet exemple fixe le niveau de précision attendu pour S02 uniquement. Ne jamais
l'appliquer tel quel à une autre spec. Pour toute autre valeur de `SPEC_PATH`,
extraire le périmètre, les fichiers, les hors périmètre, les tests, les
dépendances et les critères d'acceptation directement depuis cette spec.

```text
Nous travaillons sur le projet aimoto.

Objectif :
Implémenter exclusivement la spec suivante :

docs/audits/algo-architecture/remediation-specs/S02-grid-transactional-lifecycle.md

Mantra qualité :
On veut une app qui soit fiable, robuste, et facilement maintenable. La qualité de l'architecture et du code n'est pas négociable : on prend le temps qu'il faut.

Contexte :
S02 correspond à l'ancienne FIX-005 — Lifecycle transactionnel des grids.

La correction vise à rendre atomiques et réconciliables :
- la création d'une grid ;
- la création des runs enfants ;
- la création des queue_jobs ;
- l'annulation ;
- la persistance des résultats ;
- les compteurs ;
- la finalisation ;
- la reprise après crash.

Règle principale :
Exécuter uniquement S02.
Ne traiter aucune autre spec.
Ne faire aucune correction opportuniste.

Avant toute modification :
1. Exécute :
   git status --short

2. Vérifie que le worktree ne contient pas de changements inattendus.

3. Si des changements liés à FIX-001 sont encore non commités, arrête-toi et demande confirmation.
   Ne mélange pas S02 avec FIX-001.

4. Lis intégralement :
   docs/audits/algo-architecture/remediation-specs/S02-grid-transactional-lifecycle.md

5. Lis aussi :
   - docs/audits/algo-architecture/00-AUDIT-PLAN.md
   - docs/audits/algo-architecture/P06-GRID-ORCHESTRATION.md
   - docs/audits/algo-architecture/P13-TARGET-ARCHITECTURE.md
   - AGENTS.md ou CLAUDE.md si présents
   - les règles storage/tests applicables

6. Inspecte les fichiers probablement concernés :
   - backend/app/main.py
   - backend/app/storage.py
   - backend/app/worker.py
   - backend/app/algo/grid_worker.py
   - backend/app/algo/analytics/grid_finalization.py
   - tests API/storage/worker/grid/finalization existants

Commande de recherche utile :
rg -n "grid_search|queue_jobs|grid_finalization|cancel|finalize|algo_runs|grid_status|reconcile|lock" backend/app backend/tests

Périmètre strict S02 :
- transaction unique `grid + runs + queue_jobs` ;
- annulation complète avec invalidation des queue_jobs ;
- machine d'état explicite des grids ;
- recovery startup des grids incohérentes ;
- réparation des compteurs ;
- blocage du dispatch des grids terminales ;
- locks de finalisation récupérables ;
- tests de rollback, crash, cancel et recovery.

Hors périmètre :
- ne pas modifier le dispatch moteur de S09 ;
- ne pas modifier le descriptor de S08 ;
- ne pas modifier les métriques de S16/S17 ;
- ne pas traiter les artefacts WFA de S03 ;
- ne pas traiter les tests cross-family de S10/S11/S14/S18/S20 ;
- ne pas ajouter de nouvelle stratégie ;
- ne pas changer de base de données ;
- ne pas implémenter fairness multi-grid ;
- ne pas faire de refactor global storage/worker hors S02.

Implémentation attendue :
1. Formaliser les états et transitions
   Définir clairement les états autorisés d'une grid et les transitions valides.
   Documenter les invariants dans le code ou les tests.

2. Création transactionnelle
   La création d'une grid doit être atomique :
   - grid_searches ;
   - algo_runs / runs enfants ;
   - queue_jobs ;
   - intent / metadata nécessaires.

   Si une erreur arrive au K-ième enfant, toute la création doit être rollback.

3. Annulation transactionnelle
   L'annulation doit :
   - marquer la grid comme annulée ;
   - empêcher tout queue_job non démarré d'être exécuté ;
   - ne pas tuer silencieusement un job déjà RUNNING sans protocole dédié ;
   - être idempotente.

4. Persistance résultat + compteurs
   La persistance d'un résultat terminal doit rester cohérente avec :
   - run ;
   - algo_run ;
   - queue_job ;
   - compteurs grid ;
   - statut de finalisation.

   Les compteurs doivent être réparables depuis les runs.

5. Recovery startup
   Au démarrage, ajouter ou renforcer une réconciliation :
   - grids non terminales ;
   - runs terminaux mais compteurs incohérents ;
   - queue_jobs orphelins ;
   - locks de finalisation stale ;
   - finalisation à retenter.

   Prévoir un mode diagnostic/dry-run si adapté.

6. Finalisation idempotente
   La finalisation doit être retentable.
   Un lock stale doit pouvoir être libéré selon un TTL configurable ou une règle explicite.
   Un lock actif ne doit pas être volé.

7. Tests obligatoires
   Ajouter ou modifier les tests unitaires/intégration nécessaires.

Tests minimum attendus :
- erreur au K-ième enfant → rollback total ;
- cancel → aucun queue_job queued ne reste exécutable ;
- crash après job DONE → compteur réparé et finalisation retentée ;
- recovery aligne `runs`, `algo_runs`, `queue_jobs`, `grid_searches` ;
- grid terminale ignorée par le worker ;
- lock stale libéré ;
- lock actif préservé ;
- intent présent dès le commit initial ;
- finalisation idempotente.

Pas de test E2E automatisé.
Pas de Playwright/Cypress.
Si une validation interface est nécessaire, ajouter uniquement une courte checklist de test manuel.

Commandes de test :
Adapter selon les tests existants.

Exemples possibles :
cd backend && ../.venv/bin/pytest -q tests -k "grid and (transaction or cancel or recovery or finalization)"
cd backend && ../.venv/bin/pytest -q tests -k "queue_jobs or grid_searches or grid_finalization"

Ne lance pas une suite globale coûteuse sans expliquer pourquoi.

Critères d'acceptation :
- Aucun parent ou enfant orphelin après échec de création.
- Aucun run annulé non démarré n'est dispatché.
- Les grids bloquées sont réparées au restart.
- La finalisation est idempotente et retentable.
- Les invariants SQL ou storage sont couverts par tests d'intégration.
- Les scénarios H1 passent :
  - rollback au run K ;
  - cancel sans ré-exécution ;
  - recovery compteur après crash.
- Aucune autre spec n'a été traitée.
- Aucun changement opportuniste hors S02.

À la fin :
1. Exécute :
   git status --short

2. Réponds avec :
   - résumé de la correction S02 ;
   - fichiers modifiés ;
   - invariants ajoutés ;
   - tests ajoutés/modifiés ;
   - commandes exécutées et résultats ;
   - éventuelles migrations ou changements storage ;
   - risques résiduels ;
   - confirmation qu'aucune autre spec n'a été traitée ;
   - résultat final de `git status --short`.
```
