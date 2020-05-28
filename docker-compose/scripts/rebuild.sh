#!/bin/bash
docker-compose down
docker volume rm platform_vendor-bundle
docker-compose up -d --force-recreate --build
