# UX3-07 — Clôture « Memorable Experience »

**Date :** 21 août 2026  
**Application :** `AI System.app`  
**Statut :** implémentation terminée ; validation UI automatisée bloquée par l’autorisation macOS Automation.

## Décision de périmètre

La mission UX3 est limitée aux trois transformations prescrites :

1. **System Pulse** — rendre visible le flux AI System → Projets → Claude/Codex ;
2. **Quick Command** — fournir une palette globale `⌘K` pour naviguer et agir ;
3. **Operation Experience** — unifier l’opération active, le feedback et le reçu sémantique.

Les contrats JSON, le canonical/manifest/registry, les routes backend, le
fallback AppleScript, `CommandRunner` et le mode sandbox sont conservés.

## Implémentation

| Transformation | Réalisation |
|---|---|
| System Pulse | `SystemPulseModel` et `SystemPulseView`, quatre nœuds, états healthy/attention/error/unknown/running, layout horizontal/vertical, Reduce Motion |
| Quick Command | `QuickCommandRegistry`, index local exact/préfixe/mot/sous-chaîne/alias/récence/contexte, intents typés, `⌘K` et menu d’action |
| Operation Experience | `CommandCenter`, `ActiveOperation`, `OperationReceipt`, indicateur toolbar, auto-dismiss du succès, erreur persistante, activité structurée |

Les composants reçoivent des modèles déjà interprétés. Aucun statut UX3 ne
provient d’un scan de stdout, d’un log ou d’un appel backend lancé par la
palette de recherche.

Faute de contrat séparé pour Claude et Codex, les deux nœuds affichent
explicitement l’état global. Aucun état provider spécifique n’est inventé.

## Validation automatisée

| Contrôle | Résultat |
|---|---|
| `.venv/bin/python -m unittest discover -s tests -p 'test*.py'` | **OK — 93 tests** |
| `xcodebuild … test -only-testing:'AI SystemTests'` | **OK — 110 tests, 0 échec, 0 ignoré** |
| `make inventory` | **OK — action_required=0** |
| `make doctor` | **OK — danger=0, review=0** |
| `make check` | **OK — dérive=0, exports manquants=0** |
| `make build-swift-app` | **OK — Release installé dans `/Users/vincentdesbrosses/Applications/AI System.app`** |
| `codesign --verify --deep --strict` sur l’app installée | **OK** |
| `git diff --check` | **OK** |

Résultat Swift détaillé :

`/Users/vincentdesbrosses/Library/Developer/Xcode/DerivedData/AI_System-fndtzuvikbyhccgtbttakxjdkmxh/Logs/Test/Test-AI System-2026.08.21_00-12-16-+0200.xcresult`

## Validation UI et recette visuelle

### Captures disponibles

- [Overview Release avec System Pulse](</tmp/ai-system-ux2-release-current.png>) — fenêtre standard, état sain réel.
- [Quick Command](</tmp/ai-system-ux3-quick-command.png>) — palette centrée, autofocus, navigation clavier et actions protégées.
- [Overview UX3 sombre](</tmp/ai-system-ux3-overview-dark.png>) — conclusion et flux System Pulse.
- [Recette fenêtre minimale UX2](ux2-baseline/ux2-final-min-window-window.png) — taille minimale déclarée `900 × 620` conservée par `ContentView`.

Les états System Pulse `healthy`, `attention`, `error`, `unknown` et `running`
sont couverts par `SystemPulseTests`, les fixtures de la galerie
`UX3PrototypeGallery` et les previews. L’état sain est également observé sur
l’app Release installée. Les contrôles Operation Experience `running`,
`success` et `failed` sont couverts par les fixtures de preview et
`OperationExperienceTests`, notamment l’auto-dismiss du succès et la
persistance de l’échec jusqu’à consultation.

La capture claire n’est pas déclarée PASS : la session macOS est restée en
apparence sombre malgré une tentative temporaire de bascule. Les surfaces
utilisent toutefois les matériaux et couleurs système, sans palette sombre
codée en dur. VoiceOver et les parcours clavier en direct sont `NOT_TESTED`
à cause du même blocage Automation ; les labels, états et contrats
d’accessibilité sont testés statiquement.

Le test UI ciblé a échoué avant l’exécution des assertions produit :

```text
XCTest is trying to Enable UI Automation.
Timed out while enabling automation mode.
```

Résultat conservé :

`/Users/vincentdesbrosses/Library/Developer/Xcode/DerivedData/AI_System-fndtzuvikbyhccgtbttakxjdkmxh/Logs/Test/Test-AI System-2026.08.20_23-58-07-+0200.xcresult`

Ce blocage est environnemental ; il ne constitue pas un échec d’assertion de
l’application.

## Préservation du dépôt

- Les quatre rapports `reports/ai-*.latest.*` déjà modifiés au démarrage ont
  été restaurés et comparés octet par octet à leur sauvegarde de baseline.
- Les deux spécifications fournies restent non suivies et inchangées.
- Aucun fichier backend, script ou contrat JSON n’a été modifié par UX3.
- Les changements UX3 restent dans le worktree pour revue.
- Aucun commit ni push n’a été effectué pendant cette mission.

## Conclusion

UX3 est techniquement prête : les trois transformations sont intégrées,
testées et installées. La seule limite résiduelle est la validation UI
automatisée/VoiceOver en direct, bloquée par l’autorisation macOS Automation,
avec une recette visuelle manuelle et des fixtures conservées comme preuves
complémentaires.
