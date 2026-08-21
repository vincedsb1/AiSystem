# AI System — Spécifications fonctionnelles et techniques UX/UI V2

**Version :** 2.0  
**Date :** 20 août 2026  
**Statut :** Prête pour implémentation incrémentale  
**Nature :** Seconde passe UX/UI après clôture de UX-00 → UX-10  
**Application :** AI System — macOS SwiftUI  
**Dépôt :** `/Users/vincentdesbrosses/Documents/Misc/ai-system`

---

## 0. Objet du document

Ce document spécifie la seconde passe d’amélioration UX/UI de l’application macOS `AI System`, après l’implémentation réussie de la refonte structurelle UX-00 → UX-10.

La première refonte a résolu les problèmes d’architecture de l’information et de modèle d’état :

- trois destinations principales ;
- état métier global ;
- gestion contextualisée des opérations ;
- projets et skills structurés ;
- import, synchronisation et ajout de projet ;
- activité séparée des autres écrans ;
- réglages et outils secondaires relogés ;
- contrats JSON versionnés ;
- tests backend et Swift.

Cette deuxième passe ne doit pas rouvrir ces décisions. Elle vise à transformer une interface fonctionnellement saine mais encore austère en une application :

- plus claire ;
- plus chaleureuse ;
- plus contemporaine ;
- mieux hiérarchisée ;
- plus agréable à consulter quotidiennement ;
- toujours native macOS ;
- toujours simple.

La priorité est la **qualité perceptive au service de la compréhension**, pas l’ajout de fonctionnalités.

---

## 1. Sources et état de référence

### 1.1 Sources

1. Le présent document pour cette seconde passe UX/UI.
2. `docs/AI System UX UI Specs.md` ou le fichier de spécification réellement présent dans le dépôt pour la refonte précédente.
3. `docs/UX-10-CLOSURE.md` pour les écarts assumés et la checklist de recette.
4. Le code actuel et les contrats JSON réellement présents dans le dépôt.
5. Les captures post-refonte fournies le 20 août 2026.
6. Les Human Interface Guidelines d’Apple.

### 1.2 État fonctionnel déclaré

Le récapitulatif d’implémentation indique :

- UX-00 → UX-10 terminées ;
- 93 tests backend passants ;
- 92 tests Swift passants ;
- `make inventory` OK ;
- `make doctor` OK ;
- `make check` OK ;
- `make build-swift-app` OK ;
- app installée dans `~/Applications/AI System.app` ;
- sandbox désactivé conservé ;
- fallback AppleScript conservé ;
- activité session-only ;
- tests UI automatisés bloqués par l’autorisation macOS Automation.

Cette spécification considère donc le socle fonctionnel comme valide et ne demande aucun refactor backend général.

### 1.3 Références Apple

- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles)
- [Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars)
- [Split views](https://developer.apple.com/design/human-interface-guidelines/split-views)
- [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
- [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)
- [Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback)
- [Lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables)
- [Disclosure controls](https://developer.apple.com/design/human-interface-guidelines/disclosure-controls)
- [Progress indicators](https://developer.apple.com/design/human-interface-guidelines/progress-indicators)

---

## 2. Périmètre et non-objectifs

### 2.1 Inclus

- amélioration de la Vue d’ensemble ;
- amélioration de la lisibilité de Projets ;
- restructuration visuelle d’Activité ;
- harmonisation des toolbars ;
- amélioration des alignements, tailles, espacements et densités ;
- amélioration des couleurs sémantiques ;
- réduction des répétitions visuelles ;
- amélioration des libellés et formats de date/durée ;
- composants visuels partagés ;
- responsive desktop ;
- mode clair/sombre ;
- accessibilité ;
- tests et validation visuelle.

### 2.2 Non inclus

- nouvelle destination principale ;
- modification du modèle canonical/manifest/registry ;
- nouveau workflow backend ;
- remplacement d’ActivityStore session-only par un historique persistant ;
- refonte d’`CommandRunner` ;
- modification des routes import/sync/add-project ;
- nouveau framework UI ;
- design web ou dashboard SaaS ;
- personnalisation manuelle du thème ;
- illustrations décoratives ;
- animations complexes ;
- suppression du fallback AppleScript ;
- recréation du projet Xcode.

### 2.3 Règle de périmètre

Si une amélioration visuelle révèle un manque de données, le code doit :

1. réutiliser une donnée structurée déjà disponible ;
2. ou enrichir un modèle structuré de façon minimale ;
3. mais ne jamais parser `stdout` ou un log pour fabriquer un état métier.

---

## 3. Audit global post-refonte

### 3.1 Acquis à préserver

La nouvelle interface a réalisé les gains les plus importants :

- navigation réduite à Vue d’ensemble, Projets et Activité ;
- suppression de l’erreur globale affichée partout ;
- vraie liste de projets ;
- détail sélectionné ;
- statuts de skills compréhensibles ;
- filtres ;
- accès secondaire aux outils ;
- détails techniques isolés dans Activité ;
- usage cohérent des couleurs sémantiques ;
- structure native `NavigationSplitView`.

La seconde passe doit préserver cette sobriété structurelle.

### 3.2 Diagnostic visuel global

L’application paraît maintenant correcte et cohérente, mais encore proche d’un outil d’administration interne.

Les causes principales sont :

1. typographie globalement trop petite ;
2. hiérarchie verticale faible ;
3. trop d’éléments concentrés dans le coin supérieur gauche ;
4. grands espaces vides non intentionnels ;
5. répétition de coches vertes à plusieurs niveaux ;
6. surfaces et sections insuffisamment différenciées ;
7. actions dupliquées entre contenu, toolbar et menus ;
8. métadonnées trop compactes ;
9. formats de dates et durées non uniformes ou non localisés ;
10. détails techniques encore trop visibles dans Activité.

### 3.3 Direction cible

Le rendu cible doit évoquer une application macOS calme et soignée :

- une grande conclusion claire ;
- des surfaces légèrement teintées, jamais criardes ;
- une grille d’alignement stable ;
- plus d’air autour des groupes importants ;
- une densité plus forte dans les listes ;
- une densité plus faible dans les résumés ;
- une seule occurrence visuelle forte de chaque information ;
- des détails révélés à la demande.

### 3.4 Ce que « chaleureux » signifie ici

Le caractère chaleureux ne doit pas provenir d’illustrations ou de gradients décoratifs agressifs.

Il doit venir de :

- formulations humaines ;
- surfaces teintées avec parcimonie ;
- arrondis cohérents ;
- rythme vertical confortable ;
- couleurs de statut adoucies en arrière-plan ;
- feedback rassurant ;
- absence de bruit technique.

---

## 4. Fondations visuelles V2

### 4.1 Conteneur de contenu

Créer un conteneur partagé pour les pages à colonne unique :

- padding horizontal : 28 points à largeur normale ;
- padding vertical supérieur : 24 points ;
- padding inférieur : 32 points ;
- largeur maximale recommandée : 1040 points pour Vue d’ensemble ;
- alignement leading ;
- centrage horizontal du conteneur lorsque la fenêtre devient très large ;
- réduction du padding horizontal à 20 points lorsque l’espace est contraint.

Objectif : éviter qu’une ligne d’activité occupe près de toute la largeur de la fenêtre tandis que tout le contenu reste collé en haut à gauche.

### 4.2 Échelle d’espacement

| Token logique | Valeur | Usage |
|---|---:|---|
| `xxs` | 4 | icon/label, détails très liés |
| `xs` | 8 | éléments d’une même ligne |
| `sm` | 12 | sous-groupes et contrôles |
| `md` | 16 | padding de lignes/surfaces |
| `lg` | 24 | séparation de sections |
| `xl` | 32 | grandes ruptures |
| `xxl` | 40 | respiration héro/sections majeures |

Les valeurs peuvent être définies sous forme de constantes privées ou d’un petit namespace `AppSpacing`. Ne pas créer un package de design system.

### 4.3 Arrondis

| Élément | Rayon recommandé |
|---|---:|
| champ/liste compacte | système ou 8 |
| ligne interactive groupée | 10 |
| surface de section | 12 |
| héro principal | 16 |

Utiliser `ContainerRelativeShape` lorsque cela améliore l’adaptation au contexte.

### 4.4 Typographie

| Élément | Style cible |
|---|---|
| conclusion principale | 26–30 pt, semibold/bold selon rendu |
| titre de projet/d’activité | 20–22 pt, semibold |
| titre de section | 15–17 pt, semibold |
| nom dans une liste | 13–14 pt, medium/semibold |
| corps | style `body` système |
| métadonnée | `subheadline` ou `caption`, contraste contrôlé |
| valeur de métrique | 18–22 pt, semibold |
| technique | monospaced 11–12 pt |

Éviter les tailles fixes lorsque les styles sémantiques SwiftUI donnent un résultat équivalent. Les plages ci-dessus servent de cible visuelle.

### 4.5 Couleurs

Utiliser les couleurs système et sémantiques :

- accent macOS pour sélection et action principale ;
- vert pour sain/succès ;
- orange pour attention ;
- rouge pour erreur ;
- gris secondaire pour neutre/inconnu.

Pour les surfaces teintées :

- combiner une opacité faible de la couleur sémantique avec un matériau ou fond système ;
- vérifier clair et sombre ;
- ne pas appliquer de texte vert clair sur fond vert sans contrôle de contraste ;
- réserver les couleurs saturées aux symboles, petits indicateurs et actions.

### 4.6 Surfaces

Trois niveaux maximum :

1. fond de fenêtre ;
2. surface de section légèrement contrastée ;
3. contrôle ou sélection.

Ne pas imbriquer plusieurs cartes arrondies sans nécessité.

### 4.7 Symboles

- SF Symbols uniquement ;
- symbole principal 24–28 pt ;
- symbole de statut de liste 11–14 pt ;
- éviter trois coches vertes sur une même ligne ;
- icône seule uniquement avec tooltip et label d’accessibilité.

### 4.8 Formats localisés

Toutes les dates et durées visibles doivent utiliser les APIs de formatage :

- `20 août 2026 à 21:18` ;
- `il y a 4 min` ;
- `1,4 s` ;
- `3 min 57 s`.

Éviter :

- `20 Aug 2026` ;
- `1.4 s` en locale française ;
- `3 min, 57 secs` ;
- juxtaposition non expliquée de la durée et du temps relatif.

---

## 5. Toolbar et actions globales

### 5.1 Problème actuel

La Vue d’ensemble comporte potentiellement trois façons de rafraîchir :

- bouton Vérifier maintenant dans le contenu ;
- icône bouclier dans la toolbar ;
- menu Actualiser l’état.

Projets présente également une action Vérifier dans le contenu et une icône de rafraîchissement en toolbar.

Cette duplication nuit à la clarté.

### 5.2 Règle cible

Une action doit avoir un emplacement principal unique.

#### Vue d’ensemble

- état sain : action **Vérifier à nouveau** dans le héro, style secondaire ;
- état inconnu/attention/erreur : action principale dans le héro ;
- supprimer l’icône bouclier si elle déclenche la même action ;
- menu `…` : uniquement rapports et actions réellement secondaires.

#### Projets

- `+` reste dans la toolbar pour Ajouter un projet ;
- action Vérifier reste dans l’en-tête du projet avec un libellé explicite ;
- supprimer l’icône refresh de toolbar si elle duplique Vérifier ;
- menu secondaire devient une icône `ellipsis.circle` avec tooltip, pas un bouton textuel « Actions secondaires ».

#### Activité

- filtre placé dans l’en-tête de la liste d’activités, pas dans la zone du détail ;
- recherche et filtre appartiennent au même panneau ;
- le détail n’affiche que des actions liées à l’activité sélectionnée.

### 5.3 Menus

Les libellés doivent décrire l’objet :

- Actualiser la vue ;
- Ouvrir Inventory ;
- Ouvrir Doctor ;
- Ouvrir dans Finder ;
- Ouvrir dans Terminal ;
- Copier le chemin.

Éviter les menus qui reproduisent exactement un bouton visible voisin.

---

## 6. Vue d’ensemble V2

### 6.1 Diagnostic détaillé

La Vue d’ensemble actuelle est fonctionnellement correcte, mais :

- le bloc « Tout est à jour » manque de présence ;
- le contenu est trop proche du bord supérieur ;
- le titre et la description sont petits ;
- le bouton bleu domine alors qu’aucune action n’est requise ;
- les métriques Projets flottent sans surface ni structure ;
- l’activité récente est une très longue barre horizontale ;
- les informations temporelles sont ambiguës ;
- la majeure partie de la fenêtre est vide sans composition intentionnelle ;
- l’ensemble paraît froid malgré le statut positif.

### 6.2 Composition cible

Ordre vertical :

1. héro de santé ;
2. résumé des projets ;
3. actions requises si présentes ;
4. activité récente ;
5. aucun autre contenu si tout est sain.

Largeur : conteneur principal maximum 1040 points.

Espacements :

- 24 points avant le héro ;
- 24 à 32 points entre héro et résumé ;
- 24 points entre sections ;
- 12 points entre titre de section et contenu.

### 6.3 Health Hero

Créer un composant partagé `HealthHeroView` ou équivalent.

#### Structure

- surface arrondie de rayon 16 ;
- padding 24 points ;
- symbole de statut dans une surface circulaire douce ;
- titre 26–30 pt ;
- description 14–15 pt ;
- métadonnée de dernière observation ;
- action contextuelle ;
- layout horizontal à largeur normale, vertical si la largeur devient insuffisante.

#### État sain

Copie recommandée :

> **Tout est synchronisé**  
> 10 projets vérifiés et 146 skills gérés. Aucune action n’est requise.  
> Vérifié aujourd’hui à 21:18

Action : **Vérifier à nouveau**, style secondaire/bordered.

La surface peut recevoir une légère teinte verte. Le bouton ne doit pas être le point le plus saturé de la page lorsque tout va bien.

#### État attention

> **2 éléments demandent votre attention**  
> Suggst contient un nouveau skill et un export manque dans Pylaa.

Action principale accentuée : **Examiner les actions**.

Surface légèrement teintée orange.

#### État erreur

> **La vérification n’a pas pu être terminée**

Actions : **Réessayer** et Afficher l’activité.

Surface rouge très légère, sans grande zone rouge saturée.

#### État inconnu

> **Vérifiez votre environnement IA**  
> Analysez les projets et leurs skills pour connaître leur état.

Action principale : **Vérifier maintenant**.

#### État running

- conserver la surface ;
- `ProgressView` ;
- titre **Vérification en cours…** ;
- ancienne observation présentée comme précédente si elle reste visible ;
- aucun changement de hauteur brutal.

### 6.4 Résumé des projets

#### Objectif

Présenter une synthèse lisible sans créer une grille de dashboard lourde.

#### Structure recommandée

Une surface unique contenant quatre métriques alignées :

1. Projets : 10 ;
2. Sains : 10 ;
3. À examiner : 0 ;
4. En erreur : 0.

Chaque métrique contient :

- petit symbole ou point ;
- valeur 20 pt semibold ;
- libellé 12–13 pt ;
- couleur sémantique discrète.

Les quatre colonnes ont la même largeur. La surface utilise un padding 16–20 points.

À largeur réduite, basculer vers une grille 2 × 2.

#### Règles

- ne pas colorer toute la valeur rouge/orange si elle vaut zéro ;
- un zéro sans problème reste neutre ;
- le vert peut mettre en valeur la métrique Sains ;
- si une métrique devient non nulle, elle devient interactive et navigue vers le filtre correspondant.

### 6.5 Actions requises

Cette section n’apparaît que si nécessaire.

Chaque ligne :

- statut ;
- projet ;
- résumé ;
- action ;
- chevron si toute la ligne est cliquable.

La section doit être placée avant Activité récente.

### 6.6 Activité récente

#### Problème actuel

La ligne occupe toute la largeur et contient à droite des données temporelles difficiles à interpréter ainsi qu’un bouton Voir peu expressif.

#### Structure cible

Surface de section avec deux ou trois lignes maximum.

Chaque `RecentActivityRow` :

- symbole de statut unique ;
- titre ;
- résumé sur une ligne ;
- métadonnée : `il y a 4 min · 1,4 s` ;
- chevron ;
- toute la ligne est cliquable ;
- supprimer le bouton Voir.

Les lignes sont séparées par des `Divider` internes, pas chacune par une grande carte.

### 6.7 Critères d’acceptation — Vue d’ensemble

- la conclusion est l’élément visuel dominant ;
- le titre principal est lisible à distance normale ;
- le contenu est aligné dans un conteneur cohérent ;
- aucun bouton de vérification n’est dupliqué ;
- le statut sain paraît rassurant mais pas criard ;
- la page est équilibrée à 1335 × 968 ;
- la page reste lisible à la taille minimale ;
- les métriques se réorganisent à largeur réduite ;
- les dates et durées sont localisées ;
- l’activité récente est entièrement cliquable ;
- aucun log ou code technique n’est visible.

---

## 7. Projets V2

### 7.1 Diagnostic détaillé

La structure en trois zones est bonne. Les problèmes restants sont :

- colonne des projets trop large au regard de son contenu ;
- répétition de « Sain » et d’une coche verte sur chaque projet ;
- en-tête de projet un peu compact ;
- bouton Vérifier et refresh toolbar potentiellement redondants ;
- libellé « Actions secondaires » trop lourd ;
- résumé composé de six métriques mal équilibrées ;
- « Conflits » seul sur une seconde ligne ;
- filtres et recherche très compacts ;
- absence d’en-têtes de colonnes dans la liste des skills ;
- nombreuses coches vertes répétées dans chaque ligne ;
- exception représentée par un cercle vide ambigu ;
- état vide générique « Aucun résultat » au lieu de refléter le filtre.

### 7.2 Colonne de projets

#### Dimensions

- largeur idéale : 250–280 points ;
- largeur minimale : environ 220 points ;
- largeur maximale : environ 320 points ;
- conserver le redimensionnement natif.

#### ProjectListRow

- hauteur cible : 46–52 points ;
- padding horizontal : 10–12 points ;
- symbole de statut : 11–13 points ;
- nom : 13–14 pt medium ;
- sous-titre : 11–12 pt ;
- sélection native ou surface système, sans grand bloc gris personnalisé excessif.

#### Copie

Projet sain :

- nom ;
- sous-titre **À jour** ou aucune seconde ligne si la lisibilité reste suffisante.

Projet avec problème :

- nom ;
- sous-titre **2 éléments à examiner**.

Projet non vérifié :

- nom ;
- sous-titre **Non vérifié**.

Règle : ne pas afficher dix fois « Sain » si l’icône et le contexte suffisent. Le sous-titre doit devenir utile, pas répétitif.

### 7.3 En-tête de projet

#### Layout

- padding supérieur : 24–28 points ;
- padding horizontal : 24 points ;
- symbole 24–26 pt ;
- titre 22 pt semibold ;
- résumé 13–14 pt ;
- dernière analyse 11–12 pt ;
- actions séparées du texte par 12–16 points.

#### Copie recommandée pour Suggst

> **Suggst**  
> 20 skills synchronisés · 6 exceptions attendues  
> Vérifié aujourd’hui à 21:18

Cette formulation est plus précise que « 20 skills gérés sur 26 — aucune action requise ».

#### Actions

- bouton principal/contextuel : Vérifier ou Synchroniser ;
- bouton menu : symbole `ellipsis.circle` ;
- tooltip : **Plus d’actions pour Suggst** ;
- retirer le texte « Actions secondaires ».

### 7.4 Résumé du projet

Remplacer les six métriques actuelles par quatre informations principales :

1. Total : 26 ;
2. Synchronisés : 20 ;
3. Exceptions : 6 ;
4. À examiner : 0.

Informations secondaires sous forme d’une phrase ou d’un sous-groupe :

> Composition : 13 partagés · 7 spécifiques

Les conflits alimentent « À examiner » ou une alerte dédiée lorsqu’ils sont non nuls. Il n’est pas nécessaire d’afficher en permanence une métrique Conflits à zéro isolée sur une seconde ligne.

#### Surface

- une surface compacte ;
- quatre colonnes égales ;
- padding 16 points ;
- valeur 18–20 pt ;
- libellé 11–12 pt ;
- grille 2 × 2 si largeur réduite.

### 7.5 Barre de filtres

#### Libellés

- Tous 26 ;
- À examiner 0 ;
- Synchronisés 20 ;
- Exceptions 6.

Les parenthèses peuvent être conservées si le composant natif Picker donne un meilleur rendu, mais les chiffres doivent rester faciles à scanner.

#### Layout

- Picker segmenté occupant l’espace disponible ;
- recherche d’une largeur idéale 220–260 points ;
- à largeur réduite, recherche sur une ligne séparée ;
- 12 points entre filtre et recherche ;
- résultat affiché sous le titre Skills seulement si utile.

### 7.6 Liste/table des skills

#### En-tête obligatoire

Ajouter une ligne d’en-tête alignée avec les données :

| Colonne | Libellé |
|---|---|
| principale | Skill |
| scope | Type |
| Claude | Claude |
| Codex | Codex |
| état/action si nécessaire | État |

Si l’implémentation utilise `Table`, employer les colonnes natives. Si elle conserve une `LazyVStack`, créer un composant `SkillTableHeader` partageant exactement les largeurs des cellules.

#### Colonnes recommandées

- Skill : flexible, minimum 260 points ;
- Type : 100–120 points ;
- Claude : 64–76 points ;
- Codex : 64–76 points ;
- Action : largeur selon présence, masquée si aucune action.

#### Réduction des coches

Une ligne synchronisée ne doit pas afficher trois coches vertes de même poids.

Approche cible :

- statut général porté par le texte secondaire **Synchronisé**, éventuellement accompagné d’un petit symbole ;
- colonnes Claude/Codex utilisent une coche plus petite et plus discrète ;
- éviter une grande coche supplémentaire au début si le statut texte suffit.

#### Exceptions

Une exception attendue doit afficher :

- symbole neutre `info.circle` ou `checkmark.circle` secondaire ;
- sous-titre **Claude uniquement — attendu** ;
- badge ou texte **Exception attendue** si une colonne État existe ;
- Claude présent ;
- Codex non attendu, représenté par un tiret ou texte **Non requis**, pas par un cercle vide ressemblant à un chargement.

#### Actions requises

Les lignes à examiner peuvent recevoir :

- petite teinte de fond sémantique ;
- statut orange/rouge ;
- bouton Importer/Synchroniser clairement aligné à droite.

Les lignes saines ne doivent pas être saturées de vert.

### 7.7 États vides contextualisés

Adapter l’état au filtre :

#### À examiner = 0

> **Aucun skill à examiner**  
> Ce projet ne demande aucune action.

Action : **Afficher tous les skills**.

#### Recherche sans résultat

> **Aucun skill ne correspond à “…”**  
> Modifiez votre recherche ou effacez-la.

Action : **Effacer la recherche**.

#### Synchronisés = 0

> **Aucun skill synchronisé**

L’action dépend de l’état backend.

Ne pas utiliser systématiquement « Effacer le filtre », formulation technique.

### 7.8 Scrolling

- l’en-tête du projet et le résumé peuvent rester dans le scroll principal ;
- la barre de filtres peut rester visible si cela est naturel et fiable ;
- éviter deux scrollbars imbriquées ;
- le scroll doit conserver la sélection du projet ;
- le changement de filtre revient en haut de la liste si nécessaire.

### 7.9 Critères d’acceptation — Projets

- la colonne projet n’écrase pas le détail ;
- la répétition du vert est fortement réduite ;
- les métriques tiennent sur une grille équilibrée ;
- aucun élément n’est isolé sur une ligne sans raison ;
- les colonnes de skills ont des en-têtes ;
- Type, Claude et Codex sont immédiatement identifiables ;
- une exception n’a pas l’apparence d’une erreur ou d’un chargement ;
- les états vides reflètent le filtre actif ;
- la recherche reste utilisable à largeur réduite ;
- Vérifier n’est pas dupliqué dans la toolbar ;
- les menus à icône ont tooltip et VoiceOver label.

---

## 8. Activité V2

### 8.1 Diagnostic détaillé

L’écran Activité dispose de la bonne architecture maître-détail, mais manque encore de clarté :

- le filtre Toutes (2) apparaît au-dessus du détail plutôt qu’au-dessus de la liste ;
- recherche et filtre sont séparés alors qu’ils contrôlent la même collection ;
- deux activités identiques sont difficiles à distinguer rapidement ;
- le détail commence correctement mais devient immédiatement technique ;
- Détails techniques est ouvert par défaut dans la capture ;
- les données métier de résultat sont insuffisamment structurées ;
- la date `20 Aug 2026` et la durée `1.4 s` ne sont pas localisées ;
- les boutons de rapports manquent de hiérarchie ;
- stdout occupe la partie la plus visible du détail ;
- le contenu est collé en haut avec beaucoup d’espace vide en dessous.

### 8.2 Architecture cible

Conserver trois zones :

1. sidebar principale ;
2. liste des activités ;
3. détail sélectionné.

Rééquilibrer :

- liste idéale : 330–380 points ;
- détail : reste de l’espace ;
- contenu du détail limité à environ 760–840 points et centré/aligné leading dans sa zone ;
- padding du détail : 24–28 points.

### 8.3 En-tête de la liste

Ordre :

1. titre Activité ;
2. recherche ;
3. filtre ou menu de filtre ;
4. liste groupée.

Le filtre Toutes/Échecs/Vérifications/Synchronisations doit être placé dans le panneau de liste.

Options :

- Picker/menu compact à droite de la recherche ;
- ou ligne séparée recherche + filtre si la largeur l’exige.

### 8.4 Groupement temporel

Grouper visuellement les activités :

- Aujourd’hui ;
- Hier ;
- Cette semaine ;
- Plus anciennes.

Pour l’historique session-only, afficher au minimum Aujourd’hui si plusieurs activités existent. Ne pas forcer un groupement s’il n’y a qu’une activité.

### 8.5 ActivityListRow

Structure :

- symbole de statut 12–14 pt ;
- titre 13–14 pt semibold ;
- cible/projet en secondaire ;
- résumé métier sur une ligne ;
- heure à droite ;
- durée en secondaire à droite ;
- hauteur 58–70 points selon contenu ;
- sélection native ou fond système.

Exemple :

> **Vérification du système**                  21:18  
> 10 projets vérifiés · aucune action          1,4 s

Ne pas répéter « Système » sur une ligne séparée si le résumé et le titre suffisent ; le scope peut rester utile lorsque plusieurs types d’activités coexistent.

### 8.6 En-tête du détail

Créer `ActivityDetailHeader` :

- symbole de statut dans cercle doux ;
- titre 20–22 pt ;
- badge ou texte de statut **Réussie** ;
- résumé 14 pt ;
- métadonnées en une ligne : **Aujourd’hui à 21:18 · 1,4 s · Système** ;
- espacement inférieur 24 points.

Éviter le tableau compact Cible/Démarré/Durée lorsque ces trois informations tiennent dans une ligne naturelle.

### 8.7 Section Résultat

Ajouter une section sémantique avant Rapports :

> **Résultat**  
> 10 projets vérifiés. Aucun élément ne demande votre attention.

Si des compteurs structurés sont disponibles :

- 10 projets ;
- 146 skills ;
- 0 action ;
- 0 erreur.

Ne pas obtenir ces valeurs en parsant stdout.

Si ActivityStore ne possède que `summary`, afficher simplement ce résumé correctement mis en forme. L’enrichissement du modèle est optionnel tant que la hiérarchie est respectée.

### 8.8 Rapports et fichiers

Remplacer, si possible, les trois petits boutons gris par des lignes de ressource :

- symbole de document ;
- nom Inventory/Doctor/Journal ;
- sous-titre bref ;
- action Ouvrir ou chevron ;
- toute la ligne cliquable.

Alternative minimale acceptable : conserver les boutons, mais :

- ajouter des SF Symbols ;
- uniformiser les libellés ;
- augmenter l’espacement ;
- rendre la section visuellement distincte.

### 8.9 Détails techniques

#### Règle absolue

La section est **repliée par défaut** pour chaque nouvelle sélection.

Le disclosure affiche dans son libellé :

> Détails techniques

Lorsqu’il est fermé, aucun chemin, code de sortie ou stdout n’est visible.

#### Contenu ouvert

- action backend ;
- code de sortie ;
- chemin du log ;
- stdout ;
- stderr si présent ;
- actions Copier et Ouvrir le log.

Présentation :

- métadonnées techniques dans une grille label/valeur ;
- panneau monospacé avec padding 14–16 points ;
- fond contrasté mais non dominant ;
- sélection de texte ;
- hauteur maximale raisonnable avec scroll interne seulement si nécessaire ;
- chemins longs copiables et tronqués visuellement si besoin.

#### Réinitialisation

Lorsqu’une autre activité est sélectionnée, les détails techniques reviennent à l’état fermé.

### 8.10 État sans sélection

> **Sélectionnez une activité**  
> Consultez son résultat, les rapports générés et les détails techniques.

Utiliser un symbole neutre et aucun bouton primaire.

### 8.11 État sans activité

Dans la liste :

> **Aucune activité pour cette session**  
> Les vérifications et synchronisations apparaîtront ici.

Action secondaire éventuelle : **Vérifier maintenant** si l’intégration de navigation est simple.

### 8.12 Critères d’acceptation — Activité

- recherche et filtre sont dans le panneau de liste ;
- le détail commence par un résultat humain ;
- la date et la durée sont localisées ;
- les détails techniques sont fermés par défaut ;
- le changement de sélection referme les détails ;
- stdout n’est jamais visible au premier regard ;
- les ressources sont identifiables par symbole et libellé ;
- les activités identiques restent distinguables par heure et résumé ;
- le contenu du détail ne s’étale pas inutilement sur toute la largeur ;
- le mode sans sélection et le mode sans activité sont traités.

---

## 9. Composants SwiftUI à créer ou faire évoluer

Les noms exacts doivent être adaptés à l’arborescence réelle après inspection.

### 9.1 Composants partagés

#### `AdaptiveContentContainer`

Responsabilités :

- largeur maximale ;
- padding adaptatif ;
- alignement ;
- comportement petites/grandes fenêtres.

#### `SemanticSurface`

Responsabilités :

- surface neutre/success/attention/error ;
- fond et bordure système ;
- rayon cohérent ;
- pas de logique métier.

Une abstraction n’est justifiée que si plusieurs écrans utilisent réellement les mêmes règles.

#### `MetricItemView`

- valeur ;
- libellé ;
- symbole/couleur optionnels ;
- accessibilité combinée.

#### `SectionSurface`

- titre optionnel ;
- contenu ;
- padding cohérent ;
- séparateurs internes.

### 9.2 Vue d’ensemble

- `HealthHeroView` ;
- `ProjectHealthSummaryView` ;
- `RequiredActionRow` ;
- `RecentActivityRow`.

### 9.3 Projets

- `ProjectListRow` ;
- `ProjectHeaderView` ;
- `ProjectSummaryView` ;
- `SkillFilterBar` ;
- `SkillTableHeader` si `Table` non utilisée ;
- `ProjectSkillRow` ajusté ;
- `FilteredSkillsEmptyState`.

### 9.4 Activité

- `ActivityListHeader` ;
- `ActivityListRow` ;
- `ActivityDetailHeader` ;
- `ActivityResultSection` ;
- `ActivityResourceRow` ;
- `TechnicalDetailsDisclosure`.

### 9.5 Règle d’architecture

Les composants visuels reçoivent des données déjà interprétées. Ils ne doivent pas :

- scanner des skills ;
- déterminer un statut ;
- parser des logs ;
- déclencher directement des scripts sans passer par l’orchestration existante.

---

## 10. Modèles et view models

### 10.1 Changements minimaux

La seconde passe doit privilégier des propriétés de présentation calculées à partir de modèles structurés existants :

- titre localisé ;
- résumé ;
- date formatée ;
- durée formatée ;
- symbole/couleur sémantiques ;
- métriques déjà présentes.

### 10.2 Formateurs partagés

Créer si nécessaire :

- `RelativeDateTimeFormatter` ou `Date.FormatStyle` partagé ;
- `Duration.FormatStyle` partagé ;
- helpers de copies sémantiques.

Éviter de concaténer manuellement des chaînes temporelles.

### 10.3 ActivityStore

Changements autorisés :

- exposer un groupement par jour ;
- exposer une copie localisée ;
- mémoriser la sélection ;
- réinitialiser l’état de disclosure à chaque sélection au niveau de la vue.

Changements non requis :

- persistance entre lancements ;
- migration de stockage ;
- nouveaux types d’opération backend.

### 10.4 OverviewViewModel

Changements autorisés :

- composition des métriques ;
- copie par état ;
- navigation des métriques non nulles ;
- formatage de dernière observation.

Ne pas modifier le calcul backend de santé.

### 10.5 ProjectsViewModel

Changements autorisés :

- copies de résumé ;
- regroupement des métriques ;
- filtre contextualisé ;
- état vide contextualisé ;
- largeur/selection purement UI.

Ne pas modifier les règles `importable`, `allowedActions`, exceptions ou conflits.

---

## 11. Responsive desktop

### 11.1 Largeur de référence

Les captures de référence sont proches de 1335 × 968. Cette taille doit produire la composition la plus soignée.

### 11.2 Taille minimale

Conserver la taille minimale fonctionnelle existante ou documentée. À cette taille :

- aucune action principale tronquée ;
- aucun chevauchement ;
- les métriques passent en grille 2 × 2 ;
- recherche Projets peut passer sous les segments ;
- métadonnées Activité peuvent passer sur deux lignes ;
- les toolbars restent utilisables.

### 11.3 Très grande largeur

- Vue d’ensemble : max-width ;
- détail Activité : max-width ;
- Projets : le tableau peut s’étendre mais les colonnes Claude/Codex restent compactes ;
- éviter les longues lignes de texte de plus de 80–100 caractères visuels.

### 11.4 Hauteur réduite

- sections importantes visibles avant scroll lorsque possible ;
- pas de grandes marges fixes verticales ;
- listes scrollables ;
- héro ne doit pas dépasser environ 220 points dans son état standard.

---

## 12. Accessibilité

### 12.1 Couleur

- aucun état porté uniquement par le vert/orange/rouge ;
- métriques zéro lisibles sans couleur ;
- exceptions explicitement nommées ;
- sélection distinguable indépendamment de la couleur de statut.

### 12.2 VoiceOver

Exemples de labels combinés :

- « Suggst, à jour, 20 skills synchronisés, 6 exceptions attendues » ;
- « Claude, présent » ;
- « Codex, non requis » ;
- « Vérification du système, réussie, aujourd’hui à 21 heures 18, durée 1 seconde 4 ».

### 12.3 Icônes seules

Le menu ellipsis, le bouton Ajouter et toute action d’icône seule doivent posséder :

- `accessibilityLabel` ;
- help/tooltip ;
- zone cliquable suffisante.

### 12.4 Contraste

Vérifier :

- texte secondaire dans les surfaces teintées ;
- texte des métriques ;
- sélection de projet en mode sombre ;
- placeholder de recherche ;
- séparateurs de table.

### 12.5 Reduce Motion

Les transitions de héro, filtres et états vides doivent être désactivées ou simplifiées avec Reduce Motion.

---

## 13. Tests

### 13.1 Tests unitaires Swift

Ajouter ou adapter :

- copie du héro pour healthy/attention/error/unknown/running ;
- format français de date ;
- format français de durée ;
- métriques Overview ;
- résumé projet `20 synchronisés · 6 exceptions attendues` ;
- état vide selon filtre ;
- statut Codex non requis pour exception ;
- groupement d’activités ;
- filtre Activité ;
- détails techniques fermés par défaut si testable ;
- réinitialisation du disclosure à la sélection ;
- aucune action dupliquée dans les modèles de toolbar si garde existante.

### 13.2 Tests UI automatisés

Si l’autorisation Automation est disponible :

1. Vue d’ensemble saine ;
2. Vue d’ensemble attention ;
3. navigation métrique → Projets ;
4. filtres Projets ;
5. recherche Projets ;
6. état vide À examiner ;
7. Activité filtre/recherche ;
8. ouverture/fermeture détails techniques ;
9. sélection d’une autre activité refermant les détails ;
10. navigation clavier.

### 13.3 Recette manuelle obligatoire

Même si les tests UI deviennent exécutables, réaliser une recette visuelle de l’app installée.

#### Vue d’ensemble

- healthy ;
- unknown ;
- running ;
- attention via fixture/état réel sûr ;
- error via double/mock si possible ;
- 0 et plusieurs activités.

#### Projets

- projet sain ;
- filtre Tous ;
- filtre À examiner vide ;
- Synchronisés ;
- Exceptions ;
- recherche sans résultat ;
- nom long ;
- largeur minimale.

#### Activité

- aucune activité ;
- une activité ;
- plusieurs activités ;
- détails fermés ;
- détails ouverts ;
- rapport/log absent ;
- date/durée françaises.

#### Apparence

- clair ;
- sombre ;
- accent bleu et autre accent système ;
- contraste accru ;
- réduction transparence ;
- Reduce Motion ;
- écran Retina à échelle courante.

### 13.4 Snapshots de référence

À chaque étape visuelle, produire des captures de l’app Release installée à :

- 1335 × 968 ou taille équivalente de référence ;
- taille minimale ;
- mode clair ;
- mode sombre.

Les captures doivent être comparées aux critères de cette spécification, pas seulement à l’absence de crash.

---

## 14. Plan d’implémentation UX2

Cette seconde passe comporte sept étapes. Chaque étape doit rester compilable et validée avant la suivante.

### UX2-00 — Baseline visuelle et mapping du code

#### Objectif

Associer les éléments visibles aux fichiers Swift réels et figer une baseline post-UX-10.

#### Travaux

1. Inspecter `git status --short`.
2. Lire `docs/UX-10-CLOSURE.md`.
3. Identifier les vues/composants/ViewModels de :
   - Overview ;
   - Projects ;
   - Activity ;
   - toolbar ;
   - composants partagés.
4. Vérifier les tests existants.
5. Construire l’app Release.
6. Reproduire les captures actuelles.
7. Noter tailles de colonnes, paddings et comportements réels.
8. Vérifier la localisation actuelle des dates/durées.

#### Livrable

`docs/UX2-00-VISUAL-BASELINE.md` ou section équivalente.

#### Critères d’acceptation

- fichiers ciblés connus ;
- aucune modification fonctionnelle ;
- baseline visuelle archivée ;
- tests/build/check connus ;
- worktree préservé.

---

### UX2-01 — Fondations visuelles et formatage

#### Objectif

Créer les règles partagées avant de redessiner les écrans.

#### Travaux

1. Introduire l’échelle d’espacement légère.
2. Créer `AdaptiveContentContainer`.
3. Créer/adapter les surfaces sémantiques.
4. Créer `MetricItemView` si utile.
5. Uniformiser les formats de date et durée.
6. Définir les règles de rayon/padding.
7. Vérifier light/dark/contrast.
8. Ne pas modifier les workflows.

#### Tests

- formatage français ;
- composants dans previews/fixtures si disponibles ;
- contrôle des symboles et labels ;
- build.

#### Critères d’acceptation

- aucune chaîne temporelle anglaise visible ;
- espacements réutilisables sans abstraction excessive ;
- surfaces cohérentes ;
- pas de régression fonctionnelle ;
- `make check` vert.

---

### UX2-02 — Vue d’ensemble premium et chaleureuse

#### Objectif

Faire de la Vue d’ensemble l’écran le plus clair et le plus soigné de l’application.

#### Travaux

1. Créer le Health Hero.
2. Implémenter ses cinq états.
3. Supprimer les actions de vérification dupliquées.
4. Refaire le résumé Projets en surface 4 métriques.
5. Ajouter la section Actions requises conditionnelle.
6. Refaire Activité récente en lignes cliquables.
7. Appliquer max-width et padding.
8. Localiser les dates/durées.
9. Adapter la grille à largeur réduite.
10. Ajouter les labels d’accessibilité.

#### Tests

- tous les états ;
- navigation ;
- métriques ;
- layouts largeur normale/minimale ;
- light/dark ;
- Reduce Motion.

#### Critères d’acceptation

- la conclusion domine visuellement ;
- écran équilibré et chaleureux ;
- aucun grand vide causé par une ligne étirée ;
- une seule action de vérification principale ;
- activité récente claire ;
- capture Release validée.

---

### UX2-03 — Lisibilité de Projets

#### Objectif

Réduire le bruit visuel et rendre la liste des skills auto-explicative.

#### Travaux

1. Ajuster la largeur de la colonne projets.
2. Refaire `ProjectListRow`.
3. Refaire l’en-tête projet et sa copie.
4. Remplacer Actions secondaires par un menu icône accessible.
5. Supprimer le refresh toolbar dupliqué.
6. Recomposer le résumé en quatre métriques.
7. Ajouter la composition partagé/spécifique en secondaire.
8. Adapter filtre + recherche.
9. Ajouter les en-têtes de colonnes.
10. Réduire les coches vertes.
11. Clarifier les exceptions avec Non requis.
12. Contextualiser les états vides.
13. Vérifier scroll et petite largeur.

#### Tests

- filtres ;
- copies ;
- états vides ;
- exception ;
- skill synchronisé ;
- action requise ;
- en-têtes alignés ;
- accessibilité.

#### Critères d’acceptation

- une ligne skill se comprend sans deviner les colonnes ;
- vert utilisé avec parcimonie ;
- résumé équilibré ;
- exceptions non ambiguës ;
- recherche et filtres adaptatifs ;
- capture Release validée.

---

### UX2-04 — Clarté d’Activité

#### Objectif

Faire apparaître le résultat avant les preuves techniques.

#### Travaux

1. Déplacer le filtre dans le panneau de liste.
2. Refaire l’en-tête recherche/filtre.
3. Grouper les activités par période si pertinent.
4. Refaire `ActivityListRow`.
5. Créer `ActivityDetailHeader`.
6. Ajouter la section Résultat.
7. Refaire Rapports et fichiers.
8. Fermer Détails techniques par défaut.
9. Réinitialiser le disclosure à chaque sélection.
10. Améliorer le panneau monospacé.
11. Ajouter états sans sélection/sans activité.
12. Appliquer max-width et padding.
13. Localiser date et durée.

#### Tests

- sélection ;
- filtre/recherche ;
- disclosure ;
- changement sélection ;
- ressources ;
- états vides ;
- dates/durées.

#### Critères d’acceptation

- stdout invisible par défaut ;
- résultat humain au premier regard ;
- filtre situé avec la liste ;
- détail équilibré ;
- disclosure réinitialisé ;
- capture Release validée.

---

### UX2-05 — Harmonisation globale et accessibilité

#### Objectif

Uniformiser les trois écrans et finaliser le comportement macOS.

#### Travaux

1. Auditer toolbars et menus.
2. Supprimer toutes les duplications d’actions restantes.
3. Harmoniser tooltips.
4. Harmoniser labels VoiceOver.
5. Vérifier focus clavier.
6. Vérifier clair/sombre/accent/contraste.
7. Vérifier Reduce Motion/Transparency.
8. Vérifier textes longs.
9. Vérifier taille minimale.
10. Ajuster animations sobres.

#### Critères d’acceptation

- actions placées de façon prévisible ;
- icônes seules accessibles ;
- aucun statut uniquement coloré ;
- interface cohérente entre les écrans ;
- aucune régression des raccourcis ;
- tests verts.

---

### UX2-06 — Recette, documentation et clôture

#### Objectif

Valider l’app installée et documenter la seconde passe.

#### Travaux

1. Exécuter tests backend.
2. Exécuter tests Swift.
3. Tenter les tests UI avec autorisation Automation.
4. Réaliser la recette manuelle complète.
5. Produire les captures de référence.
6. Exécuter :
   - `make inventory` ;
   - `make doctor` ;
   - `make check` ;
   - `make build-swift-app`.
7. Tester `~/Applications/AI System.app`.
8. Mettre à jour README/OPERATIONS/docs UX.
9. Documenter les écarts assumés.
10. Vérifier le worktree.

#### Critères d’acceptation

- toutes les captures cibles validées ;
- tests verts ou blocage UI environnemental documenté ;
- aucune régression métier ;
- app Release installée validée ;
- fallback AppleScript préservé ;
- aucun commit automatique si la session d’implémentation ne l’autorise pas explicitement.

---

## 15. Ordre de priorité

| Priorité | Travail | Impact |
|---|---|---|
| P0 | Health Hero + layout Overview | qualité perçue immédiate |
| P0 | Détails techniques Activité fermés | clarté fondamentale |
| P0 | En-têtes de colonnes Skills | compréhension immédiate |
| P1 | Résumé Projets simplifié | lisibilité |
| P1 | ActivityDetailHeader + Result | compréhension du résultat |
| P1 | dates/durées localisées | finition et cohérence |
| P1 | suppression actions dupliquées | simplicité |
| P2 | groupement temporel Activité | navigation |
| P2 | surfaces/metrics partagées | cohérence |
| P2 | responsive et polish avancé | robustesse visuelle |

---

## 16. Risques et mitigations

| Risque | Mitigation |
|---|---|
| transformer l’app en dashboard web | une surface par section, composants macOS, pas de mosaïque décorative |
| surutiliser le vert | un signal principal par ligne, statuts secondaires neutres |
| abstraire trop tôt | composants partagés seulement après deux usages réels |
| casser les layouts étroits | grilles adaptatives et recette taille minimale |
| dupliquer les actions | audit toolbar/contenu/menu par écran |
| introduire du parsing stdout | données structurées ou résumé existant uniquement |
| changer le métier pendant le polish | périmètre strict, aucun changement de statut backend |
| détails techniques toujours ouverts | état local false et reset à la sélection |
| dates incohérentes | formateurs centralisés et tests |
| worktree chargé | inspection et patchs ciblés par étape |

---

## 17. Checklist par étape

### Avant

- [ ] Inspecter `git status --short`.
- [ ] Lire les fichiers réels ciblés.
- [ ] Identifier les modifications préexistantes.
- [ ] Construire la baseline.
- [ ] Définir les états visuels à tester.

### Pendant

- [ ] Ne pas modifier les règles métier.
- [ ] Ne pas parser stdout/YAML.
- [ ] Utiliser composants et couleurs système.
- [ ] Vérifier largeur normale et minimale.
- [ ] Vérifier clair et sombre.
- [ ] Ajouter tests de copie/formatage/comportement.

### Après

- [ ] Tests ciblés verts.
- [ ] Build vert.
- [ ] Capture Release produite.
- [ ] VoiceOver/keyboard contrôlés.
- [ ] `make inventory` vert.
- [ ] `make doctor` vert.
- [ ] `make check` vert.
- [ ] `git diff` relu.
- [ ] Aucun fichier préexistant écrasé.

---

## 18. Definition of Done V2

### Vue d’ensemble

- [ ] Héro de santé présent.
- [ ] Hiérarchie typographique forte.
- [ ] Surface chaleureuse et sémantique.
- [ ] Une seule action de vérification.
- [ ] Résumé projets équilibré.
- [ ] Actions requises conditionnelles.
- [ ] Activité récente en lignes cliquables.
- [ ] Max-width et padding adaptatifs.

### Projets

- [ ] Colonne projet équilibrée.
- [ ] En-tête projet lisible.
- [ ] Résumé réduit à quatre métriques principales.
- [ ] Filtres/recherche adaptatifs.
- [ ] En-têtes de colonnes présents.
- [ ] Répétition du vert réduite.
- [ ] Exceptions explicites et non ambiguës.
- [ ] États vides contextualisés.

### Activité

- [ ] Recherche et filtre regroupés.
- [ ] Liste lisible et localisée.
- [ ] En-tête de détail clair.
- [ ] Résultat métier avant rapports.
- [ ] Détails techniques fermés par défaut.
- [ ] Disclosure réinitialisé à la sélection.
- [ ] Ressources compréhensibles.
- [ ] États sans sélection/activité présents.

### Global

- [ ] Formats français cohérents.
- [ ] Toolbars sans doublons.
- [ ] Mode clair/sombre validé.
- [ ] Taille minimale validée.
- [ ] VoiceOver et clavier validés.
- [ ] Reduce Motion/Transparency respectés.
- [ ] Tests backend et Swift verts.
- [ ] `make inventory`, `make doctor`, `make check` verts.
- [ ] `make build-swift-app` vert.
- [ ] App Release installée testée.
- [ ] Aucun changement métier involontaire.

---

## 19. Résumé opérationnel

La seconde passe doit être exécutée dans cet ordre :

1. **UX2-00** — figer la baseline visuelle ;
2. **UX2-01** — harmoniser fondations et formatage ;
3. **UX2-02** — rendre la Vue d’ensemble forte, claire et chaleureuse ;
4. **UX2-03** — améliorer la lisibilité de Projets ;
5. **UX2-04** — restructurer Activité autour du résultat ;
6. **UX2-05** — harmoniser toolbars et accessibilité ;
7. **UX2-06** — valider, documenter et clôturer.

La règle de design centrale est :

> Une conclusion forte, une structure calme, un seul signal visuel par information, et les détails techniques uniquement à la demande.

