#!/bin/zsh
echo "Refreshing your local dev database"

app=${1:-braven-platform}
./docker-compose/scripts/dblatest_download.sh $app
./docker-compose/scripts/dblatest_restore.sh
