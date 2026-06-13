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


## Phase 9 — Extension aux autres projets

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

Le registre activera les projets progressivement.