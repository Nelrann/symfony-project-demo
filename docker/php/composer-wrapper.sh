#!/bin/sh
set -e

# Sérialise tous les appels à Composer (entrypoint au démarrage + `docker compose
# exec php composer ...`). Deux Composer simultanés réécrivent vendor/ en parallèle
# et peuvent le corrompre (autoload incomplet, plugin symfony/flex cassé).
exec 9>/tmp/composer.lock
flock 9

exec /usr/local/bin/composer-real "$@"
