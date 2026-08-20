# ÉTAPE UX-06 — Nouveau parcours d'ajout de projet

**Statut :** Terminée
**Dépend de :** UX-02, backend add-project

## État initial

`scripts/add_project.py` existait mais n'émettait que du texte humain, sans
contrat JSON ni erreurs structurées : inutilisable tel quel par SwiftUI sans
parser du stdout, ce que la §21.8 interdit.

## Backend ajouté à `scripts/project_actions.py`

### `inspect-folder --path P`

Lecture seule. Décrit un dossier candidat pour préremplir le formulaire :
chemin résolu, nom suggéré, environnements détectés (`.agents/skills`,
`.claude/commands`), projet déjà déclaré le cas échéant, et la valeur par
défaut d'installation immédiate.

### `add-project --project N --path P --targets codex|claude|both`

Validation autoritaire côté backend (§13.3) :

- chemin absolu, dossier existant et lisible ;
- nom non vide, sans séparateur de chemin, produisant un slug utilisable ;
- collision de nom insensible à la casse ;
- collision de racine ;
- cibles valides.

Écriture atomique du registry, refusée si le résultat ne passe pas
`validate_registry_shape`. Un échec laisse le registry strictement intact.

### Valeur par défaut préservée

La spec (§13.3) demande de ne pas modifier arbitrairement le comportement
existant. `ai_system_action.sh add-project` avait `INSTALL_NOW` à `false` :
`defaultInstallNow` vaut donc `false` et l'interface se contente de l'exposer.

### Skills partagés d'un nouveau projet

Plutôt qu'une liste codée en dur, le backend reprend les skills partagés
installés par au moins la moitié des projets actifs.

## Swift

| Fichier | Rôle |
|---|---|
| `Features/Projects/AddProjectSheet.swift` | sheet guidée + `AddProjectViewModel` |
| `Services/ProjectSkillsService.swift` | routes `inspectFolder` et `addProject` |

Parcours : `NSOpenPanel` → inspection → nom prérempli et modifiable →
environnements détectés → ajout → rechargement de la liste → sélection du
nouveau projet → analyse.

## Règles respectées

- §13.1 — déclenchement par toolbar et `⌘N`.
- §13.2 — sheet, `NSOpenPanel`, nom déduit, cibles proposées, sélection finale.
- §13.3 — aucune validation de chemin côté UI comme seule garantie ; le backend
  fait autorité. Nom prérempli mais modifiable.
- §13.4 — chaque erreur indique si le projet a été ajouté ou non.
- Aucun parsing ni écriture du registry côté Swift.

## Validation

- Tests backend : 77 → **93** (16 nouveaux)
- Tests Swift : 46 → **60** (14 nouveaux)
- `./check-ai-system.sh` — OK
- Registry inchangé par les tests
- Injection `both; rm -rf /` en cible : rejetée

## Note

Le champ « installation immédiate » n'est pas encore proposé dans la sheet : le
backend expose `defaultInstallNow=false` et l'installation passe par la
synchronisation du projet (UX-05), déjà disponible juste après l'ajout.
