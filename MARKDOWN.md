# Projet Taskboard
## Etape 1:

**Qu'est-ce qu'un secret dans le contexte d'une application web ?**
Dans le contexte d’une application web, un secret désigne toute information sensible nécessaire au bon fonctionnement et à la sécurité du système. Cela inclut par exemple les mots de passe, les clés API, les clés JWT ou encore les tokens d’authentification. Ces éléments permettent d’accéder à des services, de sécuriser des échanges ou d’authentifier des utilisateurs. Il est donc essentiel de garantir leur confidentialité afin d’éviter tout accès non autorisé.

**Pourquoi est-il dangereux de commiter des secrets même dans un dépôt privé ?**
Commiter des secrets dans un dépôt Git, même privé, représente un risque important. Tous les collaborateurs ayant accès au dépôt peuvent consulter ces informations. De plus, une erreur de configuration peut rendre le dépôt public, ou un compte développeur peut être compromis, exposant ainsi les données sensibles. Un autre problème majeur est que Git conserve l’historique complet des modifications : même si les secrets sont supprimés par la suite, ils restent accessibles dans les anciens commits.

**Comment détecter si des secrets ont déjà été leakés dans l'historique Git ?**
Pour détecter si des secrets ont été exposés, il est possible d’effectuer des recherches manuelles à l’aide de commandes comme `git log` ou `git grep`. Cependant, il est plus efficace d’utiliser des outils spécialisés tels que GitGuardian, TruffleHog ou Gitleaks, qui analysent automatiquement l’historique Git afin d’identifier des motifs correspondant à des données sensibles.

**Que se passe-t-il si vous supprimez le fichier `.env` mais que le commit initial est conservé dans l'historique ?**
Supprimer simplement le fichier `.env` ne suffit pas à sécuriser les informations si celui-ci a déjà été versionné. Le fichier reste accessible dans les anciens commits et peut être récupéré facilement. Les secrets doivent donc être considérés comme compromis. Il est alors nécessaire de réécrire l’historique Git pour les supprimer définitivement, puis de révoquer ces secrets et en générer de nouveaux afin de garantir à nouveau la sécurité de l’application.
