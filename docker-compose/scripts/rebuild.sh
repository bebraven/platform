#!/bin/bash
docker-compose down
docker volume rm platform_vendor-bundle
# If you have to go nuclear, run:
# docker-compose build --no-cache && docker-compose up -d
docker-compose up -d --force-recreate --build
