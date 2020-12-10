#!/bin/zsh

cp .env.example .env
app=${1:-braven-platform}
./docker-compose/scripts/dbrefresh.sh $app
./docker-compose/scripts/restart.sh
