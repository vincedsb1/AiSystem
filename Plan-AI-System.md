# Plan complet actualisé — AI System / AIMOTO

## Objectif

Créer un système centralisé pour gérer, versionner, auditer et synchroniser tes instructions IA, skills Claude Code, skills Codex, commandes, règles, hooks et contextes projet.

Le but n’est pas seulement de “ranger les fichiers”, mais de créer un système durable qui permet de :

- détecter les divergences entre Claude et Codex ;
- identifier les skills obsolètes ;
- éviter les fallbacks silencieux ;
- maintenir la documentation IA utile ;
- démarrer de nouvelles conversations avec le bon contexte ;
- améliorer progressivement tes skills après chaque tâche.


## Décision d’architecture

Créer une source de vérité centrale :

/Users/vincentdesbrosses/Documents/Misc/ai-system

Ce dossier devient le centre de pilotage.

Les projets comme AIMOTO restent les lieux d’exécution.

Principe :

- ai-system = source de vérité, audit, templates, scripts, rapports.
- aimoto = projet consommateur avec exports Claude/Codex.
- Claude/Codex ne doivent plus être modifiés manuellement à terme.
- Les exports locaux seront générés ou vérifiés depuis ai-system.


## Structure cible

/Users/vincentdesbrosses/Documents/Misc/ai-system
├── skills-registry.yml
├── scripts
│   ├── ai_inventory.py
│   ├── ai_doctor.py
│   └── sync_skills.py
├── reports
│   ├── ai-inventory.latest.json
│   ├── ai-inventory.latest.md
│   ├── ai-doctor.latest.json
│   └── ai-doctor.latest.md
├── docs
│   ├── AI-SYSTEM-CONVENTIONS.md
│   ├── SKILL-VERSIONING.md
│   └── SYNC-POLICY.md
├── templates
│   ├── skill-frontmatter.yml
│   ├── claude-command.md
│   └── codex-skill.md
└── skills
    ├── shared
    │   ├── implement
    │   ├── commit
    │   └── create-doc
    └── projects
        └── aimoto
            ├── new-strategy
            ├── update-strategy
            └── analyse-signal


## Phase 1 — Inventaire de l’existant

Objectif :
observer l’état actuel sans rien modifier.

Livrables :
- skills-registry.yml
- scripts/ai_inventory.py
- reports/ai-inventory.latest.json
- reports/ai-inventory.latest.md

Résultat attendu :
- liste des commands Claude ;
- liste des skills Codex ;
- détection des paires Claude/Codex ;
- détection des symlinks ;
- détection des backups ;
- détection des versions manquantes ;
- détection des fallbacks suspects ;
- première liste d’actions prioritaires.


## Phase 2 — Standardisation des métadonnées

Objectif :
ajouter un frontmatter standard à chaque artifact important.

Champs cibles :
- name
- artifact_type
- scope
- project
- domain
- version
- status
- source_of_truth
- compatibility
- guards

Priorité :
1. implement
2. new-strategy
3. update-strategy
4. commit
5. create-doc


## Phase 3 — Source canonique et exports

Objectif :
ne plus maintenir manuellement Claude et Codex.

Principe :
- canonical.md = source de vérité
- claude.md = export Claude
- codex.md = export Codex
- sync_skills.py = génération/synchronisation

Exemple :
ai-system/skills/projects/aimoto/new-strategy/canonical.md
→ AIMOTO/.claude/commands/new-strategy.md
→ AIMOTO/.agents/skills/new-strategy/SKILL.md


## Phase 4 — ai_doctor.py

Objectif :
auditer la qualité, pas seulement l’inventaire.

Détections :
- fallback implicite ;
- skill shared contenant du spécifique AIMOTO ;
- version identique avec hash différent ;
- version différente avec contenu identique ;
- command Claude sans équivalent Codex ;
- skill Codex sans équivalent Claude ;
- symlink cassé ;
- backup actif ;
- AGENTS.md / CLAUDE.md divergents ;
- doc architecture potentiellement obsolète.


## Phase 5 — Refactor des skills critiques

Priorités :

1. update-strategy
   - supprimer le fallback MMXM implicite ;
   - forcer strategy=<name> si ambigu ;
   - séparer orchestrateur universel et adapters spécifiques.

2. new-strategy
   - utiliser la version Claude comme base canonique ;
   - enrichir l’export Codex ;
   - préserver le format de sortie obligatoire.

3. implement
   - passer en shared officiel ;
   - conserver project-config.md comme source locale des conventions.

4. commit
   - extraire le doc-sync dans une commande séparée.

5. create-doc
   - renforcer la règle : documentation utile pour IA, pas documentation bruitée.


## Phase 6 — Context packs AIMOTO

Créer :

