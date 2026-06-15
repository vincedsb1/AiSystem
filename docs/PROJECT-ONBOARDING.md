# Onboarding d’un nouveau projet

## 1. Déclarer le projet

Ajouter le projet dans `skills-registry.yml` avec ses paths racine, ses
contextes et sa liste `install_shared_skills`.

## 2. Installer les shared skills

Déclarer uniquement les `shared.*` réellement utiles au projet. Ne pas
ajouter de skill project-specific étranger.

## 3. Identifier les commandes Claude-only

Lister les commandes qui doivent rester locales au projet et ne pas être
converties automatiquement en Codex.

## 4. Créer les exceptions explicites

Créer une `pairing_exception` quand une commande Claude-only doit rester
volontairement sans équivalent Codex.

## 5. Créer un canonical project-specific

Créer un canonical project-specific seulement si le besoin métier est clair et
que la commande ne doit pas rester Claude-only.

## 6. Vérifier l’isolation

Vérifier qu’aucun export d’un autre projet n’apparaît dans le nouveau projet et
qu’aucun skill du projet n’est exporté ailleurs par erreur.

## 7. Commandes utiles

```bash
# Synchronisation ciblée des shared skills
.venv/bin/python scripts/sync_skills.py --apply --no-backup \
  --only shared.ai-post-task-review shared.commit shared.create-doc \
  shared.implement shared.optimize-claude-md shared.spec-0-feedback \
  shared.spec-1-intake shared.spec-2-draft shared.spec-3-audit \
  shared.spec-4-challenge shared.spec-5-revise shared.test shared.ui-review

# Vérification anti-fuite
grep -R "aimoto\|AIMOTO\|InterviewOS\|intrai\|Pylaa\|Pylot\|Skriipt\|Spotter\|suggst\|truthify" \
  <project>/.agents/skills || true

# Validation globale
make check
```

## 8. Documenter le projet

Créer `docs/projects/<project>-onboarding.md` pour résumer les décisions
d’isolation, les shared skills installés et les éventuelles exceptions.
