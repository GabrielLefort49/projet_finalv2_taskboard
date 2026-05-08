# TP - Deploiement local via SSH tunnel

## Comparaison des solutions de tunnel

| Solution | Gratuit | Fonctionnement | Installation | Compte | URL/port stable | Contraintes pour le TP |
| --- | --- | --- | --- | --- | --- | --- |
| ngrok | Oui, tier gratuit | Agent local qui ouvre un tunnel vers ngrok. HTTP simple, TCP possible selon les limites du plan. | Oui, binaire `ngrok`. | Oui. | Domaine dev assigne, pas de domaine personnalise gratuit. TCP limite. | Fiable, mais quotas mensuels gratuits : 1 Go sortant, 20 000 requetes HTTP, 5 000 connexions TCP, 3 endpoints en ligne. Interstitiel sur trafic navigateur HTML. |
| localhost.run | Oui | Reverse SSH avec `ssh -R`, sans client proprietaire. | Non, OpenSSH suffit. | Non pour tunnel gratuit, compte/cle pour domaine custom. | Gratuit instable apres quelques heures; stable via offre custom domain. | Tres simple pour exposer HTTP. Pour un SSH brut depuis GitHub Actions, la version gratuite est limitee car les tunnels publics sont orientes HTTP/TLS; verifier la faisabilite TCP avant validation. |
| Cloudflare Tunnel | Oui | `cloudflared` cree des connexions sortantes vers Cloudflare. | Oui, `cloudflared`. | Non pour Quick Tunnel; oui + domaine Cloudflare pour tunnel nomme/stable. | Quick Tunnel aleatoire; stable avec compte et domaine. | Tres fiable. Quick Tunnel est fait pour test, limite a 200 requetes concurrentes et pas de SSE. Les services non HTTP/SSH demandent souvent `cloudflared` cote client, donc moins direct pour un runner GitHub standard. |
| Pinggy | Oui | Reverse SSH vers Pinggy, support HTTP(S), TCP, UDP, TLS. | Non, OpenSSH suffit. | Non pour usage basique. | Gratuit aleatoire; stable en Pro. | Bon candidat pour SSH TCP en TP. Limite gratuite principale : session de 60 minutes et sous-domaines aleatoires. |
| serveo.net | Oui | Reverse SSH avec `ssh -R`. | Non, OpenSSH suffit. | Non pour HTTP; certaines fonctions TCP demandent inscription. | Sous-domaines gratuits, souvent deterministes mais pas garantis. | Simple et proche de localhost.run. Free plan : 3 tunnels actifs, interstitiel; le forwarding TCP public est indique comme reserve aux utilisateurs enregistres. |

Choix retenu pour ce depot : `localhost.run`, car il correspond a l'architecture demandee et ne necessite pas d'installation. En pratique, si le tunnel localhost.run gratuit ne permet pas une connexion SSH brute depuis GitHub Actions dans votre environnement, le remplacement le plus simple pour la validation est Pinggy en tunnel TCP, avec les memes secrets `DEPLOY_HOST` et `DEPLOY_PORT`.

Sources consultees : documentation ngrok Free Plan Limits, documentation localhost.run CLI/FAQ, documentation Cloudflare Tunnel, page tarifaire Pinggy, documentation Serveo.

## Authentification SSH

L'authentification par mot de passe est simple mais fragile pour un pipeline : elle expose un secret reutilisable, se prete aux attaques par force brute et s'automatise mal. L'authentification par cle est preferable : GitHub Actions possede la cle privee dans un secret, le serveur SSH ne connait que la cle publique dans `authorized_keys`.

Types de cles :

| Type | Avis |
| --- | --- |
| RSA 2048 | Ancien minimum acceptable, a eviter pour une nouvelle cle si Ed25519 est disponible. |
| RSA 4096 | Compatible partout, plus lourd, bon choix si un vieux serveur ne supporte pas Ed25519. |
| Ed25519 | Recommande ici : moderne, court, rapide, securise, bien supporte par OpenSSH. |

