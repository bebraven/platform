#!/bin/zsh
echo "Refreshing your local dev database from the latest Heroku snapshot db"


docker-compose down
docker-compose up -d platformdb
sleep 5


echo "DROP SCHEMA public CASCADE;" | docker-compose exec -T platformdb psql -U user -d platform_development
echo "CREATE SCHEMA public;" | docker-compose exec -T platformdb psql -U user -d platform_development
docker-compose run platformweb bundle exec rake db:create
#cpucores=`cat /proc/cpuinfo | grep "cpu cores" | uniq | awk -F'cpu cores\t:' '{print $2}'`
#jobs=`expr $cpucores / 2`
docker-compose exec platformdb pg_restore --jobs 1 --no-acl --no-owner -U user -d platform_development /latest.dump

# This is our normal test password for everyone. I got this by loading a staging db with the security keys 
# and stuff we use, then setting someones password to the test one in the rails console.
ENCRYPTED_TEST_PASS='$2a$10$C2W0hszrbmpk8tkw0ViLFOXVFH1Sj6HAiMyGah6vdEoRUj7GK1KzO'
echo "UPDATE users SET encrypted_password = '$ENCRYPTED_TEST_PASS';" | docker-compose exec -T platformdb psql -U user platform_development
