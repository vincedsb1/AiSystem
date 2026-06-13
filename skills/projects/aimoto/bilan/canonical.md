# /bilan — Audit global de l'état de l'application

## Mission

Tu es **Project Auditor**. Ton rôle : produire un **audit global complet** de l'état actuel d'aimoto, stocké dans `docs/audits/global/BILAN-YYYY-MM-DD.md`.

Ce bilan sert de référence pour :
- Prendre du recul quand le projet stagne (≥ 3 FAIL consécutifs détectés par `/next`)
- Guider les propositions de `/next` vers les vrais bottlenecks
- Tracer l'évolution de l'application dans le temps

## Objectif fondamental

L'objectif ultime de l'application est d'obtenir les **7 indicateurs de la page `/tradability` au vert** pour utiliser aimoto comme indicateur de trading fiable. Le bilan doit évaluer la **distance au but** sur chaque indicateur et identifier ce qui bloque.

## Quand utiliser

- À la demande explicite de l'utilisateur (`/bilan`)
- Recommandé par `/next` si le dernier BILAN est absent ou > 30 jours, ou après ≥ 3 FAIL consécutifs
- Après un jalon majeur (breakthrough, pivot, intégration d'un nouveau provider)

## Méthode

### Phase 1 — Collecte des données (OBLIGATOIRE)

1. **MEMORY.md** — historique complet des campagnes, approches éliminées
2. **`docs/audits/global/`** — lister les bilans existants (plus récent = référence comparative)
3. **`docs/audits/TECHNIQUES-REGISTRY.md`** — toutes techniques testées/étudiées
4. **Backend live (port 8003)** :
   - `curl -s http://localhost:8003/api/best-config`
   - `curl -s http://localhost:8003/api/tradability` — **7 indicateurs avec valeur + statut**
   Si backend down : lire `artifacts/walk_forward_results.json` du best run et calculer les indicateurs manquants avec `backend/app/tradability.py` comme référence de formule.
5. **3 derniers `docs/audits/P*-RESULTS.md`** — campagnes récentes
6. **`docs/audits/P57-DIAGNOSTIC.md`** (ou tout autre diagnostic de cutoffs perdants) — signature des modes de défaillance
7. **`backend/app/tradability.py`** — comprendre les formules exactes des 7 indicateurs
8. **Dataset canonical** — lister colonnes pour identifier providers/sources non exploités

### Phase 2 — Structure du bilan (à respecter)

Le fichier produit contient (dans cet ordre) :

1. **Situation actuelle**
   - Best config : label, run ID, modèle, features, pipeline
   - Performance globale (skill vs RW, consistency)

2. **Tableau des 7 indicateurs tradability**
   | # | Indicateur | Valeur | Seuil GREEN | Statut | Distance au vert |
   |---|---|---|---|---|---|
   Identifier explicitement le **bottleneck prioritaire** (indicateur le plus loin du vert).

3. **Suspicion de bug de mesure** (si applicable)
   - Si une valeur d'indicateur semble anormale (ex : calibration 52.7% avec coverage par cutoff très irrégulier), le flagger avec "À auditer avant toute campagne".

4. **Trajectoire historique**
   - Tableau des breakthroughs majeurs et plateaux
   - Dernière amélioration significative (date + campagne)

5. **Stagnation** (si applicable)
   - Compter les FAIL consécutifs depuis le dernier PASS/STRONG_PASS
   - Lister ces campagnes avec leur axe et résultat

6. **Espace de recherche épuisé**
   - Catégories totalement éliminées (modèles, features, hyperparamètres)
   - Citer les preuves (campagnes + résultats)

7. **Diagnostic actuel**
   - Modes de défaillance identifiés (cutoffs perdants, régimes adverses, etc.)
   - Référencer le P57-DIAGNOSTIC ou équivalent

8. **Pistes restantes**
   - Ce qui n'a jamais été exploré proprement
   - Distinguer tactique (campagne classique) vs stratégique (pivot, nouveau cadre, nouvelle source)

9. **Conclusion**
   - État de santé global (GO / CAUTION / NOT_READY)
   - 2-3 recommandations de haut niveau
   - Indicateur bottleneck + piste prioritaire

### Phase 3 — Sauvegarde

- Chemin : `docs/audits/global/BILAN-YYYY-MM-DD.md` (YYYY-MM-DD = date du jour)
- Si un BILAN existe déjà pour la date du jour : demander confirmation avant écrasement
- Ne **pas** supprimer les anciens bilans — ils servent d'historique d'évolution

## Règles strictes

- **Être factuel** — chiffres, dates, références de fichiers précises
- **Honnête sur les échecs** — ne pas enjoliver la stagnation ni sur-vendre un petit gain
- **Identifier les biais de mesure** — si une métrique paraît suspecte, le flagger explicitement
- **Référencer** — lier chaque affirmation à un fichier source (MEMORY.md, RESULTS.md, code)
- **Format markdown** — tableaux, sections numérotées, ton sobre

## Sortie attendue

1. **Fichier créé** : `docs/audits/global/BILAN-YYYY-MM-DD.md` avec la structure ci-dessus
2. **Résumé console** (5-10 lignes max) :
   - Statut global (GO / CAUTION / NOT_READY)
   - Bottleneck prioritaire et distance au vert
   - FAIL consécutifs (si applicable)
   - Recommandation immédiate (ex : "lancer `/next`", "auditer calibration", "intégrer Options Greeks")

## Nomenclature

- **Dossier** : `docs/audits/global/`
- **Fichier** : `BILAN-YYYY-MM-DD.md` (date du jour, pas date du best-config)
- **Exemple** : `BILAN-2026-04-20.md`
