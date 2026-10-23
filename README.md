# Projet Symfony avec Docker

Application [Symfony](https://symfony.com) prête à l'emploi, exécutée entièrement dans Docker Compose : PHP-FPM, Nginx, MySQL, Tailwind CSS et Mailhog en développement, Caddy en production.

Ce dépôt sert également de **template réutilisable** pour démarrer un nouveau projet.

## Stack

| Composant | Version | Rôle |
|-----------|---------|------|
| PHP | 8.3-FPM | Exécution de l'application |
| Symfony | 7.4 | Framework |
| MySQL | 8.0 | Base de données |
| Nginx | alpine | Serveur web (reverse proxy PHP-FPM) |
| Caddy | 2 | Reverse proxy et HTTPS en production |
| AssetMapper + Tailwind CSS | Tailwind v4 | Assets et styles |
| Mailhog | latest | Capture des emails en développement |

## Prérequis

- [Docker](https://docs.docker.com/get-docker/) >= 24
- [Docker Compose](https://docs.docker.com/compose/install/) >= 2 (plugin `docker compose`)
- `make` et `git`

Aucune installation locale de PHP, Composer, MySQL ou Nginx n'est nécessaire.

Ports utilisés en développement : `8080` (HTTP), `3306` (MySQL), `1025` / `8025` (Mailhog SMTP / interface web).
En production, Caddy expose `8081` / `8443` par défaut (configurable).

## Démarrage rapide

```bash
git clone <url-du-depot> symfony-project
cd symfony-project
make install
```

`make install` enchaîne automatiquement :

1. le démarrage des conteneurs (`docker compose up -d --build --wait`) ;
2. l'installation des dépendances Composer ;
3. la compilation des styles Tailwind ;
4. la création de la base de données ;
5. l'exécution des migrations Doctrine.

La première exécution construit l'image PHP et télécharge les images nécessaires (quelques minutes).
`--wait` attend que le healthcheck MySQL passe : sans lui, `doctrine:database:create` peut échouer en `Connection refused` au premier démarrage (initialisation de MySQL ~20-40 s).

| Accès | URL |
|-------|-----|
| Application | http://localhost:8080 |
| Web Profiler (dev) | http://localhost:8080/_profiler |
| Mailhog (emails capturés) | http://localhost:8025 |

## Créer un projet depuis ce template

Ce dépôt est conçu pour servir de **base réutilisable**. Tout ce qui est spécifique à un projet vit dans des fichiers non committés (`.env.local`, `.env.prod.local`) ou dans `templates/`.

### 1. Sur GitHub : créer votre projet depuis le template

Sur la page principale de ce dépôt, cliquez sur le bouton vert **Use this template**
(ou l'URL directe : https://github.com/Nelrann/symfony-project/generate), puis :

   - *Owner* : votre compte ou votre organisation
   - *Repository name* : le nom du nouveau projet (ex. `mon-nouveau-projet`)
   - *Repository visibility* : Public ou Private selon l'usage
   - *Description* : facultatif
   - laisser **"Include all branches"** décoché
   - **Create repository from template**

Résultat : un nouveau dépôt à votre nom (`github.com/<votre_compte>/mon-nouveau-projet`), avec la stack complète, un historique git vierge, et aucun secret (`.env.prod.local` n'est pas versionné).

### 2. Cloner et installer

```bash
git clone git@github.com:<votre_compte>/mon-nouveau-projet.git
cd mon-nouveau-projet
cp .env.prod.example .env.prod.local # à remplir plus tard, pour le premier deploy
make install
```

Application dev : http://localhost:8080

### 3. Personnaliser (checklist par projet)

| Élément | Où | Pourquoi |
|---------|-----|----------|
| Branding page d'accueil | `templates/home/index.html.twig`, `assets/styles/app.css` | contenu/footer |
| `DOMAIN` | `.env.prod.local` | Caddy HTTPS + nom de l'image PHP (`${DOMAIN}-prod`) |
| `WEB_HTTP_PORT` / `WEB_HTTPS_PORT` | `.env.prod.local` | **uniques par serveur** (8081/8443 pour le 1er, 8082/8444… pour le suivant) |
| `APP_SECRET` | `.env.prod.local` | aléatoire et différent du template |
| `DB_NAME` / `DB_USER` / `DB_PASSWORD` | `.env.prod.local` | base dédiée au projet |
| DNS (enregistrement A) | registrar | pointe vers le serveur |

> Les noms de containers et d'images sont dérivés du **dossier du projet** et du `DOMAIN` : plusieurs déploiements de ce template peuvent cohabiter sur le même serveur tant que les ports diffèrent.

### 4. Multi-projets sur un même serveur

Chaque projet a son propre network Docker, ses propres volumes et ports. Le Caddy **edge** (celui qui écoute sur 80/443) doit router chaque domaine vers les ports HTTPS du projet correspondant — c'est lui qui choisit `8443` vs `8444`, etc.

## Services

| Service | Image / Build | Port hôte | Description |
|---------|---------------|-----------|-------------|
| `nginx` | `nginx:alpine` | `8080` | Serveur web (reverse proxy PHP-FPM) |
| `php` | build `docker/php` | `9000` (interne) | PHP 8.3-FPM + Composer |
| `db` | `mysql:8.0` | `3306` | Base de données MySQL |
| `mailhog` | `mailhog/mailhog` | `8025` / `1025` | Capture d'emails (UI / SMTP) |
| `caddy` | `caddy:2-alpine` | `8081` / `8443` | Uniquement en production |

## Commandes utiles (Makefile)

Un `Makefile` est fourni pour simplifier les opérations courantes. **Il pilote le stack de dev par défaut** (`docker-compose.yml` seul, sans Caddy) ; les cibles suffixées `-prod` chargent l'overlay production.

| Commande | Description |
|----------|-------------|
| `make help` | Liste toutes les commandes disponibles |
| `make install` | Installation complète (dépendances, Tailwind, BDD, migrations) |
| `make build` | Construit les images Docker |
| `make up` | Démarre les conteneurs en attendant les healthchecks |
| `make down` | Arrête et supprime les conteneurs (stack dev) |
| `make restart` | Redémarre les conteneurs |
| `make logs` | Affiche les logs en continu |
| `make shell` | Ouvre un shell dans le conteneur PHP |
| `make console c="cache:clear"` | Exécute une commande Symfony console |
| `make composer c="require symfony/..."` | Exécute une commande Composer |
| `make cache-clear` | Vide le cache Symfony |
| `make db-create` | Crée la base de données si nécessaire |
| `make migrate` | Exécute les migrations Doctrine |
| `make tailwind` | Compile les styles Tailwind |
| `make tailwind-watch` | Recompile Tailwind à chaque modification |
| `make up-prod` | Démarre le stack prod (Caddy inclus), sans build ni migrations |
| `make down-prod` | Arrête et supprime le stack prod (Caddy inclus) |
| `make logs-prod` | Affiche les logs du stack prod (Caddy inclus) |

> Sur le serveur, **n'utilisez pas `make down`** : `caddy` n'étant déclaré que dans `docker-compose.prod.yml`, le fichier de base ne le connaît pas et le conteneur Caddy resterait actif (avec échec de suppression du réseau). Utilisez `make down-prod`, ou `./deploy.sh` pour un déploiement complet.

Exemple :

```bash
make console c="make:controller HomeController"
make composer c="require symfony/serializer"
```

### Mettre à jour le projet

```bash
git pull
make install
```

`make install` est idempotent : il reconstruit les images si nécessaire, met à jour les dépendances, recompile Tailwind et applique les migrations en attente.

## Tailwind CSS

Les styles ne sont **pas compilés automatiquement**. Après une modification des templates ou de `assets/styles/app.css`, lancez :

```bash
make tailwind
# équivalent à :
docker compose exec php php bin/console tailwind:build
```

En développement, pour recompiler en continu à chaque changement :

```bash
make tailwind-watch
# équivalent à :
docker compose exec php php bin/console tailwind:build --watch
```

En production, `deploy.sh` lance `tailwind:build --minify`.

Le binaire Tailwind v4 est téléchargé automatiquement par le bundle et mis en cache dans `var/tailwind/` (ignoré par Git).

## Exemples de commandes

### Ouvrir un shell dans le conteneur PHP

```bash
docker compose exec php sh
# ou
make shell
```

### Exécuter une commande Symfony console

```bash
docker compose exec php php bin/console list
docker compose exec php php bin/console make:controller HomeController
docker compose exec php php bin/console make:entity Product
```

### Exécuter une commande Composer

```bash
docker compose exec php composer require symfony/serializer
docker compose exec php composer update
```

### Vider le cache

```bash
docker compose exec php php bin/console cache:clear
# ou
make cache-clear
```

### Créer et exécuter une migration Doctrine

```bash
docker compose exec php php bin/console make:migration
docker compose exec php php bin/console doctrine:migrations:migrate
```

## Variables d'environnement

Les variables de développement sont définies dans `.env` (surchargées par `.env.local`, ignoré par Git).

| Variable | Valeur par défaut (Docker) | Description |
|----------|----------------------------|-------------|
| `APP_ENV` | `dev` | Environnement Symfony |
| `APP_SECRET` | (dev uniquement) | Secret de l'application |
| `DATABASE_URL` | `mysql://symfony:symfony@db:3306/symfony?...` | Connexion à MySQL |
| `MAILER_DSN` | `smtp://mailhog:1025` | Envoi d'emails vers Mailhog |
| `DEFAULT_URI` | `http://localhost` | URI par défaut |

En production, les variables sont lues depuis `.env.prod.local` (non versionné) :

| Variable | Rôle |
|----------|------|
| `APP_SECRET` | Secret Symfony (obligatoire, différent du dev) |
| `DOMAIN` | Domaine public utilisé par Caddy |
| `WEB_HTTP_PORT` / `WEB_HTTPS_PORT` | Ports hôtes exposés par Caddy |
| `DB_NAME` / `DB_USER` / `DB_PASSWORD` | Base et utilisateur MySQL |
| `DB_ROOT_PASSWORD` | Mot de passe root MySQL |
| `DATABASE_URL` | Connexion Doctrine (surchargée par compose à partir des `DB_*`) |
| `MAILER_DSN` | Serveur SMTP réel |
| `DEFAULT_URI` | URL publique de l'application |

> En production, ne stockez jamais de secrets dans `.env` ni dans un fichier versionné. Utilisez `.env.prod.local` ou les secrets Symfony.

## Structure du projet

```
.
├── assets/                  # Sources JS/CSS (AssetMapper + Tailwind)
│   ├── app.js
│   └── styles/app.css
├── bin/console              # Console Symfony
├── config/                  # Configuration Symfony
├── docker/
│   ├── caddy/Caddyfile      # Reverse proxy + HTTPS (prod)
│   ├── nginx/               # Config Nginx (dev + prod)
│   └── php/                 # Dockerfiles, php.ini, entrypoint
├── migrations/              # Migrations Doctrine
├── public/                  # Point d'entrée web (index.php, assets compilés)
├── src/                     # Code source (controllers, entities, ...)
├── templates/               # Templates Twig
├── .env                     # Variables par défaut (dev)
├── .env.prod.example        # Template des secrets de production
├── deploy.sh                # Script de déploiement production
├── docker-compose.yml       # Stack de développement
├── docker-compose.prod.yml  # Surcharges production
├── importmap.php            # Entrées JavaScript (AssetMapper)
├── Makefile                 # Raccourcis de commandes
└── composer.json            # Dépendances PHP
```

Les dossiers `var/` (cache, logs, binaire Tailwind) et `vendor/` (dépendances Composer) sont générés et ignorés par Git.

## Arrêter / nettoyer

```bash
# Arrêter les conteneurs (conserve les données)
docker compose down

# Arrêter et supprimer les volumes (supprime la base de données)
docker compose down -v

# Reconstruire les images
docker compose build --no-cache
```

Réinitialisation complète en développement :

```bash
docker compose down -v
make install
```

## Dépannage

- **Port déjà utilisé** : modifiez les ports dans `docker-compose.yml` (ex. `8080:80`). En production, ajustez `WEB_HTTP_PORT` / `WEB_HTTPS_PORT`.
- **Les conteneurs ne démarrent pas** : consultez `docker compose ps` puis `docker compose logs -f php db nginx`.
- **`Connection refused` au premier démarrage** : MySQL est encore en cours d'initialisation. Attendez la fin du healthcheck (`docker compose up -d --wait`) puis relancez `make install` ou `make migrate`.
- **Erreur 502 Bad Gateway** : PHP-FPM n'est pas prêt ou `composer install` a échoué. Vérifiez `docker compose logs php`.
- **Permissions** : les fichiers sont créés avec l'utilisateur `www` (uid 1000). Si votre utilisateur hôte a un autre uid, ajustez l'uid/gid dans `docker/php/Dockerfile`.
- **Styles Tailwind absents** : lancez `make tailwind` (ou `make tailwind-watch` en développement).
- **Téléchargement du binaire Tailwind bloqué** : vérifiez l'accès réseau du conteneur et supprimez `var/tailwind/` avant de relancer `make tailwind`.
- **Cache Symfony** : en cas d'erreur inattendue, videz le cache avec `make cache-clear`.
- **Base de données inaccessible** : vérifiez que le conteneur `db` est démarré (`docker compose ps`) et que `DATABASE_URL` pointe bien vers l'hôte `db`.

## Déploiement en production

Une configuration de production est fournie via `docker-compose.prod.yml` et `docker/php/Dockerfile.prod`.

### Prérequis serveur

- Docker et Docker Compose v2 ;
- Git et accès au dépôt ;
- un enregistrement DNS `A` pointant vers le serveur ;
- les ports `WEB_HTTP_PORT` / `WEB_HTTPS_PORT` ouverts (par défaut `8081` / `8443`).

### 1. Préparer les secrets

Copiez le template et remplissez les valeurs :

```bash
cp .env.prod.example .env.prod.local
# Éditez .env.prod.local : APP_SECRET, DATABASE_URL, MAILER_DSN, DEFAULT_URI,
# DOMAIN, DB_PASSWORD, DB_ROOT_PASSWORD, WEB_HTTP_PORT, WEB_HTTPS_PORT
```

Générez un `APP_SECRET` fort :

```bash
openssl rand -hex 16
```

> `.env.prod.local` est injecté dans le conteneur `php` par `docker-compose.prod.yml` (`env_file`). Les variables `DB_*` y sont utilisées par Compose pour construire `DATABASE_URL`.

> ⚠️ Ne commitez jamais `.env.prod.local`.

### 2. Ports d'écoute

Si votre serveur a déjà des services sur `80` / `443`, Caddy peut écouter sur des ports hôtes différents :

```env
WEB_HTTP_PORT=8081
WEB_HTTPS_PORT=8443
```

La base MySQL n'est **pas exposée** sur le port hôte en production (accès uniquement via le réseau Docker interne). Mailhog est également désactivé par défaut.

### 3. Déployer

```bash
./deploy.sh
```

Le script effectue automatiquement :

1. le chargement de `.env.prod.local` ;
2. `git pull origin main` ;
3. le build des images de production (`--pull` : propagation des correctifs PHP/OS) ;
4. le démarrage des services (`--wait` sur les healthchecks) ;
5. l'exécution des migrations Doctrine ;
6. le build Tailwind (`--minify`) ;
7. le vidage et le réchauffage du cache prod ;
8. la compilation des assets dans `public/assets` (servis statiquement par Nginx) ;
9. le redémarrage de PHP-FPM et Nginx (purge OPcache/preload).

> `deploy.sh` déploie toujours la branche `main` du dépôt distant. Le serveur doit donc pouvoir faire un `git pull` sans conflit (pas de modifications locales).

Pour arrêter le stack de production (Caddy inclus), utilisez `make down-prod` — jamais `docker compose down` ni `make down`, qui ne connaissent pas `caddy` (déclaré uniquement dans l'overlay) et laissent donc le reverse proxy tourner.

### HTTPS et certificats

Par défaut, le `Caddyfile` utilise un **certificat interne** (`tls internal`) : il est auto-signé et destiné à un déploiement derrière un Caddy « edge » qui termine le HTTPS réel sur les ports 80/443.

- **Derrière un Caddy edge** (configuration par défaut) : laissez `tls internal`, et faites router le domaine par l'edge vers `WEB_HTTPS_PORT`.
- **Caddy exposé directement sur Internet** : retirez la ligne `tls internal` dans `docker/caddy/Caddyfile`, utilisez `WEB_HTTP_PORT=80` et `WEB_HTTPS_PORT=443`, et assurez-vous que le DNS pointe vers le serveur. Caddy obtiendra alors un certificat Let's Encrypt automatiquement.

> ⚠️ Let's Encrypt (HTTP-01 / TLS-ALPN) exige que les ports **80** et **443** soient joignables depuis Internet. Avec des ports non standard (ex. `8081` / `8443`), l'émission automatique ne fonctionnera pas sans configuration DNS-01.

### Logs et exploitation

Pour éviter de répéter les options de production :

```bash
DC="docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local"

$DC ps
$DC logs -f php nginx caddy
$DC exec php php bin/console about
```

### Sauvegarde / restauration MySQL

```bash
DC="docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local"

# Sauvegarde
$DC exec -T db sh -c 'mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' > backup.sql

# Restauration
$DC exec -T db sh -c 'mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' < backup.sql
```

### Rollback

`deploy.sh` faisant un `git pull` sur `main`, le rollback recommandé est de **reverter** le commit fautif sur `main`, puis de redéployer :

```bash
# Sur votre machine, puis push sur main
git revert <commit-fautif>
git push

# Sur le serveur
./deploy.sh
```

Les migrations de base de données ne sont pas annulées automatiquement : si la migration est destructive, restaurez la sauvegarde correspondante.

### Différences avec le dev

| Élément | Dev | Prod |
|---------|-----|------|
| Code source | Monté en volume | Baked dans l'image |
| `APP_ENV` | `dev` | `prod` |
| `APP_DEBUG` | `true` | `false` |
| Web Profiler | Activé | Désactivé |
| MakerBundle / DebugBundle | Installés | Non installés (`--no-dev`) |
| OPcache `validate_timestamps` | `1` | `0` (cache figé) |
| Mailhog | Activé | Désactivé (SMTP réel) |
| Nginx | Port `8080` | Derrière Caddy (ports hôtes configurables) |
| Caddy | Non installé | Reverse proxy + TLS (certificat interne par défaut) |
| Assets | Servis par AssetMapper | Compilés dans `public/assets` |

## Licence

Ce projet est fourni à titre d'exemple.
