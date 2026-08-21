# AI System — Audit UX/UI et spécifications « Memorable Experience »

**Version :** UX3.0  
**Date :** 20 août 2026  
**Statut :** Prête pour implémentation incrémentale  
**Périmètre :** Trois transformations majeures uniquement  
**Application :** AI System — macOS SwiftUI  
**Dépôt :** `/Users/vincentdesbrosses/Documents/Misc/ai-system`

---

## 0. Objet du document

Ce document réalise un troisième audit de l’application `AI System` après la clôture des étapes UX-00 → UX-10 puis UX2-00 → UX2-06.

L’application est désormais :

- claire ;
- cohérente ;
- fonctionnelle ;
- native macOS ;
- correctement structurée ;
- accessible aux détails techniques sans les imposer ;
- validée par les tests backend et Swift.

L’objectif de cette nouvelle phase n’est donc plus de corriger l’interface ou d’ajouter du polish général. Il est de sélectionner **exactement trois transformations** capables de faire passer l’application d’un bon outil professionnel à une expérience reconnaissable, rapide et mémorable.

Les trois transformations retenues sont :

1. **System Pulse** — une représentation signature et fonctionnelle du système ;
2. **Quick Command** — une palette globale d’actions et de navigation ;
3. **Operation Experience** — une chorégraphie cohérente des opérations et des reçus sémantiques.

Tout travail ne servant pas directement l’un de ces trois axes est hors périmètre.

---

## 1. Sources et baseline

### 1.1 Sources

1. Les captures finales fournies le 20 août 2026.
2. `UX2-06-CLOSURE.md`.
3. Le code réellement présent dans le dépôt au début de l’implémentation.
4. Les contrats JSON et tests existants.
5. Les Human Interface Guidelines d’Apple.

### 1.2 Baseline déclarée

La clôture UX2 indique :

- 93 tests backend passants ;
- 99 lignes/tests Swift validés ;
- Inventory, Doctor et Check verts ;
- build Release installé ;
- détails techniques fermés par défaut ;
- navigation à trois destinations conservée ;
- aucune modification backend lors de la passe UX2 ;
- tests UI bloqués par l’autorisation macOS Automation ;
- mode sombre validé ;
- mode clair non validé visuellement de façon fiable ;
- activité limitée à la session active.

### 1.3 Contraintes à préserver

- SwiftUI natif ;
- pas de framework UI tiers ;
- pas d’Electron/Tauri ;
- pas de parsing YAML dans Swift ;
- pas de parsing de `stdout` pour déterminer un état métier ;
- `CommandRunner` basé sur `Process.arguments` ;
- `CommandCenter` autoritaire sur l’opération active ;
- logique canonical/manifest/registry dans le backend ;
- sandbox désactivé ;
- fallback AppleScript ;
- projet Xcode existant ;
- workflows CLI ;
- worktree préservé ;
- aucun commit automatique sans autorisation explicite.

### 1.4 Références Apple

- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles)
- [Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
- [Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields)
- [Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback)
- [Progress indicators](https://developer.apple.com/design/human-interface-guidelines/progress-indicators)
- [Motion](https://developer.apple.com/design/human-interface-guidelines/motion)

---

## 2. Audit synthétique de l’état actuel

### 2.1 Ce qui est maintenant réussi

#### Vue d’ensemble

- héro de santé lisible ;
- bonne respiration ;
- résumé des projets structuré ;
- teinte de succès sobre ;
- action secondaire correctement dépriorisée ;
- largeur de contenu maîtrisée.

#### Projets

- navigation maître-détail efficace ;
- résumé compact ;
- tableau lisible ;
- filtres compréhensibles ;
- exceptions clairement séparées ;
- état vide contextualisé.

#### Activité

- résultat humain avant les preuves ;
- ressources clairement présentées ;
- détails techniques repliés ;
- liste et détail bien séparés ;
- dates et durées localisées.

### 2.2 Pourquoi l’application n’est pas encore mémorable

L’application possède désormais une excellente base, mais son apparence reste largement construite avec les motifs attendus d’un utilitaire SwiftUI :

- sidebar ;
- cartes ;
- métriques ;
- table ;
- liste maître-détail ;
- boutons et menus système.

Ces choix sont justes, mais aucun élément ne permet encore d’identifier immédiatement `AI System` sans voir son nom.

L’expérience est principalement statique :

- elle montre bien l’état final ;
- elle ne donne pas encore une sensation forte du système qui travaille ;
- elle ne permet pas encore d’atteindre instantanément n’importe quelle intention ;
- elle ne possède pas de geste ou composant signature.

### 2.3 Évaluation qualitative

| Dimension | État actuel | Potentiel après UX3 |
|---|---:|---:|
| Clarté | élevée | très élevée |
| Cohérence | élevée | très élevée |
| Qualité visuelle | bonne | premium |
| Identité propre | moyenne/faible | forte |
| Vitesse d’usage expert | moyenne | excellente |
| Confiance pendant une opération | correcte | excellente |
| Mémorabilité | moyenne | forte |

### 2.4 Principe de sélection

Les trois axes retenus ont été choisis parce qu’ils agissent chacun sur une dimension différente :

- **voir** : comprendre et reconnaître le système ;
- **agir** : atteindre n’importe quelle intention instantanément ;
- **ressentir** : percevoir clairement le déroulement et le résultat des opérations.

---

# TRANSFORMATION 1 — SYSTEM PULSE

## 3. Vision

### 3.1 Problème résolu

La Vue d’ensemble actuelle est propre, mais elle reste une succession de trois surfaces :

- santé ;
- métriques ;
- activité récente.

Elle explique que tout est synchronisé, sans montrer ce qui rend `AI System` unique : un système central qui maintient plusieurs projets cohérents entre Claude et Codex.

### 3.2 Proposition

Créer un composant signature nommé **System Pulse** : une représentation simple, interactive et accessible du flux géré par l’application.

Le composant représente :

```text
AI System → Projets → Claude + Codex
```

Il ne s’agit pas d’un diagramme technique détaillé. Il s’agit d’un résumé spatial en quatre éléments :

1. le noyau AI System ;
2. le groupe de projets ;
3. Claude ;
4. Codex.

Les connexions expriment l’état réel : sain, attention, erreur, vérification en cours ou inconnu.

### 3.3 Pourquoi ce point transforme l’application

- il rend la fonction du produit compréhensible en deux secondes ;
- il crée un élément visuel propre à AI System ;
- il utilise l’espace disponible de la Vue d’ensemble de manière fonctionnelle ;
- il remplace une partie de la logique « dashboard » par un modèle mental ;
- il donne une forme visible à la synchronisation ;
- il peut guider vers les projets ou destinations concernés lorsqu’un problème apparaît.

---

## 4. Spécification fonctionnelle de System Pulse

### 4.1 Position dans la Vue d’ensemble

Le héro actuel est conservé, mais il devient la partie supérieure d’une surface signature plus complète.

Ordre recommandé :

1. conclusion et action ;
2. System Pulse ;
3. activité récente.

Le résumé des projets actuellement séparé peut être intégré dans System Pulse ou rester immédiatement sous lui si le prototype montre une meilleure lisibilité. Il ne doit pas produire une répétition exacte des mêmes données.

### 4.2 Structure visuelle

À largeur normale :

- nœud **AI System** à gauche ou au centre-gauche ;
- nœud **10 projets** au centre ;
- deux nœuds **Claude** et **Codex** à droite ;
- connexions horizontales ou légèrement ramifiées ;
- une seule ligne visuelle principale ;
- hauteur totale recommandée : 150 à 190 points ;
- padding interne : 20 à 24 points.

À largeur réduite :

- disposition verticale ;
- AI System en haut ;
- projets au centre ;
- Claude/Codex sur la dernière ligne ;
- aucun texte tronqué ;
- aucune connexion qui traverse un libellé.

### 4.3 Contenu des nœuds

#### AI System

- icône de l’application ou symbole signature ;
- libellé `AI System` ;
- sous-texte `146 skills gérés` ou formulation issue des données disponibles ;
- état du noyau.

#### Projets

- libellé `10 projets` ;
- sous-texte `10 à jour` ;
- état agrégé ;
- clic : ouvre Projets ;
- si des actions existent : sous-texte `2 à examiner` et teinte attention.

#### Claude

- symbole distinct mais cohérent ;
- libellé Claude ;
- sous-texte `Synchronisé` ou `N exports concernés` si disponible ;
- clic : ouvre Projets avec un filtre pertinent seulement si cette navigation est fiable.

#### Codex

- même structure que Claude ;
- ne pas employer un logo externe non autorisé ;
- SF Symbol ou glyph interne cohérent.

### 4.4 États

#### Healthy

- connexions continues ;
- vert utilisé sur de petites zones ;
- fond très légèrement teinté ;
- copie principale `Tout est synchronisé` ;
- aucun mouvement permanent.

#### Attention

- la connexion ou le nœud concerné devient orange ;
- le nœud Projets indique le nombre d’actions ;
- action principale `Examiner` ;
- cliquer ouvre directement le contexte filtré.

#### Error

- le segment concerné est interrompu ou marqué ;
- rouge limité au signal ;
- texte expliquant la cause générale ;
- accès à l’activité concernée.

#### Unknown

- connexions en style neutre/pointillé ;
- copie `État non vérifié` ;
- action `Vérifier maintenant`.

#### Running

- aucun faux pourcentage ;
- petite progression indéterminée dans le nœud actif ;
- un seul passage animé le long du flux peut être utilisé pour signifier l’activité ;
- si Reduce Motion est actif, remplacer par un changement d’opacité statique.

### 4.5 Interactions

- survol d’un nœud : élévation/teinte très légère et tooltip ;
- clic Projets : navigation vers Projets ;
- clic sur un nœud en anomalie : navigation vers la vue/filtre correspondant ;
- navigation clavier entre nœuds ;
- VoiceOver présente le composant comme un résumé groupé puis expose les nœuds interactifs.

### 4.6 Motion signature

Une animation courte peut devenir la signature du produit après une vérification réussie :

1. la progression s’arrête ;
2. la connexion AI System → Projets s’illumine ;
3. la connexion se divise vers Claude et Codex ;
4. les nœuds passent à l’état sain ;
5. le titre devient `Tout est synchronisé`.

Durée totale cible : 500 à 750 ms.

L’animation :

- se joue une seule fois par résultat ;
- ne boucle jamais ;
- ne bloque aucune interaction ;
- respecte Reduce Motion ;
- ne modifie pas la mise en page.

### 4.7 Accessibilité

Résumé VoiceOver recommandé :

> AI System est à jour. 10 projets sont synchronisés avec Claude et Codex. Aucune action n’est requise.

Le dessin des connexions est décoratif pour VoiceOver. Les informations sont portées par des labels textuels.

---

## 5. Spécification technique de System Pulse

### 5.1 Données

Réutiliser exclusivement :

- l’overview existant ;
- les compteurs projets ;
- l’état global ;
- les compteurs de skills ;
- les actions requises ;
- les informations Claude/Codex déjà structurées si disponibles.

Si l’état séparé Claude/Codex n’existe pas, les deux nœuds affichent l’état global de distribution. Ne pas déduire cet état en lisant les logs.

### 5.2 Composants proposés

- `SystemPulseView` ;
- `SystemPulseNode` ;
- `SystemPulseConnector` ;
- `SystemPulseModel` purement présentation ;
- `SystemPulseLayout` uniquement si un `HStack/VStack/ViewThatFits` ne suffit pas.

### 5.3 Implémentation graphique

Ordre de préférence :

1. vues SwiftUI simples et `Shape` ;
2. `ViewThatFits` pour l’adaptation ;
3. custom `Layout` si nécessaire ;
4. `Canvas` seulement si les connexions deviennent impossibles à maintenir autrement.

Éviter :

- moteur de graphes ;
- SpriteKit ;
- image générée ;
- shader ;
- animation infinie ;
- géométrie fragile calculée à partir de coordonnées globales non testées.

### 5.4 Tests

- healthy/attention/error/unknown/running ;
- nombre de projets variable ;
- valeurs longues ;
- largeur 1335 et largeur minimale ;
- light/dark ;
- Reduce Motion ;
- navigation clavier ;
- labels VoiceOver ;
- snapshot manuel après vérification.

### 5.5 Critères d’acceptation

- la fonction d’AI System est compréhensible sans lire un paragraphe ;
- le composant est identifiable comme propre au produit ;
- aucune donnée n’est inventée ;
- la Vue d’ensemble reste simple ;
- System Pulse ne ressemble pas à un diagramme d’architecture ;
- le composant reste utile quand tout va bien ;
- une anomalie permet une navigation directe ;
- aucune animation permanente ;
- app utilisable avec Reduce Motion.

---

# TRANSFORMATION 2 — QUICK COMMAND

## 6. Vision

### 6.1 Problème résolu

L’interface est facile à comprendre, mais l’utilisateur expert doit encore :

- choisir une destination ;
- sélectionner un projet ;
- trouver une action ;
- ouvrir un menu secondaire ;
- parfois rechercher ensuite un skill.

Pour une application de développeur utilisée régulièrement, la meilleure interface est aussi celle qui peut s’effacer lorsqu’on connaît son intention.

### 6.2 Proposition

Créer une palette globale **Quick Command**, ouverte avec `⌘K`, permettant de :

- naviguer ;
- ouvrir un projet ;
- rechercher un skill ;
- lancer une vérification ;
- préparer une synchronisation ;
- ajouter un projet ;
- ouvrir une activité ;
- ouvrir Inventory, Doctor ou les réglages.

### 6.3 Pourquoi ce point transforme l’application

- il donne une interaction signature immédiatement mémorisable ;
- il accélère tous les workflows ;
- il réduit le besoin d’ajouter de nouveaux boutons ;
- il convient parfaitement à une application destinée à un développeur ;
- il rend les fonctions secondaires accessibles sans charger l’interface ;
- il crée un pont unique entre navigation, objets et actions.

---

## 7. Spécification fonctionnelle de Quick Command

### 7.1 Déclenchement

- raccourci principal : `⌘K` ;
- menu application : `Actions > Ouvrir Quick Command…` ;
- optionnel : bouton de toolbar uniquement si les tests montrent qu’un point d’entrée visible est nécessaire ;
- le raccourci fonctionne depuis les trois destinations et les Réglages, sauf pendant une modalité bloquante.

### 7.2 Présentation

- overlay ou sheet centrée ;
- largeur idéale : 620 à 700 points ;
- hauteur maximale : 520 points ;
- matériau système ;
- champ de recherche autofocus ;
- liste de résultats ;
- footer discret avec raccourcis clavier ;
- aucune navigation de sidebar visible à l’intérieur.

### 7.3 État sans requête

Afficher au maximum :

- 3 actions suggérées ;
- 5 éléments récents ;
- raccourcis contextuels selon la destination active.

Exemple depuis Vue d’ensemble :

- Vérifier le système ;
- Ouvrir Suggst ;
- Ajouter un projet ;
- Activité récente : Vérification du système.

### 7.4 Catégories de résultats

#### Navigation

- Vue d’ensemble ;
- Projets ;
- Activité ;
- Réglages.

#### Actions

- Vérifier le système ;
- Ajouter un projet ;
- Synchroniser le projet sélectionné ;
- ouvrir Inventory ;
- ouvrir Doctor.

#### Projets

- chaque projet actif ;
- sous-titre avec son état ;
- action par défaut : ouvrir le projet.

#### Skills

- skill ;
- projet ;
- statut ;
- action par défaut : ouvrir le projet et sélectionner/filtrer le skill ;
- ne pas exécuter automatiquement un import depuis un simple Return.

#### Activités

- activités de la session ;
- action : ouvrir le détail.

#### Ressources

- Inventory ;
- Doctor ;
- Journal ;
- README/Operations si ces ressources sont déjà exposées.

### 7.5 Recherche

La recherche porte sur :

- libellé visible ;
- alias connus ;
- nom de projet ;
- nom de skill ;
- mots-clés français simples.

Exemples d’alias :

- `check`, `vérifier`, `santé` → Vérifier le système ;
- `sync`, `synchroniser` → Synchroniser ;
- `log`, `journal` → Activité/Journal ;
- `settings`, `réglages` → Réglages.

### 7.6 Classement

Ordre de pertinence :

1. correspondance exacte ;
2. préfixe ;
3. mot complet ;
4. sous-chaîne ;
5. alias ;
6. récence ;
7. contexte actif.

Ne pas ajouter de dépendance de fuzzy-search lors de la première version. Une normalisation locale simple suffit.

### 7.7 Navigation clavier

- flèches haut/bas : sélection ;
- Return : action principale ;
- `⌘Return` : action alternative uniquement si elle est clairement affichée ;
- Échap : fermer ;
- Tab : naviguer vers les contrôles auxiliaires si présents ;
- la sélection reste toujours visible.

### 7.8 Sécurité des actions

#### Actions en lecture seule

Peuvent s’exécuter directement :

- naviguer ;
- ouvrir un projet ;
- ouvrir une activité ;
- ouvrir un rapport ;
- vérifier le système si cette opération est déjà considérée sûre et non destructive.

#### Actions mutantes

Ne sont jamais déclenchées sans contexte/confirmation :

- synchroniser ;
- importer ;
- ajouter un projet ;
- toute future action de suppression.

Quick Command doit alors :

- naviguer vers le contexte ;
- ou ouvrir la sheet de confirmation existante ;
- conserver les mêmes règles que l’UI principale.

### 7.9 Récence

Mémoriser au maximum 5 identifiants de commandes/objets récents.

Ne pas persister :

- sortie de logs ;
- chemins sensibles supplémentaires ;
- contenu des requêtes utilisateur ;
- paramètres techniques complets.

### 7.10 États vides et erreurs

#### Aucun résultat

> Aucun résultat pour “…”

Proposer :

- Vérifier l’orthographe ;
- ouvrir Projets ;
- afficher toutes les commandes.

#### Données non chargées

Afficher les commandes statiques immédiatement. Les projets/skills apparaissent lorsque leurs stores sont disponibles.

#### Action indisponible

Expliquer la raison :

- opération déjà en cours ;
- aucun projet sélectionné ;
- action non autorisée par le backend.

---

## 8. Spécification technique de Quick Command

### 8.1 Modèles

```text
QuickCommandItem
- id
- kind
- title
- subtitle
- systemImage
- keywords
- availability
- action
- alternateAction optional
```

L’action doit être une intention typée, pas une closure opaque difficile à tester.

Exemple conceptuel :

```text
QuickCommandIntent
- navigate(section)
- openProject(projectID)
- revealSkill(projectID, skillID)
- openActivity(activityID)
- runCheck
- prepareProjectSync(projectID)
- addProject
- openResource(resourceID)
- openSettings
```

### 8.2 Composants proposés

- `QuickCommandView` ;
- `QuickCommandViewModel` ;
- `QuickCommandRegistry` ;
- `QuickCommandSearchIndex` ;
- `QuickCommandRow` ;
- `QuickCommandIntentRouter` ;
- `AppCommands` enrichi avec `⌘K`.

### 8.3 Sources de données

- commandes statiques définies dans le registre ;
- projets depuis le store existant ;
- skills depuis les scans déjà chargés ;
- activités depuis `ActivityStore` ;
- contexte courant depuis la navigation.

Ne pas scanner le filesystem à l’ouverture de la palette.

### 8.4 Performance

- ouverture perçue instantanée ;
- commandes statiques disponibles sans attente ;
- filtrage en mémoire ;
- aucun appel backend à chaque frappe ;
- index reconstruit uniquement lorsque les données sources changent ;
- objectif : résultats mis à jour sous 50 ms pour le volume actuel.

### 8.5 Tests

- ouverture/fermeture `⌘K` ;
- recherche exacte/préfixe/alias ;
- classement ;
- navigation clavier ;
- projet actif ;
- skill ;
- activité ;
- données non chargées ;
- opération déjà en cours ;
- action mutante ouvre confirmation ;
- récents limités à 5 ;
- VoiceOver ;
- petite fenêtre ;
- light/dark.

### 8.6 Critères d’acceptation

- une commande ou un projet s’ouvre sans toucher la souris ;
- la palette apparaît instantanément ;
- aucune action destructive/mutante n’est exécutée accidentellement ;
- aucune nouvelle logique métier n’est implémentée dans la palette ;
- la navigation obtenue est identique à celle de l’UI principale ;
- `⌘K`, flèches, Return et Échap fonctionnent ;
- la palette reste utile même si les projets ne sont pas encore chargés.

---

# TRANSFORMATION 3 — OPERATION EXPERIENCE

## 9. Vision

### 9.1 Problème résolu

L’application présente maintenant correctement les résultats, mais l’expérience entre le clic et le résultat reste principalement technique :

- un bouton est déclenché ;
- un indicateur montre que quelque chose travaille ;
- les données sont actualisées ;
- une activité est créée.

Ce fonctionnement est correct, mais une application premium doit donner une sensation continue de maîtrise :

- ce qui se passe ;
- sur quoi ;
- depuis combien de temps ;
- si la navigation reste possible ;
- ce qui a changé ;
- où retrouver la preuve.

### 9.2 Proposition

Créer une couche globale **Operation Experience** composée de :

1. un indicateur d’opération persistant mais discret ;
2. des transitions d’état cohérentes ;
3. un reçu sémantique après chaque opération ;
4. une Activity enrichie par ces reçus ;
5. un langage de mouvement partagé.

### 9.3 Pourquoi ce point transforme l’application

- il rend le backend tangible et rassurant ;
- il donne une sensation de continuité entre les écrans ;
- il évite les clics répétés et l’incertitude ;
- il transforme les logs en preuve secondaire ;
- il produit les micro-interactions qui distinguent une application correcte d’une application premium.

---

## 10. Spécification fonctionnelle de l’indicateur global

### 10.1 Principe

Une opération en cours reste visible même si l’utilisateur change de destination.

L’indicateur ne doit pas bloquer la navigation ni couvrir le contenu.

### 10.2 Emplacement recommandé

Utiliser un contrôle compact dans la toolbar, côté trailing, ou un emplacement natif équivalent validé par prototype.

Éviter :

- grande bannière persistante ;
- overlay bas-droite couvrant le tableau ;
- toast au centre ;
- modalité bloquante pour une vérification.

### 10.3 États

#### Idle

- contrôle absent ;
- aucune place vide réservée.

#### Running

- `ProgressView` compact ;
- titre court : `Vérification…`, `Synchronisation de Suggst…` ;
- durée écoulée optionnelle après 2 secondes ;
- clic : popover ou navigation vers l’activité running ;
- tooltip détaillée.

#### Succeeded

- le spinner devient une coche ;
- message : `Vérification terminée · 0 action` ;
- affichage 2,5 à 4 secondes ;
- clic : ouvre l’activité ;
- disparition douce.

#### Failed

- symbole d’erreur ;
- message contextualisé ;
- reste visible jusqu’à consultation ou fermeture explicite ;
- clic : ouvre l’activité et l’erreur ;
- jamais auto-dismiss tant que l’utilisateur n’a pas pu prendre connaissance du résultat.

#### Cancelled

- message neutre ;
- disparition après une courte durée ;
- activité conservée si le modèle actuel le prévoit.

### 10.4 Popover d’opération

Contenu minimal :

- action ;
- cible ;
- état ;
- durée ;
- message courant ;
- action `Voir dans Activité` ;
- action Annuler uniquement si l’annulation est sûre.

Ne pas afficher stdout dans ce popover.

---

## 11. Reçus sémantiques

### 11.1 Définition

Un reçu est la synthèse structurée et durable dans la session de ce qu’une opération a fait.

Il répond à :

- quelle action ?
- sur quelle cible ?
- quel résultat ?
- quels changements ?
- quels avertissements ?
- combien de temps ?
- où voir les détails ?

### 11.2 Contenu recommandé

```text
OperationReceipt
- operationID
- kind
- target
- status
- startedAt
- finishedAt
- duration
- headline
- summary
- createdCount optional
- updatedCount optional
- unchangedCount optional
- warningCount optional
- errorCount optional
- actionRequiredCount optional
- resources
- technicalReference
```

### 11.3 Règle de vérité

Chaque champ provient :

- d’une réponse JSON structurée ;
- du contexte connu au déclenchement ;
- de `CommandResult` pour durée/exit code ;
- d’un rescan/overview structuré après mutation.

Aucun compteur n’est extrait de lignes `stdout`.

### 11.4 Présentation dans Activité

L’en-tête actuel est conservé.

La surface Résultat devient un reçu compact :

#### Vérification saine

> **Tout est à jour**  
> 10 projets vérifiés · 146 skills gérés · aucune action requise

#### Synchronisation

> **Suggst synchronisé**  
> 2 exports mis à jour · 18 inchangés · aucun conflit

#### Import

> **new-skill est maintenant géré**  
> Source créée et exports Claude/Codex synchronisés

#### Échec

> **La synchronisation de Suggst a échoué**  
> Aucun fichier n’a été modifié. Un conflit doit être examiné.

Les ressources et détails techniques restent sous le reçu.

### 11.5 Présentation ailleurs

- Overview : activité récente affiche le `headline` et le résumé court ;
- Projets : feedback inline après import/sync ;
- toolbar : headline compact ;
- Quick Command : activité récente peut afficher le headline.

Un même reçu alimente toutes les représentations. Ne pas générer plusieurs copies divergentes.

---

## 12. Langage de mouvement

### 12.1 Principes

- mouvement fonctionnel ;
- durée courte ;
- aucun rebond excessif ;
- aucune boucle décorative ;
- continuité entre déclenchement et résultat ;
- Reduce Motion autoritaire.

### 12.2 Transitions recommandées

#### Déclenchement

- le bouton affiche immédiatement un état busy local ;
- l’indicateur global apparaît par fondu/déplacement de quelques points ;
- durée : 150 à 220 ms.

#### Mise à jour de métriques

- `contentTransition(.numericText())` si compatible ;
- animation 200 à 300 ms ;
- aucune animation si Reduce Motion.

#### Succès

- spinner → coche ;
- symbol replacement natif si disponible ;
- teinte sémantique brève ;
- 250 à 400 ms.

#### Liste de skills

- un skill importé change de section par transition sobre ;
- conserver la sélection et la position autant que possible ;
- ne pas faire défiler automatiquement sur une grande distance.

#### Erreur

- pas de secousse ;
- apparition stable ;
- couleur et texte ;
- focus accessible sur l’action suivante si pertinent.

### 12.3 Reduce Motion

Avec Reduce Motion :

- remplacer déplacements par crossfade ;
- désactiver la propagation animée System Pulse ;
- désactiver numericText animé si gênant ;
- conserver tous les changements d’état et textes.

---

## 13. Spécification technique Operation Experience

### 13.1 Source d’état

`CommandCenter` reste l’autorité sur l’opération active.

Évolution recommandée : exposer un modèle de présentation stable :

```text
ActiveOperation
- id
- kind
- displayName
- target
- state
- startedAt
- cancellable
- progress optional
- statusMessage optional
```

Ne pas dupliquer cet état dans chaque ViewModel.

### 13.2 Composants proposés

- `OperationStatusControl` ;
- `OperationStatusPopover` ;
- `OperationReceipt` ;
- `OperationReceiptBuilder` ;
- `OperationReceiptView` ;
- `OperationMotion` ou helpers d’animation légers.

### 13.3 ActivityStore

L’activité session-only reste acceptable.

Le store doit recevoir :

- l’activité ;
- son reçu ;
- ses références techniques.

Il ne doit pas reconstruire le reçu à partir de stdout après coup.

### 13.4 Progression

Si le backend ne fournit pas de phases ou pourcentage structurés :

- `progress = nil` ;
- `ProgressView` indéterminé ;
- message générique et véridique.

Ne pas inventer :

- `Analyse des projets` ;
- `Comparaison des exports` ;
- pourcentages ;
- compteurs intermédiaires.

### 13.5 Concurrence

- une opération mutante active reste sérialisée ;
- Quick Command reflète l’indisponibilité ;
- les boutons locaux reflètent le même état ;
- l’utilisateur peut naviguer et consulter ;
- aucune seconde source de vérité `isRunning` par feature.

### 13.6 Tests

- idle/running/succeeded/failed/cancelled ;
- navigation pendant running ;
- succès auto-dismiss ;
- erreur persistante ;
- clic vers Activité ;
- reçu check/sync/import/error ;
- absence de données optionnelles ;
- aucun parsing stdout ;
- Reduce Motion ;
- VoiceOver ;
- Quick Command pendant opération ;
- métriques actualisées après résultat.

### 13.7 Critères d’acceptation

- l’utilisateur sait toujours si une opération est active ;
- la navigation reste disponible ;
- un succès explique ce qui a changé ;
- un échec reste visible et mène au diagnostic ;
- la même vérité alimente toolbar, Activity et feedback inline ;
- aucun faux progrès ;
- aucune duplication d’état ;
- motion désactivable ;
- stdout reste secondaire.

---

## 14. Cohérence entre les trois transformations

### 14.1 Un seul modèle d’état

System Pulse, Quick Command et Operation Experience consomment les stores existants et le modèle d’opération partagé.

Ils ne créent pas trois nouvelles sources de vérité.

### 14.2 Parcours intégré : vérifier le système

1. `⌘K` ;
2. saisir `vérifier` ;
3. Return ;
4. Quick Command se ferme ;
5. OperationStatusControl apparaît ;
6. System Pulse passe en running ;
7. l’utilisateur peut aller dans Projets ;
8. l’opération se termine ;
9. l’indicateur affiche le reçu ;
10. System Pulse effectue sa transition unique ;
11. une activité est disponible.

### 14.3 Parcours intégré : trouver un skill

1. `⌘K` ;
2. saisir `06-pivot` ;
3. sélectionner le résultat ;
4. ouvrir Suggst ;
5. appliquer le filtre/recherche nécessaire ;
6. révéler la ligne ;
7. aucune nouvelle analyse backend si les données sont déjà disponibles.

### 14.4 Parcours intégré : échec de synchronisation

1. synchronisation déclenchée depuis Projets ou Quick Command ;
2. indicateur global running ;
3. échec ;
4. indicateur rouge persistant ;
5. System Pulse marque le segment concerné ;
6. clic ouvre le reçu dans Activité ;
7. détails techniques restent fermés jusqu’à demande.

---

## 15. Architecture technique globale

### 15.1 Organisation indicative

```text
Features/
├── Overview/
│   └── SystemPulse/
│       ├── SystemPulseView.swift
│       ├── SystemPulseNode.swift
│       └── SystemPulseModel.swift
├── QuickCommand/
│   ├── QuickCommandView.swift
│   ├── QuickCommandViewModel.swift
│   ├── QuickCommandRegistry.swift
│   └── QuickCommandIntentRouter.swift
└── Activity/
    ├── OperationReceiptView.swift
    └── OperationStatusControl.swift

Models/
├── ActiveOperation.swift
├── OperationReceipt.swift
└── QuickCommandItem.swift
```

Adapter ces chemins à l’arborescence réelle. Ne pas déplacer mécaniquement tous les fichiers existants uniquement pour correspondre à cet exemple.

### 15.2 Dépendances

Aucune dépendance externe nécessaire.

### 15.3 Backend

Backend inchangé par défaut.

Une évolution additive est autorisée uniquement si un reçu important ne peut pas être construit depuis les réponses JSON existantes. Dans ce cas :

- champ optionnel ;
- schéma versionné ;
- rétrocompatibilité ;
- tests backend ;
- aucune sortie humaine parsée côté Swift.

### 15.4 Performance

- System Pulse ne doit pas provoquer de rendu continu ;
- Quick Command filtre en mémoire ;
- aucune animation infinie ;
- aucune requête backend par frappe ;
- OperationStatusControl observe une seule source ;
- objectif : aucune dégradation perceptible du lancement ou de la navigation.

---

## 16. Plan d’implémentation en étapes

### UX3-00 — Baseline et prototypes de décision

#### Objectif

Figer l’état post-UX2 et valider les trois concepts avant l’implémentation complète.

#### Travaux

1. Inspecter `git status --short`.
2. Lire le code réel Overview, AppCommands, CommandCenter et ActivityStore.
3. Documenter les données existantes disponibles pour System Pulse et les reçus.
4. Construire trois prototypes isolés avec fixtures :
   - System Pulse healthy/attention ;
   - Quick Command statique ;
   - OperationStatusControl running/success/error.
5. Vérifier mode sombre et mode clair.
6. Vérifier taille minimale.
7. Choisir les variantes finales.

#### Livrable

`docs/UX3-00-BASELINE-AND-PROTOTYPES.md`.

#### Critères d’acceptation

- aucune logique métier modifiée ;
- données nécessaires identifiées ;
- trois prototypes visibles ;
- variante finale de chaque point documentée ;
- build et check verts.

---

### UX3-01 — System Pulse fondations

#### Objectif

Créer le composant signature et ses états sans remplacer immédiatement la Vue d’ensemble.

#### Travaux

1. Créer `SystemPulseModel`.
2. Mapper l’overview existant.
3. Créer les nœuds et connexions.
4. Implémenter layout horizontal/vertical.
5. Implémenter healthy/attention/error/unknown/running.
6. Ajouter interactions et navigation.
7. Ajouter VoiceOver et Reduce Motion.
8. Ajouter tests.

#### Critères d’acceptation

- aucune donnée inventée ;
- cinq états ;
- layout adaptatif ;
- navigation fonctionnelle ;
- rendu light/dark ;
- tests verts.

---

### UX3-02 — Intégration signature Overview

#### Objectif

Transformer la Vue d’ensemble autour de System Pulse sans la surcharger.

#### Travaux

1. Intégrer System Pulse au héro ou immédiatement sous lui.
2. Supprimer les métriques redondantes.
3. Conserver l’activité récente.
4. Implémenter la transition post-vérification.
5. Vérifier les états action requise/erreur.
6. Produire captures Release.

#### Critères d’acceptation

- l’écran ne contient pas deux résumés identiques ;
- la fonction du produit est visible immédiatement ;
- la page reste simple ;
- animation unique, courte et accessible ;
- capture à 1335×968 et taille minimale validée.

---

### UX3-03 — Quick Command

#### Objectif

Livrer la palette globale complète et sûre.

#### Travaux

1. Créer registre et intents typés.
2. Ajouter `⌘K` dans `AppCommands`.
3. Créer overlay/sheet.
4. Ajouter navigation et actions statiques.
5. Indexer projets.
6. Indexer skills déjà chargés.
7. Indexer activités de session.
8. Implémenter alias et classement.
9. Implémenter récents.
10. Router les actions mutantes vers confirmations existantes.
11. Ajouter clavier/VoiceOver/tests.

#### Critères d’acceptation

- ouverture instantanée ;
- navigation complète au clavier ;
- aucun appel backend par frappe ;
- aucune mutation sans garde ;
- fonctionnement avec stores partiellement chargés ;
- tests verts.

---

### UX3-04 — Active Operation et feedback global

#### Objectif

Rendre chaque opération perceptible depuis toute l’application.

#### Travaux

1. Formaliser `ActiveOperation` depuis CommandCenter.
2. Créer `OperationStatusControl`.
3. Créer popover.
4. Implémenter running/success/error/cancelled.
5. Intégrer dans la toolbar globale.
6. Connecter les boutons locaux au même état.
7. Gérer navigation pendant opération.
8. Ajouter Reduce Motion et tests.

#### Critères d’acceptation

- une seule source de vérité ;
- statut visible depuis les trois destinations ;
- succès temporaire ;
- erreur persistante ;
- navigation disponible ;
- pas de faux progrès.

---

### UX3-05 — Reçus sémantiques et Activity

#### Objectif

Unifier la présentation des résultats autour d’un reçu structuré.

#### Travaux

1. Créer `OperationReceipt`.
2. Construire les reçus check/sync/import/add-project/error.
3. Ajouter les champs optionnels disponibles.
4. Alimenter ActivityStore.
5. Refaire la surface Résultat autour du reçu.
6. Réutiliser headline/summary dans Overview et l’indicateur global.
7. Conserver ressources et détails techniques.
8. Ajouter tests de non-parsing stdout.

#### Critères d’acceptation

- une seule copie autoritative par activité ;
- résumé clair de ce qui a changé ;
- données absentes omises proprement ;
- aucune interprétation de log ;
- erreur explique l’état d’écriture si connu ;
- tests verts.

---

### UX3-06 — Cohérence, motion et accessibilité

#### Objectif

Faire fonctionner les trois transformations comme une seule expérience.

#### Travaux

1. Implémenter les parcours intégrés.
2. Harmoniser les animations.
3. Vérifier Reduce Motion.
4. Vérifier focus clavier.
5. Vérifier VoiceOver.
6. Vérifier tooltips.
7. Vérifier light/dark/contraste.
8. Vérifier taille minimale.
9. Vérifier performance Quick Command.
10. Supprimer les feedbacks dupliqués.

#### Critères d’acceptation

- parcours check cohérent de bout en bout ;
- parcours recherche de skill cohérent ;
- parcours erreur cohérent ;
- aucune animation contradictoire ;
- aucune action inaccessible sans souris ;
- aucune régression des vues existantes.

---

### UX3-07 — Validation et clôture

#### Objectif

Valider l’expérience installée et documenter la phase.

#### Travaux

1. Tests backend.
2. Tests Swift.
3. Tests UI si Automation est autorisée.
4. Recette manuelle complète.
5. Captures System Pulse dans cinq états via fixtures/previews et états réels sûrs.
6. Capture Quick Command.
7. Capture OperationStatusControl running/success/error.
8. `make inventory`.
9. `make doctor`.
10. `make check`.
11. `make build-swift-app`.
12. Test de `~/Applications/AI System.app`.
13. Mise à jour README/OPERATIONS/docs.
14. Rapport `docs/UX3-07-CLOSURE.md`.

#### Critères d’acceptation

- trois transformations livrées ;
- aucune quatrième feature parasite ;
- app Release validée ;
- tests verts ou blocage UI environnemental documenté ;
- mode clair et sombre validés visuellement ;
- worktree documenté ;
- backend métier préservé.

---

## 17. Recette fonctionnelle

### 17.1 System Pulse

- healthy ;
- unknown ;
- running ;
- attention ;
- error ;
- clic Projets ;
- clic anomalie ;
- largeur standard ;
- largeur minimale ;
- light/dark ;
- Reduce Motion ;
- VoiceOver.

### 17.2 Quick Command

- `⌘K` depuis chaque destination ;
- recherche navigation ;
- recherche projet ;
- recherche skill ;
- alias français/anglais ;
- activité ;
- rapports ;
- action mutante ;
- opération active ;
- stores non chargés ;
- Échap ;
- flèches/Return ;
- VoiceOver.

### 17.3 Operation Experience

- check running/success ;
- check error ;
- sync ;
- import ;
- navigation pendant opération ;
- succès auto-dismiss ;
- erreur persistante ;
- clic vers Activity ;
- reçu avec champs partiels ;
- détails techniques fermés ;
- Reduce Motion.

---

## 18. Risques et mitigations

| Risque | Mitigation |
|---|---|
| System Pulse devient décoratif | chaque nœud porte une donnée et une navigation utiles |
| System Pulse devient trop technique | quatre nœuds maximum, aucun chemin de fichier/canonical |
| animation distrayante | une seule lecture, moins de 750 ms, Reduce Motion |
| palette devient un second menu complexe | catégories limitées et résultats contextuels |
| mutation accidentelle depuis `⌘K` | intents typés et confirmations existantes |
| recherche lente | index mémoire, aucun backend par frappe |
| état d’opération dupliqué | CommandCenter autoritaire |
| faux progrès | indéterminé sans contrat structuré |
| reçus reconstruits depuis stdout | builder alimenté uniquement par structures existantes |
| scope trop grand | trois transformations, aucune fonctionnalité hors axe |
| identité trop éloignée de macOS | matériaux, typographie, motion et contrôles système |

---

## 19. Priorité et impact

| Transformation | Impact visuel | Impact usage | Complexité | Priorité |
|---|---:|---:|---:|---:|
| System Pulse | très élevé | moyen/élevé | moyenne | P0 |
| Quick Command | moyen | très élevé | moyenne | P0 |
| Operation Experience | élevé en usage | très élevé | moyenne/élevée | P0 |

L’ordre recommandé reste :

1. System Pulse pour définir l’identité ;
2. Quick Command pour définir le geste signature ;
3. Operation Experience pour définir la sensation de qualité continue.

---

## 20. Definition of Done

### System Pulse

- [ ] Le rôle d’AI System est visible en deux secondes.
- [ ] Le composant possède cinq états.
- [ ] Les données viennent de modèles structurés.
- [ ] Les nœuds utiles sont interactifs.
- [ ] L’animation ne boucle pas.
- [ ] Reduce Motion est respecté.
- [ ] Light/dark et taille minimale sont validés.

### Quick Command

- [ ] `⌘K` fonctionne globalement.
- [ ] Navigation, projets, skills, activités et actions sont recherchables.
- [ ] Le filtrage est local et instantané.
- [ ] Les actions mutantes restent protégées.
- [ ] La palette est entièrement utilisable au clavier.
- [ ] Les récents sont limités et non sensibles.
- [ ] VoiceOver est validé.

### Operation Experience

- [ ] Une opération active est visible partout.
- [ ] La navigation reste disponible.
- [ ] Le succès explique le résultat.
- [ ] L’erreur persiste et mène au diagnostic.
- [ ] Activity reçoit un reçu sémantique.
- [ ] Aucun reçu ne parse stdout.
- [ ] Les animations sont cohérentes et désactivables.

### Validation globale

- [ ] Tests backend verts.
- [ ] Tests Swift verts.
- [ ] Tests UI ou blocage Automation documenté.
- [ ] `make inventory` OK.
- [ ] `make doctor` OK.
- [ ] `make check` OK.
- [ ] `make build-swift-app` OK.
- [ ] App installée testée.
- [ ] Modes clair et sombre validés visuellement.
- [ ] Aucun changement métier involontaire.
- [ ] Aucun framework tiers ajouté.

---

## 21. Conclusion

L’application n’a plus besoin de davantage de cartes, de couleurs ou de réglages fins. Elle a besoin de trois éléments qui lui appartiennent vraiment :

1. **une forme signature** — System Pulse ;
2. **un geste signature** — `⌘K` avec Quick Command ;
3. **une sensation signature** — des opérations continues, explicites et conclues par un reçu clair.

Ces trois transformations permettent de viser un niveau de qualité perçue nettement supérieur sans sacrifier la simplicité, la conformité macOS ni l’architecture actuelle.

