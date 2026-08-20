# UX2-06 — Clôture UX/UI Polish V2

Date : 2026-08-20  
Application : **AI System.app**  
Statut : implémentation terminée, validation UI automatisée limitée par macOS Automation.

## Résultat

La seconde passe UX/UI est appliquée de bout en bout sur les trois destinations
existantes, sans modifier la navigation, le backend, les contrats JSON ni les
workflows métier.

- **Overview** présente une conclusion de santé, quatre métriques, les actions
  conditionnelles et des lignes d’activité cliquables.
- **Projets** dispose d’un en-tête lisible, de quatre métriques, de filtres
  adaptatifs, d’un tableau aligné et d’états vides contextualisés.
- **Activité** regroupe recherche et filtre dans la liste, localise les dates et
  durées, structure le résultat métier et garde les détails techniques fermés.
- Les surfaces, espacements, rayons, formatters français, labels d’accessibilité
  et comportements de fenêtre minimale sont centralisés.

## Étapes réalisées

| Étape | Commit | Résultat |
|---|---|---|
| UX2-00 | e169ba0 | Baseline visuelle et état réel documentés |
| UX2-01 | b316389 | Fondations adaptatives et formatters |
| UX2-02 | 834cdaa | Overview et héro de santé |
| UX2-03 | d5f6528 | Projets, résumé, filtres et tableau |
| UX2-04 | 3336af0 | Activité, résultat, ressources et technique |
| UX2-05 | 551ddcc | Accessibilité et localisation |
| UX2-06 | e5a9365 | Validation finale et clôture |

## Validation automatisée

| Validation | Résultat |
|---|---|
| .venv/bin/python -m unittest discover -s tests -p 'test*.py' | OK — 93 tests |
| make inventory | OK — action_required=0, accepted_findings=226, expected_exceptions=30 |
| make doctor | OK — danger=0, review=0 |
| make check | OK — pairing sans dérive, manifest sans export manquant |
| make build-swift-app | OK — Release installé dans ~/Applications/AI System.app |
| xcodebuild test ... -only-testing:'AI SystemTests' | OK — 99 lignes de tests réussies |
| xcodebuild test ... -only-testing:'AI SystemUITests' | Bloqué avant exécution des tests |

Le blocage UI est reproductible et environnemental :

~~~
XCTest is trying to Enable UI Automation.
Timed out while enabling automation mode.
~~~

Le runner a échoué après 77,196 secondes avec le code 65 ; aucune assertion
produit n’a été exécutée. Le résultat est conservé dans :

/Users/vincentdesbrosses/Library/Developer/Xcode/DerivedData/AI_System-fndtzuvikbyhccgtbttakxjdkmxh/Logs/Test/Test-AI System-2026.08.20_22-28-03-+0200.xcresult

## Recette visuelle manuelle

Captures de l’app Release installée, fenêtre standard 1335×968 :

- [Overview saine](ux2-baseline/ux2-final-overview-dark.png)
- [Overview avec activité récente](ux2-baseline/ux2-final-overview-activity-dark.png)
- [Projets](ux2-baseline/ux2-final-projects-dark.png)
- [Activité — résultat et détails fermés](ux2-baseline/ux2-final-activity-dark.png)

La taille minimale a été exercée à 900×620 via l’API de fenêtre macOS. Les
colonnes Projets et le résumé passent en mode compact, et l’en-tête État du
tableau reste présent :

- [Recette fenêtre minimale](ux2-baseline/ux2-final-min-window-window.png)

Le mode sombre a été capturé. Le profil global de cette session est resté en
apparence sombre malgré la tentative temporaire de bascule claire ; aucune
capture claire fiable n’est donc déclarée PASS. La palette SwiftUI reste basée
sur les matériaux et couleurs système, sans couleur sombre codée en dur.

## Accessibilité et réduction du mouvement

- Les états possèdent un symbole et un libellé textuel.
- Les métriques et lignes métier utilisent des labels combinés dynamiques.
- Les actions secondaires disposent d’un nom accessible et d’un tooltip.
- functionalAnimation respecte accessibilityReduceMotion.
- Les contrats statiques AccessibilityContractTests sont verts.
- La validation VoiceOver/clavier en direct reste NOT_TESTED à cause du même
  blocage macOS Automation que la suite UI.

## Préservation et périmètre

- Aucun backend n’a été modifié et aucune sortie standard n’est parsée côté UI.
- Les quatre fichiers reports/ai-*.latest.* déjà modifiés avant la mission
  sont laissés hors des commits.
- Le fichier de spécification fourni reste hors des commits et inchangé.
- Aucun push n’a été effectué.
