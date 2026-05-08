## Tests manquants

- Tests sur erreurs DB (connexion échouée)
- Tests sur modification de tâche (PUT /tasks/:id)
- Tests sur suppression réussie (DELETE /tasks/:id)
- Tests sur expiration JWT

Ces cas sont importants pour garantir la robustesse de l'application en production, notamment dans un contexte CI/CD où les erreurs doivent être détectées automatiquement avant déploiement.


##  Justification des tests manquants

### Tests sur Erreurs de connexion à la base de données

Ces tests permettent de simuler une indisponibilité de la base de données (timeout, refus de connexion, crash du service).

**Pourquoi c’est important :**
- éviter les réponses 500 non maîtrisées
- garantir un comportement stable de `/health`
- améliorer la supervision et le monitoring en production



### Tests sur Modification de tâche (PUT /tasks/:id)

Ces tests couvrent les mises à jour de ressources existantes.

**Cas critiques à tester :**
- mise à jour d’une tâche existante
- tentative de mise à jour d’un ID inexistant (404)
- validation des champs envoyés (données incomplètes ou invalides)

**Pourquoi c’est important :**
- éviter la corruption de données
- garantir la cohérence des mises à jour
- sécuriser les opérations métiers


### Tests sur Suppression de tâche (DELETE /tasks/:id)

Ces tests vérifient la suppression de ressources.

**Cas critiques :**
- suppression réussie d’une tâche existante
- suppression d’un ID inexistant (404)
- suppression sans authentification (401)

**Pourquoi c’est important :**
- éviter des suppressions silencieuses ou incorrectes
- sécuriser les actions destructives
- garantir la fiabilité des opérations CRUD


###  Tests sur Expiration JWT

Ces tests valident la sécurité du système d’authentification.

**Cas à couvrir :**
- token expiré
- token invalide ou malformé
- accès refusé aux routes protégées

**Pourquoi c’est important :**
- empêcher les accès non autorisés
- respecter les bonnes pratiques de sécurité (OWASP)
- garantir la gestion correcte des sessions utilisateurs