docs/context/forecasting-context.md
docs/context/backtesting-context.md
docs/context/strategy-improvement-loop-context.md
docs/context/ai-maintenance-context.md

Objectif :
démarrer une nouvelle conversation avec le bon contexte sans charger tout le repo.


## Phase 7 — Documentation IA maintenable

Objectif :
rendre AGENTS.md et CLAUDE.md plus courts.

Ils doivent pointer vers :
- docs/ARCHITECTURE.md
- docs/context/*
- .claude/project-config.md
- skills pertinents

Ils ne doivent pas tout contenir directement.


## Phase 8 — Boucle post-tâche

Créer :

/ai-post-task-review

Objectif :
après une correction ou une implémentation, vérifier :

- code modifié ;
- documentation à mettre à jour ;
- architecture impactée ;
- context pack à rafraîchir ;
- skill utilisé à améliorer ;
- fallback ou hypothèse dangereuse rencontrée ;
- règle à ajouter ou supprimer.


## Phase 9 — Extension aux autres projets — TERMINÉE

Une fois AIMOTO fiable :

- InterviewOS
- intrai
- linkedin-ia-comments
- Pylaa
- Pylot
- Skriipt
- Spotter
- suggst
- truthify

Tous ces projets sont maintenant activés dans le registre. Chacun reçoit
uniquement les skills `shared.*` déclarés dans `install_shared_skills`. Les
commandes Claude-only justifiées sont encodées individuellement dans
`pairing_exceptions`; aucun skill project-specific étranger n'est exporté.


## Phase 10 — Consolidation multi-projets — TERMINÉE

Objectif :
rendre les rapports Inventory et Doctor immédiatement actionnables après
l'onboarding.

Axes :

- séparer `action_required`, `accepted_findings` et `expected_exceptions` ;
- réserver `FAIL` aux drifts, pairings manquants non justifiés, exports
  manifest manquants, erreurs techniques et dangers Doctor ;
- réserver `WARN` aux findings à revoir ou aux actions non bloquantes ;
- conserver les findings acceptés dans les rapports sans dégrader le statut ;
- maintenir `missing_* = 0`, `drift_* = 0` et AI Doctor `OK`.


## Phase 11 — Validation automatisée globale — TERMINÉE

Objectif :
valider l'état complet de `ai-system` avec une commande unique.

Commande recommandée :

```bash
make check
```

La cible Make délègue à `./check-ai-system.sh`. Les cibles `make inventory`
et `make doctor` restent disponibles pour exécuter chaque contrôle
séparément.

La commande régénère Inventory et Doctor, puis échoue avec un code de sortie
non nul si l'un des invariants suivants est violé :

- `action_required > 0` ;
- Doctor `danger > 0` ou `review > 0` ;
- `missing_codex_skill > 0` ou `missing_claude_command > 0` ;
- `semantic_review_needed > 0` ;
- un compteur `drift_* > 0` ;
- `manifest_missing_exports > 0`.

Les `accepted_findings` et `expected_exceptions` restent affichés pour
transparence mais ne provoquent pas d'échec.


## Phase 12 — Documentation opératoire — TERMINÉE

Objectif :
documenter la routine d'exploitation quotidienne du système central.

Livrable :

- `docs/OPERATIONS.md`

Contenu attendu :

- commandes `make check`, `make inventory`, `make doctor` ;
- lecture de `action_required`, `accepted_findings`, `expected_exceptions`,
  `missing_*` et `drift_*` ;
- conduite à tenir si la validation globale échoue ;
- règles de création d'une `pairing_exception` ;
- règles de création d'un canonical project-specific ;
- interdiction de modifier les exports projet à la main.


## Phase 13 — Workflow d'évolution des skills — TERMINÉE

Objectif :
documenter la manière de faire évoluer les skills shared et project-specific
sans casser les exports ni masquer les drifts.

Livrable :

- `docs/SKILL-WORKFLOW.md`

Contenu attendu :

- modification d'un skill shared ;
- modification d'un skill project-specific ;
- règles d'incrément de `version` ;
- synchronisation des exports ;
- validation avec `make check` ;
- gestion des commandes Claude-only ;
- conversion vers un canonical project-specific quand le besoin devient clair ;
- interdictions : export modifié à la main, exception pour masquer un drift,
  export project-specific dans un autre projet.


## Phase 14 — Onboarding futur projet — TERMINÉE

Objectif :
fournir une procédure courte pour intégrer un nouveau projet sans réintroduire
de fuite entre projets.

Livrable :

- `docs/PROJECT-ONBOARDING.md`

Contenu attendu :

- ajout du projet dans `skills-registry.yml` ;
- déclaration des paths ;
- installation des shared skills ;
- identification des commandes Claude-only ;
- création d'une `pairing_exception` quand nécessaire ;
- création d'un canonical project-specific seulement si le besoin est clair ;
- vérification de l'isolation ;
- commandes utiles : synchronisation ciblée, grep anti-fuite, `make check` ;
- création de `docs/projects/<project>-onboarding.md`.


## Phase 15 — Protection anti-régression — TERMINÉE

Objectif :
ajouter une barrière locale optionnelle avant commit pour empêcher la
régression d'un état validé.

Livrable :

- `scripts/install_git_hooks.sh`

Contenu attendu :

- installation d'un hook `.git/hooks/pre-commit` local ;
- exécution de `make check` avant commit ;
- blocage du commit si la validation échoue ;
- documentation d'installation dans `docs/OPERATIONS.md` ;
- procédure idempotente et non imposée aux autres clones.


## Phase 16 — Validation CI — TERMINÉE

Objectif :
exécuter la validation globale dans GitHub Actions à chaque push et pull
request.

Livrable :

- `.github/workflows/ai-system-check.yml`

Contenu attendu :

- déclenchement sur `push` et `pull_request` ;
- installation de Python ;
- préparation d'un environnement local avec `pyyaml` ;
- exécution de `make check`.


## Phase 17 — README racine — TERMINÉE

Objectif :
fournir une entrée courte qui rappelle la source de vérité, les commandes
principales et les règles non négociables.

Livrable :

- `README.md`

Contenu attendu :

- rôle de `ai-system` ;
- règle source de vérité : canonicals + registry + manifest ;
- commandes `make check`, `make inventory`, `make doctor` ;
- liens vers les docs d'exploitation, de workflow et d'onboarding ;
- interdictions : modifier les exports à la main, masquer un drift par
  exception, exporter un skill project-specific dans un autre projet.


## Phase 18 — Version stable initiale — TERMINÉE

Objectif :
figer la première version stable du système central avec sa documentation,
ses validations et ses garde-fous locaux/CI.

Livrable :

- `CHANGELOG.md`

Contenu attendu :

- entrée `v1.0.0` ou `initial-stable` ;
- résumé de l'onboarding multi-projets ;
- résumé de l'inventaire consolidé ;
- état `AI Doctor OK` ;
- validation locale `make check` ;
- hook pre-commit local ;
- validation CI GitHub Actions ;
- documentation opératoire disponible.


## Phase 19 — Installation ciblée des exports projet — TERMINÉE

Objectif :
installer les exports partagés d'un projet sans lister les skills un par un.

Livrables :

- `scripts/install_project_exports.py`
- `make install-project`

Contenu attendu :

- sélection du projet via `PROJECT` ;
- sélection des targets via `TARGETS` (`codex`, `claude`, `both`) ;
- génération des exports partagés depuis `install_shared_skills` ;
- compatibilité avec les projets Codex-only et les projets qui installent aussi
  les commandes Claude locales ;
- inventaire capable de reconnaître ces exports comme attendus.


## Phase 20 — Mise à jour globale des projets — TERMINÉE

Objectif :
mettre à jour les exports partagés de **tous les projets enabled** en une seule
commande, sans répéter plusieurs appels à `make install-project`.

Livrables :

- `scripts/update_project_exports.py`
- `make update-projects`
- documentation dans `docs/OPERATIONS.md` et `docs/PROJECT-ONBOARDING.md`

Contenu attendu :

- parcourir tous les projets `enabled: true` dans `skills-registry.yml` ;
- pour chaque projet, respecter les targets autorisées via `install_shared_targets` ;
- sélection des targets via `TARGETS` (`codex`, `claude`, `both`) ;
- intersection entre targets demandées et targets autorisées par projet ;
- gestion des projets Codex-only : ne pas échouer si `TARGETS=both` ;
- résumé par projet : targets appliquées, nombre updated/unchanged/error ;
- exit code non nul si au moins une erreur survient ;
- idempotence garantie.


## Phase 21 — Couche d'actions locale pour GUI macOS — TERMINÉE

Objectif :
créer un point d'entrée unique et ergonomique pour une future interface graphique
macOS, sans dumliquer la logique métier existante.

Livrables :

- Cibles Make `gui-*` : 24 cibles pour toutes les actions de l'interface
- `scripts/ai_system_action.sh` : script backend central unique
- Mise à jour de `docs/OPERATIONS.md` avec documentation des actions
- Mise à jour du `Plan-AI-System.md` (cette phase)

Contenu attendu :

- Actions système : check, inventory, doctor (ouvrir dans Terminal)
- Actions exports : update, update-codex, update-claude, install-project (ouvrir dans Terminal + make check)
- Actions rapports : open-inventory, open-doctor (open directement)
- Actions docs : open-readme, open-operations, open-skill-workflow, open-project-onboarding, open-plan, open-local-gui-design (open directement)
- Actions config : install-hooks, git-status (Terminal)
- Actions raccourcis : open-cursor, open-terminal, open-finder (ouvrir IDE/Terminal/Finder)
- Validation des arguments (PROJECT + TARGETS pour install-project)
- Terminal visible pour actions longues via osascript
- `open` pour docs/rapports
- Aucune nouvelle dépendance
- Prêt pour interface AppleScript future

## Phase 22 — Interface locale macOS AppleScript — TERMINÉE

Objectif :
créer une interface graphique interactive macOS pour piloter le système sans
passer par le terminal.

Livrables :

- `scripts/ai_system_gui.applescript` : interface AppleScript interactive
- Mise à jour de `docs/OPERATIONS.md` avec guide d'installation et d'usage
- Mise à jour de `README.md` avec mention de l'interface
- Export possible en application macOS (`AI System.app`)
- Ajout possible au Dock

Contenu attendu :

- Menu principal avec 9 catégories
- 7 sous-menus complets
- Gestion des annulations AppleScript
- Appels au backend `scripts/ai_system_action.sh`
- Aucune duplication de logique
- Notifications de confirmation après action
- Retour au menu principal après chaque action
- Support complet de toutes les actions :
  - Validation (check, inventory, doctor)
  - Exports (update, update-codex, update-claude, install-project)
  - Rapports (open-inventory, open-doctor)
  - Documentation (6 documents)
  - Configuration (install-hooks, git-status)
  - Raccourcis (Cursor, Terminal, Finder)
- Terminal visible pour actions longues
- Procédure d'export en app macOS documentée


## Phase 23 — Amélioration UX de l'interface locale — TERMINÉE

Objectif :
refaire l'interface AppleScript pour qu'elle soit claire, en français, et sans
ouvrir Terminal par défaut depuis l'app.

Livrables :

- `scripts/ai_system_gui.applescript` : interface refactorisée en français
- `scripts/ai_system_action.sh` : support du mode app (sans Terminal) via variable `AI_SYSTEM_UI_MODE`
- Dossier `logs/` : logs des actions exécutées en mode app
- Mise à jour de `docs/OPERATIONS.md` avec documentation du mode app/terminal
- Mise à jour de `README.md` avec mention des améliorations UX

Contenu attendu :

- Menu principal français clair sans tags techniques `[SYSTEM]`, `[DIAG]`, etc.
- Texte français pour tous les libellés : "Vérifier que tout est OK", "Diffuser les mises à jour", etc.
- Pas d'emojis couleur (instabilité AppleScript)
- Mode app par défaut : pas d'ouverture de Terminal depuis l'interface
- Variable d'environnement `AI_SYSTEM_UI_MODE` :
  - `app` : exécution en arrière-plan, logs écrits, pas de Terminal
  - `terminal` : comportement historique, Terminal visible
- Logs dans `logs/ai-system-last-action.log`
- Action "Ouvrir le dernier log" dans "Outils locaux"
- Terminal reste accessible volontairement via "Ouvrir dans Terminal"
- Messages de succès/erreur simples dans l'interface
- Fallback vers log en cas d'erreur
- Aucune stack trace inutile
- Menu simplifié sans redondance


## Phase 24 — Onboarding projet et application Dock — TERMINÉE

Objectif :
finaliser l'interface locale en permettant l'ajout de nouveaux projets,
en corrigeant les annulations AppleScript, et en créant un build reproductible
de l'application Dock avec icône.

Livrables :

- `scripts/ai_system_gui.applescript` : annulations propres, menu "Ajouter un nouveau projet"
- `scripts/add_project.py` : script Python pour ajouter un projet au registre
- `scripts/build_ai_system_app.sh` : script pour build l'app avec icône
- `scripts/ai_system_action.sh` : actions `add-project` et `build-gui-app`
- Cibles Make : `build-gui-app`, `add-project`
- Mise à jour complète de la documentation

Contenu attendu :

- Annulations AppleScript gérées proprement (`User cancelled. (-128)` éliminé)
- Menu principal inclut "Ajouter un nouveau projet"
- Workflow guidé pour ajouter un projet :
  1. Saisir nom
  2. Saisir chemin absolu
  3. Sélectionner cible (codex|claude|both)
  4. Installer maintenant ou plus tard
- Ajout au registre avec shared skills standards
- Installation optionnelle des exports
- Validation automatique (`make check`) après ajout
- Build app avec icône (PNG ou ICNS)
- Script build idempotent et reproductible
- Action "Recréer l'application Dock" dans l'interface
- `make check` reste OK
- Aucune modification manuelle des exports
- Aucun pairing_exception créé
- Documentation mise à jour (OPERATIONS.md, README.md, Plan-AI-System.md)
