# ÉTAPE UX-07 — Activité et détails techniques

**Statut :** Terminée
**Dépend de :** UX-02, CommandCenter évolué

## Décision préalable requise par la spec (§14.2)

Trois options étaient offertes : session-only, persistance locale structurée, ou
historique structuré backend.

**Choix retenu : session-only.**

Motifs :

1. La spec qualifie ce choix d'« initial le plus simple acceptable », à
   condition que le dernier log fichier reste accessible. C'est le cas : la
   route `open-log` l'ouvre depuis le détail d'une activité.
2. Aucun historique structuré n'existe côté backend aujourd'hui. En inventer un
   dans Application Support ajouterait du périmètre sans contrat pour le
   soutenir, ce que la §14.2 déconseille explicitement.
3. Les logs backend restent les preuves autoritaires.

La persistance entre lancements reste un « should have » (§27) ouvert.

## Livré

| Fichier | Rôle |
|---|---|
| `Models/ActivityModels.swift` | `Activity`, `ActivityKind`, `ActivityScope`, `ActivityError`, `TechnicalDetails`, `ActivityFilter` |
| `Services/ActivityStore.swift` | historique de session, sélection, filtres, recherche |
| `Features/Activity/ActivityView.swift` | liste + détail + détails techniques repliés |

### Remplacement du `lastResult` global

Chaque opération est enregistrée avec son contexte (type, cible, projet, skill).
Le résultat revient à son appelant ; aucune vue n'affiche l'erreur d'une autre.
C'est la mitigation prévue au §28 pour le risque « ancien `lastResult` global ».

### Ordre obligatoire du détail (§14.5)

1. conclusion ;
2. changements ;
3. avertissements et erreurs ;
4. rapports et fichiers ;
5. détails techniques repliés.

## Règles respectées

- FR-ACT-01 — le monospace est réservé aux détails techniques.
- FR-ACT-02 — détails techniques repliés par défaut.
- FR-ACT-03 — aucune donnée sensible ajoutée aux logs ; on n'expose que ce que
  le backend a déjà émis.
- FR-ACT-04 — aucun bouton « Effacer l'affichage ».
- FR-NAV-03 — une erreur inline peut ouvrir son activité.
- §9.3 — la Vue d'ensemble affiche les 4 dernières activités.
- §12.5 — les éléments inchangés ne produisent pas de longue liste.

## Validation

- Tests Swift : 60 → **77** (17 nouveaux)
- Tests backend : 93 — OK
- `./check-ai-system.sh` — OK
- `scripts/build_swift_app.sh` — OK

## Reste à faire en UX-08 / UX-10

Les anciennes vues `ReportsView` et `LogsView` ne sont plus atteignables depuis
la sidebar depuis UX-02, et leurs fonctions sont désormais couvertes par
Activité. Leur suppression est groupée avec celle de Documentation et Outils en
UX-08/UX-10, pour ne pas mélanger relogement et suppression.
