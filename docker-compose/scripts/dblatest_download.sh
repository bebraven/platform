#!/bin/zsh
echo "Downloading the latest Heroku database snapshot"

rm -rf latest.dump*
app=${1:-braven-platform}  # could be braven-platform-booster or braven-platform-highlander, also
heroku pg:backups:download --app $app
