# PIPELINE_DESIGN.md

# Conception de la pipeline CI/CD — TaskBoard

## Objectif

L’objectif de la pipeline est d’automatiser la vérification du projet à chaque modification du dépôt GitHub.

La pipeline doit :

* vérifier la qualité du code
* exécuter les tests automatiquement
* générer un rapport de couverture
* construire une image Docker
* publier l’image sur GitHub Container Registry (GHCR)


# Stages de la pipeline

La pipeline sera composée de trois stages principaux :

1. Lint
2. Tests
3. Build & Push Docker


# Description des stages

## 1. Stage Lint

### Objectif

Vérifier automatiquement la qualité du code source avec ESLint.

### Commande exécutée

```bash
npm run lint
```

### Résultat attendu

* la pipeline échoue si des erreurs ESLint sont détectées
* garantit un code cohérent et maintenable


## 2. Stage Tests

### Objectif

Exécuter tous les tests unitaires et d’intégration.

### Commande exécutée

```bash
npm run test:coverage
```

### Résultat attendu

* tous les tests doivent réussir
* génération d’un rapport de couverture exploitable

### Artefacts publiés

Le dossier suivant sera publié comme artefact GitHub Actions :

```text
coverage/
```

Cela permet :

* d’analyser la couverture de code
* de conserver les rapports après l’exécution
* de partager les résultats entre jobs


## 3. Stage Build & Push Docker

### Objectif

Construire automatiquement l’image Docker de l’application et la publier sur GHCR.

### Actions réalisées

* build de l’image Docker
* tagging avec le SHA du commit
* push vers GitHub Container Registry

### Exemple de tag

```text
ghcr.io/<username>/taskboard:<commit-sha>
```

### Condition d’exécution

Ce stage doit uniquement s’exécuter sur la branche :

```text
main
```

Cela évite de publier des images provenant de branches temporaires.


# Dépendances entre jobs

Les jobs doivent être exécutés dans un ordre précis grâce au mot-clé :

```yaml
needs:
```

Ordre d’exécution :

```text
lint
  ↓
tests
  ↓
docker-build
```

Le build Docker ne doit jamais démarrer si :

* le lint échoue
* les tests échouent


# Déclencheurs de pipeline

La pipeline se déclenche automatiquement sur :

```yaml
on:
  push:
  pull_request:
```

Cela permet de vérifier :

* chaque push
* chaque Pull Request avant fusion


# Gestion du cache

## Cache npm

Le cache npm permettra :

* d’éviter de réinstaller toutes les dépendances à chaque exécution
* d’accélérer les builds suivants


## Cache Docker BuildKit

Le cache Docker permettra :

* de réutiliser les layers Docker déjà construits
* de réduire le temps de build de l’image


# Runner GitHub Actions

La pipeline utilisera un runner GitHub hébergé :

```yaml
runs-on: ubuntu-latest
```

Le runner est une machine virtuelle temporaire fournie par GitHub qui exécute les jobs automatiquement.


# Registry Docker choisi

Le registry retenu est :

```text
GitHub Container Registry (GHCR)
```

## Raisons du choix

* intégration native avec GitHub
* authentification simplifiée avec GITHUB_TOKEN
* permissions automatiques
* adapté aux projets hébergés sur GitHub

# Résultat attendu

La pipeline doit :

* se déclencher automatiquement à chaque push
* échouer si le lint ou les tests échouent
* publier automatiquement l’image Docker sur GHCR
* utiliser le cache pour accélérer les exécutions suivantes
* permettre de tracer chaque image grâce au tag SHA
