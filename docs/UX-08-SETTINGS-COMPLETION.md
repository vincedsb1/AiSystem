# ÉTAPE UX-08 — Réglages, documentation et outils avancés

**Statut :** Terminée
**Dépend de :** UX-02, UX-07

## Contexte

UX-02 a réduit la sidebar à trois destinations, ce qui a rendu Diffusion,
Rapports, Documentation, Outils et Logs inatteignables. UX-08 reloge ces
fonctions avant de supprimer les vues, conformément à la règle « reloger avant
supprimer » (§28).

## Fenêtre Réglages

Scène `Settings` standard, atteignable par `⌘,` fourni par le système.

| Onglet | Contenu |
|---|---|
| Emplacements | racine AI System, dossier des logs, app installée, ouverture Finder |
| Intégrations | Finder, Terminal, Cursor avec détection de disponibilité |
| Ressources | rapports Inventory/Doctor/log + les six documents |
| Avancé | hook pre-commit, état Git, reconstruction, version et backend |

### Principes appliqués (§16.3)

- Aucun panneau de log global : chaque action donne son feedback inline et rien
  ne se propage à une autre section.
- Confirmation uniquement là où elle est nécessaire : la reconstruction de
  l'application est la seule action confirmée (§17.4).
- Les actions rares sont visuellement séparées dans une section Maintenance.
- Cursor absent est signalé et le bouton désactivé, plutôt qu'un échec après
  clic.

### Chemins en dur

Les chemins restent fixes dans cette version et sont **affichés** sans être
migrés vers une configuration dynamique : la §16.2 exclut explicitement cette
migration du périmètre de la refonte.

## Menus et raccourcis (§19.1)

`AppCommands` ajoute `⌘N` (nouveau projet), `⌘R` (actualiser) et `⌘F`
(rechercher), diffusés par notification pour que seule la destination affichée
réagisse. `⌘,` vient de la scène `Settings`. Le menu Aide ouvre README et
Operations.

## Vues supprimées

Fonctions relogées, donc vues retirées :

| Vue | Destination |
|---|---|
| `DiffusionView` | Projets (synchronisation, UX-05) |
| `ReportsView` | Activité + Réglages > Ressources |
| `LogsView` | Activité > Détails techniques |
| `DocumentationView` | Réglages > Ressources et menu Aide |
| `ToolsView` | Réglages > Avancé |
| `SidebarView` | `ContentView` (UX-02) |

Composants devenus orphelins : `ResultPanel`, `RunStatusView`,
`PrimaryActionButton`, `StatusBadge`.

`ResultPanel` était le panneau de résultat global que la spec voulait
précisément faire disparaître (§28, risque « ancien `lastResult` global »).

## Conservé

- Le fallback AppleScript (`scripts/ai_system_gui.applescript`) est intact.
- `scripts/build_ai_system_app.sh` reste disponible.
- Toutes les routes CLI restent valides.

## Validation

- Tests Swift : **77** — OK
- Tests backend : **93** — OK
- `./check-ai-system.sh` — OK
- `scripts/build_swift_app.sh` — OK
