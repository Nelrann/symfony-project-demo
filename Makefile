.PHONY: help build up down restart logs shell composer console cache-clear db-create migrate install tailwind tailwind-watch up-prod down-prod logs-prod

# Par défaut ce Makefile pilote le stack de DEV (docker-compose.yml seul).
# La prod ajoute l'overlay docker-compose.prod.yml (qui déclare `caddy`) et les
# secrets de .env.prod.local. Le déploiement complet reste ./deploy.sh.
# Les cibles *-prod sont explicites : un `docker compose down` limité au fichier
# de base ne connaîtrait pas Caddy (il resterait up et le réseau ne serait pas
# supprimé), et l'overlay exige .env.prod.local pour l'interpolation DB_PASSWORD.
PROD_COMPOSE = docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local
PROD_ENV_CHECK = test -f .env.prod.local || { echo "Erreur : .env.prod.local manquant (copier .env.prod.example et le remplir)"; exit 1; }

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Construit les images Docker
	docker compose build

up: ## Démarre les conteneurs en attendant les healthchecks (MySQL prêt avant de rendre la main)
	docker compose up -d --wait

down: ## Arrête et supprime les conteneurs (stack dev)
	docker compose down --remove-orphans

# --- Stack de production (overlay prod + Caddy) ---------------------------
# Ne pas utiliser `make up`/`make down` sur le serveur : ils ignorent Caddy.
# Pour un vrai déploiement, passer par ./deploy.sh (build, migrations, cache).

up-prod: ## Démarre le stack prod, Caddy inclus (sans build ni migrations)
	@$(PROD_ENV_CHECK)
	$(PROD_COMPOSE) up -d --wait --remove-orphans

down-prod: ## Arrête et supprime le stack prod, Caddy inclus
	@$(PROD_ENV_CHECK)
	$(PROD_COMPOSE) down --remove-orphans

logs-prod: ## Affiche les logs du stack prod, Caddy inclus
	@$(PROD_ENV_CHECK)
	$(PROD_COMPOSE) logs -f

restart: ## Redémarre les conteneurs
	docker compose restart

logs: ## Affiche les logs
	docker compose logs -f

shell: ## Ouvre un shell dans le conteneur PHP
	docker compose exec php sh

composer: ## Exécute une commande composer (ex: make composer c="require symfony/orm-pack")
	docker compose exec php composer $(c)

console: ## Exécute une commande Symfony console (ex: make console c="cache:clear")
	docker compose exec php php bin/console $(c)

cache-clear: ## Vide le cache Symfony
	docker compose exec php php bin/console cache:clear

db-create: ## Crée la base de données
	docker compose exec php php bin/console doctrine:database:create --if-not-exists

migrate: ## Exécute les migrations
	docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

tailwind: ## Compile les styles Tailwind
	docker compose exec php php bin/console tailwind:build

tailwind-watch: ## Recompile Tailwind à chaque modification
	docker compose exec php php bin/console tailwind:build --watch

install: ## Installation complète du projet
	docker compose up -d --build --wait
	docker compose exec php composer install
	docker compose exec php php bin/console tailwind:build
	docker compose exec php php bin/console doctrine:database:create --if-not-exists
	docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration
	@echo "Projet installé avec succès !"
	@echo "Application : http://localhost:8080"
	@echo "Mailhog     : http://localhost:8025"
