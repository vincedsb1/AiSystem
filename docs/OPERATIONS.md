# AI System Operations

## Commandes

### Validation et diagnostic

```bash
make check                                      # Validation complète (inventaire + doctor + checks)
make inventory                                  # Inventaire des skills
make doctor                                     # Audit des risques et incohérences
```

### Gestion des exports

```bash
make update-projects TARGETS=both               # Mettre à jour tous les projets (Claude + Codex)
make update-projects TARGETS=codex              # Mettre à jour Codex uniquement
make update-projects TARGETS=claude             # Mettre à jour Claude uniquement
make install-project PROJECT=intrai TARGETS=both  # Mettre à jour un seul projet
```

`make check` exécute la validation globale. `make inventory` et `make doctor`
restent disponibles pour isoler un diagnostic.

`make update-projects` installe les exports partagés de **tous les projets enabled**
en une seule commande. Respecte les targets autorisées de chaque projet
(`install_shared_targets` dans `skills-registry.yml`).

`make install-project` installe les exports partagés d'**un seul projet**.

## Hook Git local

Installer un hook pre-commit local pour lancer `make check` avant chaque
commit :

```bash
scripts/install_git_hooks.sh
```

Le hook est local au clone courant, optionnel, et bloque le commit si la
validation échoue.

## Interprétation

- `action_required` : findings à corriger. Tant que ce compteur est > 0,
  l'inventaire n'est pas considéré comme propre.
- `accepted_findings` : findings transparents mais non bloquants. Ils restent
  visibles dans le rapport pour auditabilité.
- `expected_exceptions` : écarts encodés dans `pairing_exceptions`. Ils sont
  attendus et ne dégradent pas le statut.
- `missing_*` : artefacts attendus mais absents. Toute valeur > 0 est bloquante.
- `drift_*` : métadonnées incohérentes entre Claude et Codex. Toute valeur > 0
  est bloquante.

## Si `make check` échoue

1. Lire `reports/ai-inventory.latest.md`.
2. Corriger les éléments dans `action_required` en priorité.
3. Si l'échec vient d'un `missing_*`, d'un `drift_*`, d'un export manquant ou
   d'un danger Doctor, corriger la source canonique ou l'export généré.
4. Ne pas modifier les exports à la main.

## Règles d'évolution

- Créer une `pairing_exception` seulement pour une commande Claude-only
  explicitement voulue et justifiée par projet.
- Créer un canonical project-specific seulement quand le besoin métier est clair
  et qu'il ne doit pas rester Claude-only.
- Ne pas éditer les exports projet à la main. Ils doivent rester générés depuis
  les canonicals et le registre.
