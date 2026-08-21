# AI System

`ai-system` est la source de vérité pour les skills, les règles, les hooks et
la validation multi-projets.

## Règle de base

- les canonicals vivent dans `skills/` ;
- le registre décrit les projets, les shared skills et les exceptions ;
- les exports sont générés, pas modifiés à la main ;
- le manifest doit rester aligné avec les exports.

## Commandes

```bash
make check
make inventory
make doctor
```

## Interface locale macOS

### SwiftUI App (Recommandée)

Une interface graphique native macOS SwiftUI est maintenant l'interface principale pour piloter le système.

**Installation et lancement :**

```bash
make build-swift-app
open ~/Applications/"AI System.app"
```

**Caractéristiques :**
- Interface native SwiftUI avec trois destinations : Vue d’ensemble, Projets, Activité
- System Pulse : représentation du flux AI System → Projets → Claude/Codex
- Quick Command global avec `⌘K`, recherche locale et actions protégées
- Operation Experience : indicateur global, reçus sémantiques et activité contextualisée
- Gestion des projets : ajouter, analyser, synchroniser et consulter les skills
- Détails techniques accessibles à la demande, sans interprétation de stdout
- Pas d'ouverture Terminal par défaut (mode `swift`)
- Pas de dépendances externes
- Entièrement local, pas de notarisation

Voir [docs/OPERATIONS.md](docs/OPERATIONS.md) pour les détails complets.

### AppleScript App (Fallback)

L'ancienne interface AppleScript est conservée comme fallback pendant la transition.

```bash
osascript scripts/ai_system_gui.applescript
# ou
make build-gui-app
open ~/Applications/"AI System.app"  # (ancienne version)
```

## Docs utiles

- [docs/OPERATIONS.md](docs/OPERATIONS.md)
- [docs/UX3-07-CLOSURE.md](docs/UX3-07-CLOSURE.md) — clôture UX3 et preuves de validation
- [docs/SKILL-WORKFLOW.md](docs/SKILL-WORKFLOW.md)
- [docs/PROJECT-ONBOARDING.md](docs/PROJECT-ONBOARDING.md)
- [Plan-AI-System.md](Plan-AI-System.md)

## Règles à ne jamais violer

- ne pas modifier les exports à la main ;
- ne pas masquer un drift par exception ;
- ne pas exporter un skill project-specific dans un autre projet.

## Interface macOS

L'application `AI System` (SwiftUI, macOS) expose trois destinations :

| Destination | Rôle |
|---|---|
| Vue d'ensemble | état global du système, actions requises, activité récente |
| Projets | consultation des projets et skills, import, synchronisation, ajout |
| Activité | résultats contextualisés, rapports et détails techniques |

Les fonctions secondaires (documentation, rapports, outils, emplacements)
vivent dans **Réglages** (`⌘,`). Raccourcis : `⌘K` Quick Command,
`⌘N` nouveau projet, `⌘R` actualiser, `⌘F` rechercher.

L'interface ne contient aucune logique métier : elle consomme les contrats
JSON versionnés de `scripts/project_skills.py` (lecture) et
`scripts/project_actions.py` (écriture). Voir `docs/UX-10-CLOSURE.md`.

Construction : `make build-swift-app`.
Le lanceur AppleScript reste disponible via `make build-gui-app`.
