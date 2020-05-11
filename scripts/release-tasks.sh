# Migrate
bundle exec rake db:migrate

# Send a Honeycomb marker
RELEASE_CREATED_AT=$(date +%s -ud ${HEROKU_RELEASE_CREATED_AT})
curl https://api.honeycomb.io/1/markers/${HONEYCOMB_DATASET} \
        -X POST \
        -H "X-Honeycomb-Team: ${HONEYCOMB_WRITE_KEY}" \
        -d '{"message":"'"${HEROKU_SLUG_DESCRIPTION}"'", "type":"deploy", "start_time": '"${RELEASE_CREATED_AT}"'}'
