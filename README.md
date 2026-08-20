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
- Interface native SwiftUI (macOS 13+)
- Sidebar avec 7 sections : Tableau de bord, Diffusion, Projets, Rapports, Docs, Outils, Logs
- Gestion des projets : ajouter, mettre à jour
- Logs intégrés avec stdout/stderr séparés
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
- [docs/SKILL-WORKFLOW.md](docs/SKILL-WORKFLOW.md)
- [docs/PROJECT-ONBOARDING.md](docs/PROJECT-ONBOARDING.md)
- [Plan-AI-System.md](Plan-AI-System.md)

## Règles à ne jamais violer

- ne pas modifier les exports à la main ;
- ne pas masquer un drift par exception ;
- ne pas exporter un skill project-specific dans un autre projet.
