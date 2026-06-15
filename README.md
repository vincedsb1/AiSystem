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

## Docs utiles

- [docs/OPERATIONS.md](docs/OPERATIONS.md)
- [docs/SKILL-WORKFLOW.md](docs/SKILL-WORKFLOW.md)
- [docs/PROJECT-ONBOARDING.md](docs/PROJECT-ONBOARDING.md)
- [Plan-AI-System.md](Plan-AI-System.md)

## Règles à ne jamais violer

- ne pas modifier les exports à la main ;
- ne pas masquer un drift par exception ;
- ne pas exporter un skill project-specific dans un autre projet.
