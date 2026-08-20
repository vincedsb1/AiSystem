# ÉTAPE UX-09 — Menus, raccourcis, accessibilité et polish

**Statut :** Terminée

## Déjà en place avant cette étape

L'accessibilité a été construite au fil des étapes plutôt qu'ajoutée à la fin :

- `accessibilityElement(children: .combine)` et `accessibilityLabel` explicites
  sur chaque ligne composite (actions, projets, skills, activités) ;
- `accessibilityHidden(true)` sur les icônes décoratives, dont le sens est déjà
  porté par le libellé voisin ;
- `.help()` sur chaque bouton représenté uniquement par un symbole ;
- statuts toujours doublés d'un texte et d'un symbole ;
- `⌘N`, `⌘R`, `⌘F` via `AppCommands` (UX-08), `⌘,` par la scène `Settings`.

## Ajouté

### Reduce Motion (§19.4)

`functionalAnimation(_:reduceMotion:)` applique une transition courte de 180 ms
ou aucune si `accessibilityReduceMotion` est actif. Aucune animation n'est
nécessaire pour comprendre un état.

### Tests-gardes d'accessibilité

15 tests vérifient des contrats qui régresseraient silencieusement autrement :

- chaque état, statut, gravité, type d'activité, filtre et destination possède
  un libellé **et** un symbole non vides ;
- les paires rouge/vert utilisent des **formes différentes** (§19.3) : un
  daltonien distingue `checkmark.circle.fill` de `xmark.octagon.fill` ;
- attention et erreur ne partagent pas de symbole ;
- exactement trois destinations principales existent ;
- chaque `writeState` explique ce qui s'est passé sur disque ;
- les exceptions attendues ne comptent jamais comme actions ;
- les noms et messages longs ne sont pas tronqués par la couche modèle — la
  troncature est une décision de la vue, pas du modèle.

## Validation

- Tests Swift : 77 → **92** (15 nouveaux)
- Tests backend : **93** — OK
- `./check-ai-system.sh` — OK

## Réserve

La cible `AI SystemUITests` échoue toujours à l'initialisation du runner
(« Timed out while enabling automation mode »). Environnemental et préexistant.
Les onze parcours de la §24.3 sont donc à valider en recette manuelle, décrite
en UX-10.
