#!/bin/zsh

cp .env.example .env
cp .env.database.example .env.database
docker-compose build
docker-compose up -d platformdb 
docker-compose up platformweb #this is a hack. it will exit with an error but needed for db:create
docker-compose run platformweb bundle exec rake db:create db:schema:load db:migrate db:seed
docker-compose down
docker-compose up -d


