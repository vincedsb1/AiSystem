# Workflow d'évolution des skills

## Modifier un skill shared

1. Modifier le canonical `skills/shared/<skill>/canonical.md`.
2. Garder le contenu project-neutre.
3. Mettre à jour `version` seulement si le changement modifie le contrat,
   la sortie attendue ou la compatibilité.
4. Synchroniser les exports via le mécanisme existant du dépôt.
5. Valider avec `make check`.

## Modifier un skill project-specific

1. Modifier le canonical du projet concerné dans `skills/projects/<project>/...`.
2. Ne pas réutiliser un export d'un autre projet.
3. Incrémenter `version` quand le comportement visible change.
4. Synchroniser les exports générés.
5. Valider avec `make check`.

## Gérer une commande Claude-only

Si une commande doit rester uniquement côté Claude, l'indiquer explicitement
dans `pairing_exceptions` pour le projet concerné.

## Transformer une commande Claude-only

Quand une commande Claude-only doit devenir partageable :

1. Créer ou mettre à jour le canonical project-specific si le besoin est propre
   au projet.
2. Ou basculer vers un shared canonical si le comportement est project-neutre.
3. Synchroniser les exports.
4. Revalider avec `make check`.

## À ne jamais faire

- modifier un export à la main ;
- créer une exception pour masquer un drift ;
- exporter un skill project-specific dans un autre projet.
