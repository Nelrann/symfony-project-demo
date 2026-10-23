#!/bin/sh
set -e

# Développement uniquement : l'arbre est monté en bind-mount (./:/var/www/html),
# donc vendor/ n'existe pas dans un checkout fraîchement cloné — il n'est PAS
# écrit dans le RUN du Dockerfile (le bind l'aurait écrasé au démarrage).
if [ ! -f vendor/autoload_runtime.php ]; then
    echo "==> vendor/ absent du bind-mount : composer install..."
    composer install --no-interaction --prefer-dist
fi

exec "$@"