Bonnes pratiques appliquees :

- cle dediee au deploiement, differente de la cle personnelle;
- cle publique seule dans `deploy/authorized_keys`;
- cle privee stockee dans `DEPLOY_SSH_PRIVATE_KEY` cote GitHub, jamais committee;
- `.ssh/` ignore par Git;
- permissions strictes : `~/.ssh` en `700`, cle privee en `600`, `authorized_keys` en `600`;
- passphrase recommandee pour une cle humaine; pour GitHub Actions, une cle sans passphrase peut etre utilisee si elle est limitee a ce TP et facilement revocable.

Generation recommandee :

```bash
ssh-keygen -t ed25519 -C "taskboard-deploy" -f .ssh/deploy_key
```

Copier ensuite le contenu de `.ssh/deploy_key.pub` dans `deploy/authorized_keys`, puis le contenu de `.ssh/deploy_key` dans le secret GitHub `DEPLOY_SSH_PRIVATE_KEY`.

## Architecture locale

Le fichier `deploy/docker-compose.deploy.yml` lance un conteneur `ssh-server` expose sur le port local `2222`. Ce conteneur :

- accepte uniquement les connexions SSH par cle pour l'utilisateur `deployer`;
- monte `/var/run/docker.sock`;
- utilise le client Docker pour piloter les conteneurs sur la machine hote.

Attention securite : monter le socket Docker donne pratiquement les droits root sur l'hote. C'est acceptable pour un TP isole, mais il ne faut pas exposer ce serveur SSH en production sans restrictions fortes.

Demarrer l'environnement local :

```bash
docker compose -f deploy/docker-compose.deploy.yml up -d --build
```

Tester l'acces local :

```bash
ssh -i .ssh/deploy_key -p 2222 deployer@localhost docker ps
```

## Tunnel

Script fourni :

```bash
./deploy/start-tunnel.sh
```

Il ouvre un reverse tunnel vers le port local `2222`. Garder ce terminal ouvert pendant le deploiement.

Secrets GitHub a renseigner :

| Secret | Valeur |
| --- | --- |
| `DEPLOY_SSH_PRIVATE_KEY` | Cle privee `.ssh/deploy_key`. |
| `DEPLOY_HOST` | Hote public affiche par le tunnel. |
| `DEPLOY_PORT` | Port public du tunnel. |
| `JWT_SECRET` | Secret applicatif de production. |

## Script de deploiement

Le script `deploy/script.sh` est execute a distance par SSH. Il est idempotent :

- creation du reseau Docker si absent;
- creation ou redemarrage de la base PostgreSQL;
- pull de l'image GHCR du commit;
- suppression/remplacement du conteneur `taskboard-app`;
- exposition de l'application sur `http://localhost:3000`;
- healthcheck bloquant sur `http://localhost:3000/health`.

Si le healthcheck echoue, le script affiche les logs de l'application et sort avec un code non nul. Le job GitHub Actions echoue donc automatiquement.

## Pipeline

La pipeline contient maintenant :

```text
lint -> test -> docker-build -> deploy
```

Le deploiement :

- ne s'execute que sur un `push` vers `main`;
- ne s'execute pas sur les pull requests;
- depend du build Docker;
- utilise l'image `ghcr.io/<owner>/<repo>:<sha>`;
- echoue si le healthcheck post-deploiement echoue.

## Validation

1. Demarrer Docker Desktop.
2. Lancer le serveur SSH local :

```bash
docker compose -f deploy/docker-compose.deploy.yml up -d --build
```

3. Ouvrir le tunnel :

```bash
./deploy/start-tunnel.sh
```

4. Mettre a jour `DEPLOY_HOST` et `DEPLOY_PORT` dans les secrets GitHub selon la sortie du tunnel.
5. Pousser sur `main`.
6. Verifier :

```bash
curl http://localhost:3000/health
```

7. Relancer le job `deploy` : il doit reussir sans creer de doublons.
