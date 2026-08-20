# AI System — Spécification fonctionnelle et technique de la refonte UX/UI

**Version :** 1.0  
**Date :** 20 août 2026  
**Statut :** Spécification prête pour implémentation incrémentale  
**Application :** AI System — macOS SwiftUI  
**Dépôt :** `/Users/vincentdesbrosses/Documents/Misc/ai-system`  
**Projet SwiftUI :** `/Users/vincentdesbrosses/Documents/Misc/ai-system/apps/AI-System`  
**Projet Xcode :** `/Users/vincentdesbrosses/Documents/Misc/ai-system/apps/AI-System/AI System.xcodeproj`

---

## 0. Objet du document

Ce document spécifie la refonte fonctionnelle et technique de l’expérience utilisateur de l’application macOS `AI System`.

Il transforme les recommandations du rapport `RAPPORT-AUDIT-UX-UI-AI-SYSTEM.md` en un plan d’implémentation séquencé, testable et réversible.

Il doit permettre de réaliser la refonte étape par étape sans :

- déplacer la logique métier dans SwiftUI ;
- casser les commandes CLI existantes ;
- réécrire le backend existant sans nécessité ;
- recréer le projet Xcode ;
- perdre les modifications présentes dans le worktree ;
- supprimer le fallback AppleScript ;
- introduire un framework UI externe.

Le document couvre :

- l’architecture de l’information cible ;
- les fonctionnalités principales et secondaires ;
- les parcours utilisateur ;
- les états et règles d’affichage ;
- l’architecture SwiftUI cible ;
- les contrats attendus du backend ;
- la stratégie de migration ;
- les tests fonctionnels, techniques et d’accessibilité ;
- les étapes d’implémentation et leurs critères d’acceptation.

---

## 1. Sources de vérité et règle de priorité

### 1.1 Sources produit et UX

1. Le présent document pour la cible fonctionnelle et technique de la refonte.
2. `RAPPORT-AUDIT-UX-UI-AI-SYSTEM.md` pour les principes UX et le diagnostic.
3. Les décisions explicites prises ultérieurement au cours de l’implémentation.
4. Les Human Interface Guidelines d’Apple pour les conventions macOS.

### 1.2 Sources d’implémentation

Lorsque l’implémentation commence, le code réellement présent dans le dépôt prime pour :

- les signatures existantes ;
- les contrats JSON déjà implémentés ;
- les fichiers créés par le chantier `project_skills.py` ;
- les modifications non commitées ;
- les versions réelles des scripts et tests.

En cas de divergence entre cette spécification et un contrat backend déjà validé, l’étape concernée doit commencer par documenter l’écart. Le contrat ne doit pas être modifié silencieusement.

### 1.3 Références Apple

- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles)
- [Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars)
- [Split views](https://developer.apple.com/design/human-interface-guidelines/split-views)
- [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
- [Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)
- [Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback)
- [Progress indicators](https://developer.apple.com/design/human-interface-guidelines/progress-indicators)
- [Disclosure controls](https://developer.apple.com/design/human-interface-guidelines/disclosure-controls)
- [Lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables)

---

## 2. Vision produit cible

### 2.1 Proposition de valeur

`AI System` doit être le cockpit local permettant de :

1. comprendre immédiatement la santé de l’environnement IA ;
2. identifier les projets et skills qui demandent une action ;
3. importer, synchroniser ou corriger les éléments concernés ;
4. comprendre ce qui a été exécuté sans lire obligatoirement des logs ;
5. accéder aux preuves et outils techniques lorsqu’ils sont nécessaires.

### 2.2 Modèle mental cible

L’application ne doit plus être perçue comme un lanceur graphique de scripts.

Elle doit être perçue comme un système qui :

- observe ;
- résume ;
- recommande une action ;
- exécute cette action ;
- explique le résultat ;
- conserve les détails techniques accessibles.

### 2.3 Phrase directrice

> Vue d’ensemble pour comprendre, Projets pour agir, Activité pour vérifier.

### 2.4 Objectifs mesurables

La refonte est considérée fonctionnellement réussie si :

- l’état global est compréhensible en moins de cinq secondes ;
- une anomalie mène en un clic au projet ou au skill concerné ;
- un skill détecté uniquement dans Claude ou Codex peut être importé sans connaissance du manifest ;
- une synchronisation indique ce qu’elle va modifier puis ce qu’elle a modifié ;
- une erreur n’apparaît que dans le contexte de l’opération concernée ;
- les logs ne sont jamais nécessaires pour comprendre un succès ordinaire ;
- les commandes avancées restent accessibles sans occuper la navigation principale ;
- toutes les fonctions principales sont utilisables au clavier ;
- les workflows CLI restent fonctionnels.

---

## 3. Périmètre

### 3.1 Inclus

- nouvelle architecture de navigation ;
- nouvelle Vue d’ensemble ;
- nouvelle expérience Projets ;
- consultation des skills et de leurs statuts ;
- import d’un skill local non géré ;
- synchronisation d’un projet ;
- ajout d’un projet ;
- nouvelle vue Activité ;
- présentation sémantique des succès et erreurs ;
- accès progressif aux rapports et logs ;
- fenêtre Réglages ;
- toolbar et menus macOS ;
- raccourcis clavier ;
- accessibilité ;
- états de chargement, états vides et erreurs ;
- adaptation clair/sombre ;
- tests et validation sur l’app Release installée.

### 3.2 Non inclus

- application web ;
- Electron ou Tauri ;
- backend distant ;
- synchronisation cloud ;
- multi-utilisateur ;
- distribution App Store ;
- réactivation du sandbox macOS ;
- refonte des règles métier Inventory/Doctor ;
- parsing direct du manifest ou du registry en SwiftUI ;
- édition manuelle de canonicals depuis une zone de texte générique ;
- terminal complet intégré à l’application ;
- suppression du fallback AppleScript ;
- refonte visuelle des scripts CLI ;
- persistance multi-machine de l’activité.

### 3.3 Fonctionnalités différées

Ces fonctions ne bloquent pas la première version de la refonte :

- historique persistant illimité ;
- notifications système lorsque l’app est en arrière-plan ;
- vérification périodique automatique ;
- drag-and-drop de projets ;
- comparaison visuelle ligne par ligne d’un drift ;
- correction automatique de conflits complexes ;
- personnalisation avancée du thème.

---

## 4. Contraintes non négociables

### 4.1 Architecture

**C-ARCH-01** — SwiftUI reste une couche de présentation et d’orchestration.

**C-ARCH-02** — Les règles suivantes restent dans le backend :

- résolution des projets ;
- lecture et validation des YAML ;
- pairing Claude/Codex ;
- résolution canonical ;
- calcul des statuts de skills ;
- import et génération des exports ;
- détection de drift ;
- exceptions attendues ;
- Inventory, Doctor et Check.

**C-ARCH-03** — SwiftUI consomme des contrats JSON structurés pour les données métier.

**C-ARCH-04** — `CommandRunner` continue d’utiliser `Process` et un tableau d’arguments.

**C-ARCH-05** — Aucune commande paramétrée ne doit être construite par concaténation de chaîne ou `eval` dans les nouvelles routes.

**C-ARCH-06** — `CommandCenter` continue de sérialiser les opérations incompatibles.

### 4.2 Projet et plateforme

**C-PLAT-01** — Application macOS native.

**C-PLAT-02** — Aucun package UI tiers sans décision ultérieure explicite.

**C-PLAT-03** — `ENABLE_APP_SANDBOX = NO` est conservé.

**C-PLAT-04** — Le projet Xcode n’est pas recréé.

**C-PLAT-05** — `project.pbxproj` n’est pas modifié manuellement sauf preuve de nécessité.

**C-PLAT-06** — Le fonctionnement de `PBXFileSystemSynchronizedRootGroup` est préservé.

**C-PLAT-07** — L’AppleScript existant est conservé comme fallback.

### 4.3 Compatibilité

Les commandes suivantes doivent rester valides à la fin de chaque étape :

- `make inventory`
- `make doctor`
- `make check`
- `make update-projects`
- `make install-project`
- `make build-swift-app`

### 4.4 Git et worktree

**C-GIT-01** — Aucun commit automatique.

**C-GIT-02** — Aucun `git reset`.

**C-GIT-03** — Aucun nettoyage global des fichiers non suivis.

**C-GIT-04** — Les changements préexistants sont préservés.

**C-GIT-05** — Chaque étape commence par un état des lieux du worktree et des fichiers concernés.

---

## 5. Terminologie métier

### 5.1 Système

Ensemble formé par `ai-system`, les canonicals, le registry, le manifest, les exports et les projets activés.

### 5.2 Projet

Projet déclaré dans `skills-registry.yml`, résolu par le backend et exposé à SwiftUI par un identifiant stable.

### 5.3 Skill géré

Skill reconnu par un canonical et le manifest, avec des exports attendus déterminés par le backend.

### 5.4 Action requise

Situation exploitable nécessitant une intervention utilisateur : import, synchronisation, correction de configuration ou résolution de conflit.

### 5.5 Exception attendue

Écart explicitement déclaré et validé, par exemple une commande Claude-only. Une exception attendue n’est ni une erreur ni une action requise.

### 5.6 Opération

Exécution déclenchée depuis l’application : vérification, scan, import, synchronisation, ajout de projet, ouverture d’une ressource ou action avancée.

### 5.7 Activité

Représentation contextualisée d’une opération avec son état, son résumé, sa durée, sa cible et ses détails techniques.

---

## 6. Architecture de l’information cible

### 6.1 Destinations principales

La sidebar contient exactement les destinations suivantes pour le périmètre initial :

1. **Vue d’ensemble**
2. **Projets**
3. **Activité**

### 6.2 Suppression des destinations de premier niveau actuelles

| Destination actuelle | Destination cible |
|---|---|
| Tableau de bord | renommé Vue d’ensemble |
| Diffusion | actions contextuelles Vue d’ensemble/Projets |
| Projets | conservé et entièrement restructuré |
| Rapports | intégré à Activité |
| Documentation | menu Aide ou Réglages > Ressources |
| Outils | toolbar, menus et Réglages > Avancé |
| Logs | détails techniques d’une Activité |

### 6.3 Règles de navigation

**FR-NAV-01** — La sélection de sidebar est persistée entre les lancements.

**FR-NAV-02** — Si l’utilisateur ouvre une action requise depuis la Vue d’ensemble, l’application sélectionne Projets, le bon projet et le filtre adéquat.

**FR-NAV-03** — Si l’utilisateur ouvre une activité depuis une erreur inline, l’application sélectionne Activité et l’activité correspondante.

**FR-NAV-04** — Le retour d’une opération ne change pas automatiquement la destination principale sauf si le workflow l’exige explicitement.

**FR-NAV-05** — La sidebar peut être masquée et restaurée avec le contrôle système standard.

**FR-NAV-06** — Aucun écran ne reproduit la totalité du dernier `CommandResult` par défaut.

---

## 7. Shell de l’application et fenêtre

### 7.1 NavigationSplitView

Utiliser `NavigationSplitView` comme structure principale.

Configuration recommandée :

- sidebar redimensionnable ;
- largeur idéale entre 190 et 240 points ;
- largeur minimale préservant les libellés ;
- contenu principal occupant l’espace restant ;
- éventuelle troisième colonne uniquement dans Projets si elle apporte une valeur réelle.

### 7.2 Fenêtre

- taille initiale recommandée : environ 1080 × 720 points ;
- taille minimale recommandée : environ 900 × 620 points ;
- contenu résilient lorsque la fenêtre est agrandie ou réduite ;
- pas de largeur fixe rigide pour les vues principales ;
- mémorisation native de la taille et de la position si le cycle de vie de l’app le permet.

Les valeurs exactes peuvent être ajustées après test réel, mais l’application doit rester utilisable à la taille minimale retenue.

### 7.3 Titres

**FR-SHELL-01** — Éviter la duplication visible du titre dans la toolbar et immédiatement dans le contenu.

**FR-SHELL-02** — Chaque destination possède un titre de navigation unique.

**FR-SHELL-03** — Les sous-titres décrivent l’état métier et non le mécanisme d’exécution.

### 7.4 Toolbar

La toolbar contient au maximum deux ou trois actions directement visibles par contexte. Les autres sont placées dans un menu `…`.

**Vue d’ensemble :**

- Vérifier maintenant ;
- Synchroniser si nécessaire ;
- menu d’actions secondaires.

**Projets :**

- Ajouter un projet ;
- recherche ou filtre si adapté à la largeur ;
- action du projet sélectionné ;
- menu d’actions secondaires.

**Activité :**

- recherche ;
- filtre ;
- actions de l’activité sélectionnée.

---

## 8. Modèle d’état sémantique

### 8.1 État global du système

SwiftUI utilise un modèle dérivé exclusivement des données backend :

| Valeur | Sens | Couleur indicative | Action typique |
|---|---|---|---|
| `unknown` | aucune observation fraîche disponible | neutre | Vérifier maintenant |
| `checking` | vérification en cours | accent/neutre | Attendre ou annuler |
| `healthy` | aucune action requise | vert | Vérifier à nouveau |
| `attention` | action utilisateur non critique requise | orange | Examiner les actions |
| `error` | incohérence bloquante ou vérification échouée | rouge | Corriger/Réessayer |

### 8.2 État d’une opération

| Valeur | Sens |
|---|---|
| `queued` | opération demandée mais pas démarrée |
| `running` | processus actif |
| `succeeded` | opération terminée correctement |
| `partiallySucceeded` | résultat exploitable avec avertissements |
| `failed` | opération terminée en erreur |
| `cancelled` | opération annulée |

### 8.3 État d’un projet

| Valeur | Sens |
|---|---|
| `unknown` | projet non analysé |
| `healthy` | aucune action requise |
| `attention` | un ou plusieurs éléments importables/corrigeables |
| `error` | conflit ou configuration invalide |
| `disabled` | projet déclaré mais désactivé |

### 8.4 Règles impératives

**FR-STATE-01** — L’état d’une ancienne opération ne devient jamais automatiquement l’état de tous les écrans.

**FR-STATE-02** — `exitCode != 0` n’est pas affiché seul comme message principal.

**FR-STATE-03** — Une couleur s’accompagne toujours d’un texte et/ou d’un symbole.

**FR-STATE-04** — `unknown` est neutre et ne doit pas être rendu comme une erreur.

**FR-STATE-05** — Une exception attendue ne contribue pas au compteur d’actions requises.

**FR-STATE-06** — Un état sain n’est affiché qu’après une observation valide datée.

---

## 9. Vue d’ensemble — spécification fonctionnelle

### 9.1 Objectif

Présenter la conclusion globale, les actions requises et l’activité récente sans exposer les détails techniques par défaut.

### 9.2 États obligatoires

#### État `unknown`

Titre : **État du système inconnu**  
Description : une vérification est nécessaire pour analyser les projets et les skills.  
Action principale : **Vérifier maintenant**.

#### État `checking`

Titre : **Vérification en cours…**  
Description : phase courante si fournie, sinon message générique.  
Indicateur : `ProgressView` indéterminé, sauf si le backend expose une progression réelle.  
Le dernier état connu peut rester visible avec un indicateur précisant qu’il est en cours d’actualisation.

#### État `healthy`

Titre : **Tout est à jour**  
Description : nombre de projets vérifiés et cohérence Claude/Codex.  
Métadonnée : date/heure de la dernière vérification.  
Action principale : **Vérifier maintenant**.

#### État `attention`

Titre : **N éléments demandent votre attention**  
Description : résumé des catégories principales.  
Action principale : **Examiner les actions**.  
Liste : au maximum cinq actions urgentes, puis lien vers les autres.

#### État `error`

Titre : formulation contextualisée, par exemple **La vérification n’a pas pu être terminée**.  
Description : cause utile si disponible.  
Actions : **Réessayer** et **Afficher les détails**.  
Ne pas remplacer l’ensemble du contenu par un log.

### 9.3 Sections

#### Synthèse globale

Contient :

- état global ;
- date de dernière observation ;
- action principale ;
- éventuellement une action secondaire.

#### Actions requises

Visible uniquement si le compteur est supérieur à zéro.

Chaque ligne contient :

- projet ;
- objet concerné ;
- explication courte ;
- gravité ;
- action directe ou navigation vers le détail.

#### Projets

Résumé compact :

- total actif ;
- sains ;
- avec attention ;
- en erreur.

L’interface ne doit pas afficher une grille de nombreuses cartes si une ligne de synthèse ou une petite liste suffit.

#### Activité récente

Affiche les trois à cinq dernières activités connues avec :

- nom humain ;
- statut ;
- date relative ;
- durée si pertinente.

### 9.4 Actions

**FR-OV-01** — Vérifier maintenant déclenche le contrôle global officiel.

**FR-OV-02** — Examiner les actions ouvre la première action prioritaire ou la vue Projets filtrée.

**FR-OV-03** — Synchroniser tous les projets n’est visible que si elle constitue une action compréhensible et pertinente.

**FR-OV-04** — L’utilisateur doit pouvoir consulter le rapport généré depuis l’activité de vérification correspondante.

**FR-OV-05** — Aucun `stdout`/`stderr` n’est rendu directement dans la Vue d’ensemble.

---

## 10. Vue Projets — spécification fonctionnelle

### 10.1 Objectif

Permettre de sélectionner un projet, comprendre son état, examiner ses skills et réaliser les actions appropriées.

### 10.2 Liste des projets

La liste est alimentée par le backend, jamais codée en dur.

Chaque élément affiche :

- nom d’affichage ;
- statut sémantique ;
- nombre d’actions requises si supérieur à zéro ;
- dernière analyse si disponible.

Tri par défaut :

1. projets en erreur ;
2. projets demandant une attention ;
3. projets sains ;
4. ordre alphabétique dans chaque groupe.

Une option peut permettre un tri purement alphabétique, sans être nécessaire à la première livraison.

### 10.3 Sélection

**FR-PROJ-01** — La sélection reste stable lors d’un rafraîchissement si le projet existe toujours.

**FR-PROJ-02** — La dernière sélection peut être restaurée au lancement.

**FR-PROJ-03** — Si aucun projet n’est sélectionné, afficher un état invitant à sélectionner ou ajouter un projet.

**FR-PROJ-04** — Si aucun projet actif n’existe, afficher un état vide avec l’action Ajouter un projet.

### 10.4 En-tête du projet

Contient :

- nom ;
- état ;
- résumé des skills gérés ;
- dernière analyse ;
- action principale contextuelle ;
- menu d’actions secondaires.

Règle d’action principale :

- si l’état est inconnu : **Analyser** ;
- si une synchronisation sûre est requise : **Synchroniser** ;
- si le projet est sain : **Vérifier** ;
- si un conflit exige un choix : **Examiner le conflit**, pas Synchroniser automatiquement.

### 10.5 Sections du projet

Deux espaces principaux :

- **Skills** ;
- **Activité**.

Un contrôle segmenté peut être utilisé si validé visuellement. Le résumé reste visible au-dessus ou dans la section Skills.

### 10.6 Résumé

Afficher :

- skills partagés ;
- skills spécifiques ;
- synchronisés ;
- actions requises ;
- exceptions attendues ;
- conflits.

Les valeurs nulles ou indisponibles doivent être affichées comme non vérifiées, jamais comme zéro confirmé.

### 10.7 Liste des skills

Informations minimales :

- nom ;
- scope : partagé/spécifique ;
- présence Claude ;
- présence Codex ;
- état sémantique ;
- action contextuelle.

La présentation peut être une `Table` sur les grandes largeurs et une `List` adaptative sur les largeurs réduites.

### 10.8 Filtres

Filtres initiaux :

- Tous ;
- À examiner ;
- Synchronisés ;
- Exceptions.

Règles :

- si des actions sont requises lors de l’ouverture via la Vue d’ensemble, sélectionner À examiner ;
- sinon sélectionner Tous ;
- une recherche porte sur le nom et, si fourni, l’identifiant canonical ;
- afficher le nombre de résultats ;
- proposer une action pour effacer le filtre lorsque le résultat est vide.

### 10.9 Traduction des statuts de skills

| Backend | Titre UX | Description UX | Action possible |
|---|---|---|---|
| `managed_synced` | Synchronisé | Claude et Codex correspondent à la source gérée | aucune |
| `local_codex_only` | Présent uniquement dans Codex | Ce skill n’est pas encore géré par AI System | Importer |
| `local_claude_only` | Présent uniquement dans Claude | Cette commande n’est pas encore gérée par AI System | Importer si autorisé |
| `local_both_unmanaged` | Non géré | Les deux versions existent hors source gérée | Examiner/Importer |
| `missing_claude` | Export Claude manquant | La source gérée existe mais l’export Claude est absent | Synchroniser |
| `missing_codex` | Export Codex manquant | La source gérée existe mais l’export Codex est absent | Synchroniser |
| `canonical_drift` | Différent de la source | Un export ne correspond plus à la source gérée | Examiner/Synchroniser |
| `manifest_error` | Configuration invalide | Le backend ne peut pas déterminer une configuration valide | Afficher les détails |
| `conflict` | Conflit à résoudre | Plusieurs sources ou destinations sont incompatibles | Examiner |
| `expected_claude_only` | Claude uniquement — attendu | Cette exception est déclarée et ne nécessite aucune action | aucune |

Le backend reste autoritaire sur `importable`, les actions autorisées et la gravité.

### 10.10 Menu secondaire du projet

- ouvrir dans Finder ;
- ouvrir dans Cursor ;
- ouvrir dans Terminal ;
- copier le chemin ;
- afficher les détails techniques ;
- autres actions rares futures.

Les actions de retrait/désactivation, si elles sont ajoutées, doivent être séparées visuellement et confirmées.

---

## 11. Import d’un skill — spécification fonctionnelle

### 11.1 Préconditions

- le projet est résolu par le backend ;
- le skill est déclaré importable par le backend ;
- la source est identifiée ;
- aucune exception attendue n’interdit l’import ;
- aucune opération incompatible n’est en cours.

### 11.2 Déclenchement

L’action Importer est visible uniquement lorsque `importable == true`.

### 11.3 Sheet de confirmation

Afficher :

- nom du skill ;
- projet ;
- source détectée ;
- résultat attendu en langage humain ;
- destinations Claude/Codex ;
- avertissement si des fichiers seront remplacés, uniquement si le backend l’annonce ;
- section Détails repliée contenant chemins et identifiants techniques.

Boutons :

- Annuler ;
- **Importer le skill**.

### 11.4 Exécution

- la sheet peut rester ouverte avec un état de progression ou se transformer en progression dédiée ;
- les doubles soumissions sont bloquées ;
- la ligne du skill reflète l’opération en cours ;
- l’utilisateur peut continuer à consulter des informations non incompatibles ;
- une annulation n’est proposée que si `CommandRunner.cancelCurrent()` et le backend garantissent un état sûr.

### 11.5 Succès

- afficher une confirmation inline ;
- rescanner le projet ;
- vérifier que le skill devient `managed_synced` ou un autre état final attendu ;
- mettre à jour les compteurs ;
- créer une activité ;
- fournir Voir l’activité comme action secondaire.

### 11.6 Échec

Afficher :

- ce qui n’a pas fonctionné ;
- si des modifications ont été effectuées ou annulées ;
- code métier backend si utile ;
- action Réessayer si sûre ;
- action Afficher les détails.

Le texte brut de `stderr` ne doit pas être le message principal.

### 11.7 Idempotence

Un import répété doit :

- retourner un succès sans changement ou un état `already_managed` compréhensible ;
- ne pas dupliquer une entrée manifest ;
- ne pas créer plusieurs canonicals ;
- ne pas écraser un contenu incompatible.

---

## 12. Synchronisation — spécification fonctionnelle

### 12.1 Niveaux

- synchronisation d’un projet ;
- synchronisation globale des projets actifs ;
- synchronisation d’un skill si le backend l’autorise explicitement.

### 12.2 Cibles

Le backend détermine les cibles autorisées.

L’interface ne demande pas systématiquement Claude/Codex/les deux. Ce choix n’est affiché que :

- lorsque plusieurs options valides ont un effet réellement différent ;
- dans une section Options ;
- ou pour un outil avancé explicitement demandé.

### 12.3 Prévisualisation

Si le backend expose un mode de prévisualisation fiable, afficher avant confirmation :

- nombre de créations ;
- nombre de mises à jour ;
- nombre d’éléments inchangés ;
- conflits ;
- cibles.

Si aucune prévisualisation fiable n’existe, ne pas simuler ces valeurs côté SwiftUI.

### 12.4 Confirmation

- pas de confirmation pour une synchronisation manifestement idempotente et non destructive ;
- confirmation si des écrasements ou conflits sont annoncés ;
- la synchronisation globale peut être confirmée si elle affecte plusieurs projets.

### 12.5 Résultat

Exemple de résumé :

> Synchronisation terminée — 1 skill mis à jour, 19 inchangés, aucun conflit.

Les éléments inchangés ne doivent pas produire une longue liste visible par défaut.

---

## 13. Ajout d’un projet — spécification fonctionnelle

### 13.1 Déclenchement

- bouton `+` dans la toolbar de Projets ;
- commande de menu **Nouveau projet…** ;
- raccourci `⌘N` lorsque l’application est active.

### 13.2 Parcours

1. Ouvrir une sheet.
2. Sélectionner le dossier avec `NSOpenPanel`.
3. Déduire le nom depuis le dossier.
4. Afficher les environnements détectés ou les cibles proposées par le backend.
5. Permettre l’ajustement du nom si valide.
6. Présenter un résumé.
7. Ajouter le projet.
8. Lancer une première analyse.
9. Ouvrir le détail du projet.

### 13.3 Champs

#### Dossier

- requis ;
- choisi via `NSOpenPanel` ;
- chemin absolu affiché en texte secondaire ;
- pas de validation limitée à `starts(with: "/")` côté UI comme seule garantie ;
- validation autoritaire backend.

#### Nom

- prérempli ;
- modifiable ;
- validation backend ;
- erreur inline.

#### Cibles

- déduites lorsque possible ;
- options avancées seulement lorsque nécessaire ;
- respecter les règles du registry.

#### Installation immédiate

Présenter en langage métier :

> Configurer maintenant les skills partagés pour ce projet.

La valeur par défaut doit être définie après examen du comportement backend existant. Elle ne doit pas être modifiée arbitrairement pendant la refonte.

### 13.4 Erreurs

Cas minimaux :

- dossier inaccessible ;
- projet déjà déclaré ;
- nom invalide ;
- projet ambigu ;
- configuration Claude/Codex incompatible ;
- échec d’écriture ;
- validation globale échouée après ajout.

Chaque erreur doit indiquer si le projet a été ajouté ou non.

---

## 14. Activité — spécification fonctionnelle

### 14.1 Objectif

Unifier les résultats d’exécution, rapports et logs dans une représentation contextualisée.

### 14.2 Portée de la première version

La première version doit au minimum conserver toutes les opérations réalisées pendant la session active.

La persistance entre les lancements est recommandée, mais doit être implémentée uniquement avec un contrat clair :

- soit le backend maintient un historique structuré ;
- soit l’application persiste des métadonnées d’activité dans Application Support ;
- les logs backend restent les preuves autoritaires ;
- aucune sortie brute ne doit être interprétée comme modèle métier.

La décision session-only ou persistante doit être prise à l’étape Activité après inspection des capacités réelles du backend.

### 14.3 Modèle d’activité

Champs recommandés :

- `id` UUID ;
- `kind` ;
- `displayName` ;
- `scope` : global, projet, skill, outil ;
- `projectId` optionnel ;
- `skillId` optionnel ;
- `status` ;
- `startedAt` ;
- `finishedAt` optionnel ;
- `duration` optionnelle ;
- `summary` ;
- `changes` structurés si fournis ;
- `warningCount` ;
- `error` structuré optionnel ;
- référence vers rapports ;
- référence vers logs ;
- `exitCode` technique optionnel ;
- `stdout` et `stderr` techniques optionnels.

### 14.4 Liste d’activités

Chaque ligne affiche :

- titre humain ;
- statut ;
- cible ;
- date ;
- durée ;
- résumé court.

Filtres initiaux :

- Toutes ;
- Échecs ;
- Vérifications ;
- Synchronisations.

### 14.5 Détail d’une activité

Ordre obligatoire :

1. conclusion ;
2. changements ;
3. avertissements/erreurs ;
4. rapports et fichiers ;
5. détails techniques repliés.

### 14.6 Détails techniques

Contiennent :

- action backend ;
- arguments présentables sans secret ;
- exit code ;
- durée ;
- stdout ;
- stderr ;
- chemin du log ;
- Copier les détails ;
- Ouvrir le fichier log.

**FR-ACT-01** — Le monospaced est réservé à cette section.

**FR-ACT-02** — Les détails techniques sont repliés par défaut.

**FR-ACT-03** — Les données potentiellement sensibles ne doivent pas être ajoutées artificiellement aux logs.

**FR-ACT-04** — Le bouton Effacer l’affichage actuel est supprimé.

**FR-ACT-05** — Si une suppression d’historique est ajoutée, elle est distincte, explicite et confirmée.

---

## 15. Rapports, documentation et outils

### 15.1 Rapports

Inventory et Doctor sont accessibles :

- depuis l’activité de vérification qui les a produits ;
- depuis un menu secondaire de la Vue d’ensemble ;
- éventuellement depuis Réglages > Ressources.

Ils ne nécessitent plus une destination principale.

### 15.2 Documentation

Les documents suivants sont accessibles via le menu Aide ou Réglages > Ressources :

- README ;
- Operations ;
- Skill Workflow ;
- Project Onboarding ;
- Local GUI Design ;
- Plan AI System.

### 15.3 Outils

Les actions avancées sont regroupées dans Réglages > Avancé ou dans des menus contextuels :

- installer le hook pre-commit ;
- afficher l’état Git ;
- ouvrir dans Cursor ;
- ouvrir dans Terminal ;
- ouvrir dans Finder ;
- reconstruire l’application.

### 15.4 Règle de visibilité

Une action fréquente et contextuelle peut être visible dans la toolbar. Une action rare ou technique doit être dans un menu ou les réglages.

---

## 16. Réglages — spécification fonctionnelle

### 16.1 Accès

- menu application > Réglages ;
- raccourci `⌘,` ;
- fenêtre standard SwiftUI `Settings` si compatible avec la structure du projet.

### 16.2 Sections

#### Général

- destination au lancement si souhaité ;
- comportement après une action ;
- préférences non techniques réellement utiles.

Ne pas créer de réglages sans besoin confirmé.

#### Emplacements

- root AI System ;
- application installée ;
- dossier des logs ;
- boutons Ouvrir dans Finder.

Les chemins en dur existants peuvent être affichés, mais leur migration vers une configuration dynamique n’est pas incluse par défaut dans la refonte.

#### Intégrations

- disponibilité de Cursor ;
- Terminal ;
- Finder ;
- actions d’ouverture.

#### Avancé

- hook pre-commit ;
- état Git ;
- reconstruction de l’app ;
- ressources techniques ;
- version de l’application et informations backend.

### 16.3 Principes

- pas de log global dans les Réglages ;
- feedback inline pour chaque action ;
- confirmations uniquement si nécessaires ;
- sections avancées clairement séparées.

---

## 17. Feedback et gestion des erreurs

### 17.1 Succès

Un succès ordinaire est signalé par :

- mise à jour visible de l’état ;
- message inline temporaire ou persistant tant qu’utile ;
- activité créée.

Ne pas utiliser d’alerte modale pour un succès ordinaire.

### 17.2 Avertissement

Un avertissement :

- n’empêche pas nécessairement l’utilisation ;
- explique la conséquence ;
- propose une action si nécessaire ;
- ne doit pas être coloré comme une erreur bloquante.

### 17.3 Erreur

Une erreur présente :

1. l’action qui a échoué ;
2. l’objet concerné ;
3. ce qui a ou non été modifié ;
4. la cause compréhensible ;
5. la prochaine action ;
6. un accès aux détails techniques.

### 17.4 Alertes et sheets

Utiliser une alerte ou confirmation pour :

- écrasement annoncé ;
- conflit ;
- retrait/suppression ;
- opération globale ayant un impact important ;
- abandon d’un formulaire contenant des modifications importantes.

Ne pas utiliser d’alerte pour :

- ouvrir un fichier ;
- confirmer une vérification en lecture seule ;
- annoncer un succès simple ;
- afficher une longue erreur technique.

### 17.5 Messages backend

Le backend doit fournir si possible :

- code stable ;
- titre/message humain ;
- détails techniques ;
- caractère retryable ;
- état d’écriture/rollback ;
- action suggérée.

SwiftUI peut mapper un code stable vers une copie française, mais ne doit pas déduire un statut métier en parsant une phrase libre.

---

## 18. Système visuel

### 18.1 Principes

- utiliser la typographie système ;
- utiliser les styles sémantiques SwiftUI ;
- utiliser les couleurs système ;
- respecter la couleur d’accent macOS ;
- utiliser SF Symbols ;
- privilégier listes, tables, sections et séparateurs ;
- éviter la multiplication des cartes décoratives ;
- éviter les ombres fortes et bordures personnalisées omniprésentes ;
- accepter la densité d’une application desktop tout en maintenant une bonne respiration.

### 18.2 Échelle d’espacement

Échelle recommandée :

- 4 points : micro-espacement ;
- 8 points : éléments liés ;
- 12 points : contrôles d’un groupe ;
- 16 points : padding standard ;
- 24 points : séparation de sections ;
- 32 points : grandes ruptures.

Cette échelle est une base cohérente, pas une obligation de figer chaque mesure.

### 18.3 Typographie

- titre de destination : style système approprié, sans duplication ;
- titre de section : `headline` ;
- contenu : `body` ;
- métadonnées : `subheadline` ou `caption` avec contraste suffisant ;
- technique : monospaced uniquement dans Détails techniques.

### 18.4 Couleurs sémantiques

- accent : sélection/action principale ;
- vert : sain/succès confirmé ;
- orange : attention ;
- rouge : erreur bloquante/destructif ;
- secondaire : neutre/non vérifié.

Éviter les couleurs RGB fixes si une couleur sémantique système convient.

### 18.5 Boutons

- une action principale accentuée par contexte ;
- boutons secondaires bordered/plain selon le contexte ;
- icône seule uniquement lorsque le sens est standard et accompagné d’une tooltip ;
- verbes directs et compréhensibles ;
- pas de noms de scripts dans les libellés principaux.

### 18.6 Cards

Une card est justifiée seulement lorsqu’elle regroupe un ensemble cohérent autonome. Ne pas recréer un dashboard web par une grille de cartes KPI.

### 18.7 Adaptation

- mode clair ;
- mode sombre ;
- contraste accru ;
- couleur d’accent personnalisée par l’utilisateur ;
- réduction de transparence ;
- réduction des animations.

---

## 19. Accessibilité et commandes macOS

### 19.1 Clavier

- `⌘N` : ajouter un projet ;
- `⌘R` : vérifier/actualiser le contexte courant ;
- `⌘F` : rechercher dans Projets ou Activité ;
- `⌘,` : Réglages ;
- navigation sidebar/listes/tables au clavier ;
- Échap ferme les sheets/popovers non bloquants ;
- Retour active l’action principale uniquement lorsque conforme aux conventions macOS.

### 19.2 VoiceOver

Chaque contrôle doit posséder :

- label explicite ;
- valeur ou état ;
- hint uniquement s’il ajoute une information utile.

Les statuts visuels doivent être annoncés textuellement.

### 19.3 Contraste

- pas de texte critique en `secondary` trop faible ;
- valider clair/sombre ;
- ne pas utiliser uniquement rouge/vert pour distinguer deux états.

### 19.4 Animation

- transitions courtes et fonctionnelles ;
- aucun mouvement décoratif permanent ;
- respecter Reduce Motion ;
- ne pas animer de grands blocs de logs.

### 19.5 Tooltips

Tout bouton représenté uniquement par un symbole possède une tooltip courte décrivant l’action.

---

## 20. Architecture technique SwiftUI cible

### 20.1 Principes

- vues déclaratives et relativement petites ;
- modèles métier `Codable` correspondant aux contrats JSON ;
- état partagé limité et explicite ;
- orchestration asynchrone hors des vues ;
- aucune lecture de YAML dans SwiftUI ;
- aucune interprétation de logs pour calculer les statuts ;
- dépendances injectables pour les tests.

### 20.2 Organisation de fichiers proposée

L’organisation exacte doit tenir compte des fichiers déjà créés au début de chaque étape.

```text
AI System/
├── App/
│   ├── AI_SystemApp.swift
│   ├── AppCommands.swift
│   └── AppSection.swift
├── Models/
│   ├── BackendAction.swift
│   ├── CommandResult.swift
│   ├── SystemOverviewModels.swift
│   ├── ProjectSkillsModels.swift
│   ├── ActivityModels.swift
│   └── SemanticStatus.swift
├── Services/
│   ├── AISystemPaths.swift
│   ├── CommandRunner.swift
│   ├── CommandCenter.swift
│   ├── BackendJSONDecoder.swift
│   └── ActivityStore.swift
├── Features/
│   ├── Overview/
│   │   ├── OverviewView.swift
│   │   └── OverviewViewModel.swift
│   ├── Projects/
│   │   ├── ProjectsView.swift
│   │   ├── ProjectDetailView.swift
│   │   ├── ProjectSkillsView.swift
│   │   ├── ImportSkillSheet.swift
│   │   ├── AddProjectSheet.swift
│   │   └── ProjectsViewModel.swift
│   ├── Activity/
│   │   ├── ActivityView.swift
│   │   ├── ActivityDetailView.swift
│   │   └── TechnicalDetailsView.swift
│   └── Settings/
│       └── SettingsView.swift
└── Views/
    └── Components/
        ├── SemanticStatusView.swift
        ├── InlineFeedbackView.swift
        ├── EmptyStateView.swift
        ├── SectionHeader.swift
        └── LoadingStateView.swift
```

Il n’est pas obligatoire de déplacer immédiatement tous les fichiers existants. La migration de l’arborescence doit rester mécanique et ne pas mélanger déplacement massif et changement fonctionnel dans une même sous-étape si cela complique la revue.

### 20.3 AppSection

Remplacer ou faire évoluer `SidebarSection` vers :

- `overview` ;
- `projects` ;
- `activity`.

Les anciennes cases peuvent rester temporairement pendant une phase de migration derrière un mécanisme de compatibilité, puis être retirées lorsque leurs fonctions sont relogées.

### 20.4 CommandRunner

À préserver :

- actor ;
- `Process` ;
- `/usr/bin/env bash` ;
- `process.arguments` ;
- environnement `AI_SYSTEM_UI_MODE=swift` ;
- capture séparée stdout/stderr ;
- durée et exit code ;
- annulation si sûre.

Améliorations permises si testées :

- identifiant de run ;
- timestamps ;
- meilleure propagation de cancellation ;
- retour d’un résultat typé générique au-dessus du résultat brut ;
- capture progressive si un besoin UX confirmé apparaît.

### 20.5 CommandCenter

Responsabilités cibles :

- sérialiser les opérations incompatibles ;
- exposer l’opération active ;
- déclencher le runner ;
- enregistrer une activité ;
- retourner le `CommandResult` au service appelant ;
- ne plus exposer un unique `lastResult` comme état visuel de toutes les vues.

API cible indicative :

```swift
func execute(
    _ request: BackendRequest,
    context: OperationContext
) async -> OperationResult
```

La signature exacte doit être adaptée au code réel. L’objectif obligatoire est qu’un appelant reçoive son propre résultat et que les autres vues ne l’affichent pas par défaut.

### 20.6 View models / stores

Les view models peuvent être des classes `@Observable`, idéalement isolées au `@MainActor` lorsque leurs mutations pilotent l’UI.

Responsabilités :

- charger/décoder ;
- exposer `loading/content/empty/error` ;
- orchestrer les actions ;
- appliquer filtres et sélection purement UI ;
- demander un rafraîchissement après mutation.

Ils ne doivent pas :

- calculer la validité d’un canonical ;
- déduire un pairing à partir de chemins ;
- parser stdout pour créer un statut métier ;
- écrire le registry ou manifest.

### 20.7 Injection et testabilité

Prévoir des protocoles légers uniquement là où ils améliorent réellement les tests, par exemple :

```swift
protocol BackendExecuting {
    func execute(_ request: BackendRequest) async -> CommandResult
}
```

Éviter une architecture abstraite excessive. Les doubles de test doivent permettre de fournir des JSON valides, des erreurs et des délais contrôlés.

---

## 21. Contrats backend attendus

### 21.1 Principe général

Les routes machine renvoient du JSON stable sur stdout. Les diagnostics techniques vont sur stderr sans casser le décodage JSON.

Enveloppe recommandée :

```json
{
  "schemaVersion": 1,
  "status": "ok",
  "generatedAt": "2026-08-20T18:42:00Z",
  "data": {},
  "error": null
}
```

Le chantier réel `project_skills.py` peut avoir une enveloppe différente. L’étape 1 doit inventorier et adopter le contrat réel plutôt que forcer cet exemple.

### 21.2 Routes minimales

#### Projets

- `list-projects --json`
- `scan --project <id> --json`
- `overview --json`

#### Actions

- `import --project <id> --skill <name> --source <source> --json`
- `sync --project <id> --json`

#### Compatibilité

Les routes doivent être exposées par `ai_system_action.sh` avec arguments séparés et validation stricte.

### 21.3 Données projet minimales

```json
{
  "id": "Suggst",
  "name": "Suggst",
  "root": "/Users/.../Suggst",
  "enabled": true,
  "allowedTargets": ["claude", "codex"],
  "lastScannedAt": "2026-08-20T18:42:00Z"
}
```

### 21.4 Données de synthèse minimales

```json
{
  "projectsTotal": 10,
  "projectsHealthy": 9,
  "projectsAttention": 1,
  "projectsError": 0,
  "actionRequired": 1,
  "expectedExceptions": 6,
  "lastCheckedAt": "2026-08-20T18:42:00Z"
}
```

### 21.5 Données skill minimales

```json
{
  "id": "new-skill",
  "name": "new-skill",
  "canonicalId": null,
  "scope": null,
  "status": "local_codex_only",
  "managed": false,
  "importable": true,
  "presence": {
    "claude": false,
    "codex": true
  },
  "allowedActions": ["import"],
  "exception": null,
  "conflict": null
}
```

### 21.6 Erreur structurée

```json
{
  "code": "canonical_conflict",
  "message": "Une source gérée incompatible existe déjà.",
  "technicalDetails": "...",
  "retryable": false,
  "writeState": "no_changes",
  "suggestedAction": "review_conflict"
}
```

Champs recommandés :

- code stable ;
- message humain ;
- détails ;
- retryable ;
- état d’écriture ;
- action suggérée.

### 21.7 Versionnement

- `schemaVersion` est obligatoire ;
- Swift refuse proprement une version majeure inconnue ;
- les champs additionnels sont tolérés ;
- les champs obligatoires manquants produisent une erreur de décodage contextualisée ;
- des fixtures JSON versionnées sont conservées dans les tests Swift.

### 21.8 Aucune interprétation de stdout humain

Les vues métier ne doivent pas dériver :

- nombres de skills ;
- statut ;
- conflits ;
- cible ;
- action requise ;
- réussite partielle

à partir de lignes telles que `unchanged:` ou `updated:`.

---

## 22. États de chargement et concurrence

### 22.1 États de vue

Chaque feature doit distinguer :

- initial ;
- loading sans contenu ;
- refreshing avec contenu existant ;
- content ;
- empty ;
- error récupérable.

### 22.2 Sérialisation

Une seule opération backend mutante à la fois, sauf preuve que des opérations peuvent être parallélisées sans risque.

### 22.3 Désactivation

Ne pas désactiver toute l’application pendant une opération si seule une partie est incompatible.

Exemples :

- pendant l’import d’un skill, empêcher un second import/sync ;
- autoriser la consultation de l’activité ;
- autoriser la navigation ;
- éviter le clignotement global de tous les boutons.

### 22.4 Données obsolètes

Lors d’un rafraîchissement :

- conserver l’ancien contenu ;
- afficher qu’une actualisation est en cours ;
- remplacer atomiquement les données lorsque le décodage réussit ;
- conserver l’ancien contenu avec une erreur inline si l’actualisation échoue.

---

## 23. Sécurité et robustesse

### 23.1 Arguments

- chaque argument reste un élément séparé ;
- aucun interpolation shell ;
- aucune donnée utilisateur passée à `eval` ;
- validation backend des projets et chemins ;
- refus des path escapes et symlinks sortants selon les règles du backend.

### 23.2 Fichiers

- les imports restent atomiques ;
- aucun écrasement silencieux ;
- le backend rapporte `writeState` ;
- SwiftUI ne modifie pas directement manifest, registry, canonicals ou exports.

### 23.3 Logs

- ne pas introduire de secrets supplémentaires ;
- éviter d’afficher inutilement tous les chemins sur les écrans principaux ;
- conserver les détails nécessaires au diagnostic ;
- copier les logs uniquement sur action explicite.

### 23.4 Annulation

Une action Annuler n’est affichée que si :

- le processus peut être terminé proprement ;
- le backend garantit un état cohérent ;
- l’UI peut déterminer le résultat `cancelled`.

Sinon, afficher seulement la progression et empêcher la relance concurrente.

---

## 24. Stratégie de tests

### 24.1 Tests backend

À conserver/ajouter selon la phase :

- résolution stricte de projet ;
- projet inconnu/désactivé/ambigu ;
- scan Claude/Codex ;
- statuts de skills ;
- exceptions attendues ;
- import idempotent ;
- conflit canonical ;
- conflit destination ;
- path escape ;
- JSON valide sur succès et erreur ;
- aucune sortie parasite sur stdout JSON ;
- routes shell sans `eval` pour les paramètres.

### 24.2 Tests Swift unitaires

- décodage des fixtures JSON ;
- version de schéma inconnue ;
- mapping statut backend vers présentation ;
- tri des projets ;
- filtres de skills ;
- transition loading/content/error ;
- préservation du contenu lors d’un refresh échoué ;
- résultat attaché à la bonne activité ;
- aucune propagation d’un échec vers une vue non concernée ;
- orchestration import puis rescan ;
- double soumission bloquée.

### 24.3 Tests UI

Parcours minimaux :

1. lancement sans observation ;
2. vérification saine ;
3. vérification avec action requise ;
4. navigation accueil → projet → skill ;
5. import réussi ;
6. import en conflit ;
7. synchronisation réussie ;
8. ajout de projet ;
9. activité et détails techniques ;
10. Réglages ;
11. raccourcis clavier principaux.

### 24.4 Tests visuels manuels

Pour chaque feature :

- mode clair ;
- mode sombre ;
- petite fenêtre ;
- grande fenêtre ;
- sidebar réduite/masquée ;
- texte long ;
- nom de projet long ;
- zéro, un et plusieurs problèmes ;
- progression ;
- erreur ;
- état vide ;
- contraste accru ;
- Reduce Motion.

### 24.5 Validation globale

À la fin de chaque étape :

1. tests ciblés ;
2. build Debug ou Release selon la phase ;
3. `make inventory` ;
4. `make doctor` ;
5. `make check` ;
6. lorsqu’une étape touche l’app complète : `make build-swift-app` ;
7. test de `~/Applications/AI System.app`.

---

## 25. Plan d’implémentation détaillé

Chaque étape doit produire une application compilable. Une étape ne commence pas tant que les critères bloquants de la précédente ne sont pas satisfaits.

### ÉTAPE UX-00 — Baseline et inventaire de l’état réel

#### Objectif

Établir la source de vérité avant toute refonte, notamment après la fin du chantier `project_skills.py`.

#### Travaux

1. Inspecter `git status --short`.
2. Inventorier les fichiers Swift actuels.
3. Inventorier les scripts backend et tests liés aux project skills.
4. Lire les contrats JSON réellement implémentés.
5. Exécuter les tests du chantier project skills.
6. Exécuter le scan réel de Suggst en lecture seule.
7. Vérifier que les sept skills Suggst sont reconnus comme gérés/synchronisés.
8. Capturer l’état de build SwiftUI.
9. Documenter les écarts entre cette spécification et le code réel.

#### Interdictions

- aucune refonte visuelle ;
- aucune modification métier non nécessaire ;
- aucune migration de fichiers Swift ;
- aucun commit.

#### Livrable

Une section de suivi ou note d’implémentation contenant :

- baseline ;
- contrats disponibles ;
- fichiers concernés ;
- risques ;
- décisions nécessaires.

#### Critères d’acceptation

- état du worktree connu ;
- build actuel connu ;
- contrats project skills connus ;
- Suggst scanné sans mutation ;
- aucune régression introduite ;
- `make check` vert ou échec préexistant documenté précisément.

---

### ÉTAPE UX-01 — Stabilisation des contrats backend et modèles Swift

#### Objectif

Créer une frontière métier fiable avant de construire la nouvelle interface.

#### Travaux backend

1. Finaliser ou valider `list-projects --json`.
2. Finaliser ou valider `scan --project --json`.
3. Définir/valider `overview --json` ou une composition équivalente fiable.
4. Stabiliser `schemaVersion`.
5. Garantir les erreurs JSON structurées.
6. Ajouter les routes sûres dans `ai_system_action.sh`.
7. Garantir stdout JSON propre.

#### Travaux Swift

1. Créer/adapter `ProjectSkillsModels.swift`.
2. Créer `SystemOverviewModels.swift`.
3. Créer les modèles d’erreur structurée.
4. Créer un décodeur JSON centralisé.
5. Ajouter une API de `CommandCenter` retournant le résultat à l’appelant.
6. Conserver les APIs existantes tant que les anciennes vues en dépendent.

#### Tests

- fixtures succès/erreur ;
- décodage ;
- version inconnue ;
- projet désactivé/inconnu ;
- scan Suggst ;
- vérification shell syntaxique.

#### Critères d’acceptation

- aucune vue parse du YAML ;
- aucune vue parse stdout pour calculer un statut ;
- modèles Swift décodent les réponses réelles ;
- routes paramétrées utilisent des arguments séparés ;
- anciennes fonctionnalités encore utilisables ;
- build vert ;
- `make check` vert.

---

### ÉTAPE UX-02 — Fondations visuelles et nouveau shell

#### Objectif

Mettre en place la navigation cible sans réimplémenter encore toutes les features.

#### Travaux

1. Introduire `AppSection` : overview, projects, activity.
2. Adapter le `NavigationSplitView`.
3. Créer la toolbar contextuelle.
4. Mettre en place la persistance de sélection.
5. Définir les composants sémantiques fondamentaux :
   - statut ;
   - feedback inline ;
   - état vide ;
   - chargement ;
   - section.
6. Définir l’échelle d’espacement et les usages typographiques dans le code, sans créer un design system abstrait excessif.
7. Créer des placeholders fonctionnels propres pour les trois destinations.
8. Maintenir temporairement l’accès aux anciennes fonctions via menus si nécessaire.

#### Migration

Les anciennes vues ne sont supprimées que lorsque leurs fonctions ont une destination cible effective.

#### Tests

- sélection sidebar ;
- restauration ;
- toolbar par destination ;
- redimensionnement ;
- clair/sombre ;
- build Release.

#### Critères d’acceptation

- seulement trois destinations principales visibles ;
- aucune fonction critique rendue inaccessible ;
- pas de duplication de titre gênante ;
- fenêtre utilisable à la taille minimale ;
- composants visibles en clair et sombre ;
- build et `make check` verts.

---

### ÉTAPE UX-03 — Vue d’ensemble métier

#### Objectif

Remplacer le Dashboard technique par un état global compréhensible.

#### Travaux

1. Créer `OverviewViewModel`.
2. Charger l’overview backend.
3. Implémenter unknown/checking/healthy/attention/error.
4. Afficher la date de dernière vérification.
5. Afficher les actions requises prioritaires.
6. Afficher le résumé des projets.
7. Afficher l’activité récente disponible.
8. Implémenter Vérifier maintenant.
9. Implémenter la navigation vers le projet concerné.
10. Ne jamais afficher les logs bruts.

#### Tests

- cinq états globaux ;
- zéro/un/plusieurs problèmes ;
- erreur de refresh avec ancien contenu conservé ;
- navigation vers projet ;
- désactivation pendant vérification ;
- texte long.

#### Critères d’acceptation

- santé compréhensible sans log ;
- dernière vérification visible ;
- action principale unique ;
- une anomalie ouvre son contexte ;
- l’ancien `lastResult` n’est plus affiché sur l’accueil ;
- build/app installée validés.

---

### ÉTAPE UX-04 — Projets en lecture seule

#### Objectif

Créer la nouvelle expérience de consultation des projets et skills avant d’activer les mutations.

#### Travaux

1. Charger `list-projects`.
2. Implémenter liste, tri et sélection.
3. Charger le scan du projet sélectionné.
4. Implémenter l’en-tête projet.
5. Implémenter le résumé.
6. Implémenter la Table/List des skills.
7. Implémenter recherche et filtres.
8. Traduire les statuts backend.
9. Afficher les exceptions attendues sans alerte.
10. Implémenter états vide/loading/error.
11. Ajouter les actions secondaires d’ouverture sûres.

#### Tests

- liste vide ;
- projet sain ;
- projet avec action ;
- conflit ;
- exception Claude-only ;
- recherche ;
- filtres ;
- conservation sélection ;
- projet supprimé/désactivé entre deux chargements.

#### Critères d’acceptation

- aucun nom de projet à saisir pour consulter un projet existant ;
- Suggst affiche correctement ses sept skills spécifiques ;
- exceptions attendues non comptées comme problèmes ;
- filtres cohérents ;
- aucun calcul métier dupliqué ;
- build et validations verts.

---

### ÉTAPE UX-05 — Import et synchronisation des skills

#### Objectif

Permettre les actions métier centrales depuis la nouvelle vue Projets.

#### Précondition

Les routes backend import/sync doivent être finalisées, sûres, idempotentes et testées.

#### Travaux backend

1. Finaliser `import`.
2. Finaliser `sync`.
3. Exposer allowedActions/importable.
4. Exposer erreurs structurées et writeState.
5. Valider l’idempotence.

#### Travaux Swift

1. Créer `ImportSkillSheet`.
2. Implémenter l’état d’opération par skill.
3. Empêcher les doubles soumissions.
4. Rescanner après succès.
5. Implémenter Synchroniser le projet.
6. Présenter le résumé du résultat.
7. Rendre les détails accessibles mais repliés.
8. Créer une activité pour chaque opération.

#### Tests

- import Codex-only ;
- import Claude-only autorisé ;
- exception attendue non importable ;
- already managed ;
- conflit canonical ;
- conflit destination ;
- sync créant un export manquant ;
- sync sans changement ;
- erreur après écriture/rollback ;
- rescan après succès.

#### Critères d’acceptation

- import réalisable sans connaître manifest/canonical ;
- confirmation décrit la conséquence ;
- cible non demandée inutilement ;
- succès visible sans lire stdout ;
- conflit non écrasé ;
- activité créée ;
- Suggst reste sain après test non destructif ou fixture ;
- validations globales vertes.

---

### ÉTAPE UX-06 — Nouveau parcours d’ajout de projet

#### Objectif

Remplacer le formulaire technique permanent par un workflow guidé en sheet.

#### Travaux

1. Créer `AddProjectSheet`.
2. Déclencher par toolbar/menu/`⌘N`.
3. Utiliser `NSOpenPanel`.
4. Préremplir le nom.
5. Présenter les cibles détectées/autorisées.
6. Placer les options rares dans Options.
7. Appeler la route backend existante de façon sûre.
8. Afficher progression et erreurs inline.
9. Lancer le premier scan.
10. Sélectionner le nouveau projet.

#### Tests

- annulation du panel ;
- chemin avec espaces ;
- nom existant ;
- dossier inaccessible ;
- cible unique ;
- ajout sans installation ;
- ajout avec installation ;
- validation post-ajout échouée ;
- double clic.

#### Critères d’acceptation

- aucun champ chemin vide permanent dans Projets ;
- choix de dossier natif ;
- nom prérempli ;
- erreurs contextualisées ;
- projet visible et sélectionné après ajout ;
- aucun parsing/écriture registry côté Swift ;
- build et validations verts.

---

### ÉTAPE UX-07 — Activité et détails techniques

#### Objectif

Remplacer les panneaux de résultats globaux, Rapports et Logs par une expérience contextualisée.

#### Décision préalable

Choisir et documenter :

- activité session-only ; ou
- persistance locale structurée ; ou
- historique structuré backend.

Le choix initial le plus simple acceptable est session-only, à condition que le dernier log fichier reste accessible.

#### Travaux

1. Créer `ActivityModels`.
2. Enregistrer chaque opération CommandCenter.
3. Créer la liste Activité.
4. Créer le détail.
5. Ajouter filtres et recherche.
6. Attacher rapports Inventory/Doctor.
7. Créer Détails techniques repliés.
8. Copier les détails.
9. Ouvrir le fichier log.
10. Retirer les `ResultPanel` des autres écrans.
11. Retirer les anciennes destinations Rapports et Logs une fois leurs fonctions couvertes.

#### Tests

- activité running puis success ;
- failure ;
- partial success ;
- ordre chronologique ;
- bonne association projet/skill ;
- détails repliés ;
- copie ;
- fichier log absent ;
- rapports absents ;
- navigation depuis une erreur.

#### Critères d’acceptation

- chaque résultat a un contexte ;
- aucune erreur ancienne affichée partout ;
- conclusion avant stdout ;
- stdout/stderr accessibles ;
- Rapports et Logs peuvent disparaître de la sidebar sans perte fonctionnelle ;
- build/app installée validés.

---

### ÉTAPE UX-08 — Réglages, documentation et outils avancés

#### Objectif

Reloger toutes les fonctions secondaires sans surcharger la navigation.

#### Travaux

1. Créer la fenêtre Réglages.
2. Ajouter Emplacements.
3. Ajouter Intégrations.
4. Ajouter Avancé.
5. Reloger hook, Git status et rebuild.
6. Reloger les ouvertures Cursor/Terminal/Finder.
7. Reloger la documentation dans Aide/Ressources.
8. Fournir feedback inline pour chaque action.
9. Retirer les anciennes destinations Documentation et Outils.

#### Tests

- `⌘,` ;
- ouverture des fichiers existants ;
- fichier absent ;
- Cursor absent ;
- hook réussi/échoué ;
- Git status ;
- rebuild ;
- feedback non propagé aux autres sections.

#### Critères d’acceptation

- seulement trois destinations principales ;
- toutes les fonctions secondaires restent accessibles ;
- aucun panneau de log global dans Réglages ;
- actions rares clairement séparées ;
- fallback AppleScript préservé ;
- validations vertes.

---

### ÉTAPE UX-09 — Menus, raccourcis, accessibilité et polish

#### Objectif

Finaliser l’expérience macOS native.

#### Travaux

1. Ajouter `AppCommands`.
2. Implémenter `⌘N`, `⌘R`, `⌘F`, `⌘,`.
3. Vérifier navigation clavier.
4. Ajouter tooltips.
5. Ajouter labels VoiceOver.
6. Vérifier contrastes.
7. Vérifier Reduce Motion/Transparency.
8. Ajuster la densité, les espacements et tailles minimales.
9. Tester noms et messages longs.
10. Ajouter transitions sobres si elles clarifient l’état.
11. Vérifier mode clair/sombre et couleur d’accent.

#### Critères d’acceptation

- parcours principal complet sans souris ;
- aucun statut porté uniquement par la couleur ;
- icônes seules documentées par tooltip/accessibility label ;
- app lisible en clair/sombre/contraste accru ;
- aucune animation indispensable à la compréhension ;
- validation humaine sur l’app installée.

---

### ÉTAPE UX-10 — Nettoyage contrôlé et clôture

#### Objectif

Supprimer les anciens éléments devenus inutiles, mettre à jour la documentation et figer la validation finale.

#### Travaux

1. Identifier les vues et composants réellement obsolètes.
2. Vérifier qu’aucune fonction n’est perdue.
3. Supprimer uniquement les éléments remplacés.
4. Conserver AppleScript et scripts fallback.
5. Mettre à jour :
   - README ;
   - OPERATIONS ;
   - SWIFTUI-GUI-PLAN ;
   - LOCAL-GUI-DESIGN ou document de statut équivalent ;
   - Plan-AI-System.
6. Documenter la nouvelle architecture.
7. Documenter les contrats JSON.
8. Exécuter tous les tests.
9. Construire et installer l’app Release.
10. Réaliser la recette complète.

#### Recette finale

- lancement ;
- état inconnu ;
- vérification saine ;
- action requise ;
- navigation vers projet ;
- import ;
- synchronisation ;
- ajout de projet ;
- activité ;
- erreur ;
- détails techniques ;
- réglages ;
- outils ;
- raccourcis ;
- clair/sombre ;
- taille minimale ;
- relance de l’application.

#### Critères d’acceptation

- aucune ancienne destination orpheline ;
- aucune fonction critique perdue ;
- aucune logique métier ajoutée dans SwiftUI ;
- aucune route paramétrée dangereuse ;
- tests backend et Swift verts ;
- `make inventory` vert ;
- `make doctor` vert ;
- `make check` vert ;
- `make build-swift-app` vert ;
- app installée validée ;
- worktree final documenté ;
- aucun commit automatique.

---

## 26. Dépendances entre étapes

| Étape | Dépend de | Peut être fractionnée |
|---|---|---|
| UX-00 | aucune | non |
| UX-01 | UX-00, chantier project skills | oui : backend puis Swift |
| UX-02 | UX-01 partiel | oui : shell puis composants |
| UX-03 | UX-01, UX-02 | oui : lecture puis actions |
| UX-04 | UX-01, UX-02 | oui : liste puis détail puis skills |
| UX-05 | UX-04, routes import/sync | oui : import puis sync |
| UX-06 | UX-02, backend add-project | oui |
| UX-07 | UX-02, CommandCenter évolué | oui : session puis persistance |
| UX-08 | UX-02, UX-07 partiel | oui |
| UX-09 | UX-03 à UX-08 | oui par feature |
| UX-10 | toutes | non |

UX-03 et UX-04 peuvent avancer dans un ordre inversé après UX-01/UX-02, mais il est recommandé de livrer la Vue d’ensemble d’abord pour valider le nouveau modèle sémantique.

---

## 27. Priorités MoSCoW

### Must have

- trois destinations ;
- état global sémantique ;
- projets alimentés par backend ;
- détail et statuts de skills ;
- import/sync ;
- ajout guidé ;
- activités contextualisées ;
- détails techniques repliés ;
- erreurs locales ;
- clair/sombre ;
- clavier/accessibilité de base ;
- compatibilité CLI.

### Should have

- activité persistante entre lancements ;
- recherche/filtres ;
- rapports attachés aux activités ;
- Réglages complets ;
- restauration de sélection ;
- raccourcis clavier complets.

### Could have

- progression détaillée ;
- notifications système ;
- aperçu des changements avant sync ;
- comparaison de drift ;
- vérification automatique configurable.

### Won’t have dans cette refonte

- backend distant ;
- collaboration ;
- App Store ;
- éditeur de YAML ;
- terminal intégré ;
- framework UI tiers.

---

## 28. Risques et mitigations

| Risque | Impact | Mitigation |
|---|---|---|
| contrat `project_skills.py` encore mouvant | modèles Swift instables | figer UX-01 avant les vues |
| refonte trop large | régressions et revue difficile | étapes compilables et gates |
| statut calculé dans Swift | divergence métier | backend autoritaire + fixtures |
| ancien `lastResult` global | erreurs hors contexte | résultat retourné à l’appelant + ActivityStore |
| logs non structurés | UX technique | JSON métier, logs en dernier niveau |
| historique persistant complexe | scope excessif | session-only acceptable initialement |
| actions simultanées | corruption/état incohérent | CommandCenter sérialisé |
| worktree chargé | écrasement de travail | inspection par étape, patchs ciblés |
| suppression trop tôt des vues | perte fonctionnelle | reloger avant supprimer |
| custom UI trop marquée | incohérence macOS | composants système/HIG |
| chemins en dur | portabilité limitée | ne pas mélanger avec refonte ; documenter |
| project.pbxproj modifié | conflits Xcode | synchronized root group |

---

## 29. Checklist obligatoire par étape

### Avant modification

- [ ] Lire les instructions du dépôt si présentes.
- [ ] Inspecter `git status --short`.
- [ ] Identifier les modifications préexistantes dans les fichiers ciblés.
- [ ] Lire les fichiers réels concernés.
- [ ] Vérifier les contrats backend réels.
- [ ] Définir les tests ciblés.

### Pendant

- [ ] Garder l’étape dans son périmètre.
- [ ] Préserver les APIs de compatibilité nécessaires.
- [ ] Ne pas parser YAML/logs dans SwiftUI.
- [ ] Utiliser des arguments séparés.
- [ ] Ajouter les tests en même temps que le comportement.
- [ ] Vérifier les états loading/empty/error.

### Après

- [ ] Tests ciblés verts.
- [ ] Build vert.
- [ ] Mode clair vérifié.
- [ ] Mode sombre vérifié.
- [ ] Taille minimale vérifiée.
- [ ] `make inventory` vert.
- [ ] `make doctor` vert.
- [ ] `make check` vert.
- [ ] App installée testée si l’étape modifie l’expérience complète.
- [ ] `git diff` relu.
- [ ] Aucun commit créé.

---

## 30. Definition of Done globale

La refonte est terminée lorsque toutes les conditions suivantes sont satisfaites :

### Produit

- [ ] La Vue d’ensemble permet de comprendre l’état sans log.
- [ ] Les actions requises sont immédiatement identifiables.
- [ ] Projets permet de consulter tous les projets actifs.
- [ ] Les statuts de skills sont compréhensibles.
- [ ] Import et synchronisation fonctionnent depuis l’UI.
- [ ] L’ajout de projet est guidé.
- [ ] Activité contextualise toutes les opérations.
- [ ] Rapports et logs restent accessibles.
- [ ] Documentation et outils restent accessibles.

### UX/UI

- [ ] Trois destinations principales seulement.
- [ ] Une action principale claire par contexte.
- [ ] Détails techniques repliés.
- [ ] Aucune erreur globale hors contexte.
- [ ] États vides, chargement et erreurs complets.
- [ ] Application cohérente en clair et sombre.
- [ ] Interface utilisable à la taille minimale.
- [ ] Conventions macOS respectées.

### Accessibilité

- [ ] Parcours principal clavier.
- [ ] VoiceOver labels sur contrôles et statuts.
- [ ] Aucune information portée uniquement par la couleur.
- [ ] Contraste accru vérifié.
- [ ] Reduce Motion pris en compte.
- [ ] Tooltips sur icônes seules.

### Technique

- [ ] Logique métier exclusivement backend.
- [ ] Contrats JSON versionnés.
- [ ] Aucun parsing YAML dans Swift.
- [ ] Aucun parsing stdout pour les statuts.
- [ ] Arguments Process séparés.
- [ ] Opérations mutantes sérialisées.
- [ ] Tests backend et Swift verts.
- [ ] AppleScript fallback conservé.
- [ ] Sandbox désactivé conservé.
- [ ] Projet Xcode non recréé.

### Validation

- [ ] `make inventory` OK.
- [ ] `make doctor` OK.
- [ ] `make check` OK.
- [ ] `make build-swift-app` OK.
- [ ] `~/Applications/AI System.app` testée.
- [ ] Aucun commit automatique.

---

## 31. Résumé opérationnel

L’implémentation doit suivre cette séquence :

1. **UX-00** — connaître l’état réel ;
2. **UX-01** — stabiliser les contrats et modèles ;
3. **UX-02** — installer le nouveau shell ;
4. **UX-03** — livrer la Vue d’ensemble ;
5. **UX-04** — livrer Projets en lecture ;
6. **UX-05** — activer import et synchronisation ;
7. **UX-06** — refaire l’ajout de projet ;
8. **UX-07** — contextualiser résultats, rapports et logs ;
9. **UX-08** — reloger réglages, docs et outils ;
10. **UX-09** — finaliser l’expérience macOS et l’accessibilité ;
11. **UX-10** — nettoyer, documenter et clôturer.

La réussite de la refonte dépend moins d’un style spectaculaire que du respect constant de quatre règles :

1. état métier avant sortie technique ;
2. intention utilisateur avant commande backend ;
3. une action principale par contexte ;
4. détails avancés disponibles, mais jamais imposés.

