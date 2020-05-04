#!/bin/sh
set -e

echo "Checking if the SALESFORCE ENV vars are setup"
if [ -z "$SALESFORCE_HOST" ] || \
   [ -z "$SALESFORCE_PLATFORM_CONSUMER_KEY" ] || \
   [ -z "$SALESFORCE_PLATFORM_CONSUMER_SECRET" ] || \
   [ -z "$SALESFORCE_PLATFORM_USERNAME" ] || \
   [ -z "$SALESFORCE_PLATFORM_PASSWORD" ] || \
   [ -z "$SALESFORCE_PLATFORM_SECURITY_TOKEN" ]; then
  echo ""
  echo "WARNING: The SALESFORCE ENV vars arent setup. If you need to work on anything that integrates with Salesforce, it won't work until you set them up."
  echo "See the README for how to set them up. E.g. SALESFORCE_PLATFORM_CONSUMER_KEY"
  echo ""
else
  echo "Ok!"
fi

# Take from here: https://nickjanetakis.com/blog/dealing-with-lock-files-when-using-ruby-node-and-elixir-with-docker
# To deal with problems when the Gemfile.lock changes in between runs of
# bundle install
built_lock_file="/tmp/Gemfile.lock"
current_lock_file="Gemfile.lock"

function cp_built_lock_file() {
    cp "${built_lock_file}" "${current_lock_file}"
}

if [ -f "${current_lock_file}" ]; then
    diff="$(diff "${built_lock_file}" "${current_lock_file}")"
    if [ "${diff}" != "" 2>/dev/null ]; then
        cp_built_lock_file
    fi
else
    cp_built_lock_file
fi

# Note: there are some issues with the listen gem and certain editors
# where gaurd won't detect changes made from the host machine on a Mac
# inside the container when the volume is mounted. For VIM, you need to add
#   set backupcopy=yes 
# in your .vimrc
# See: https://github.com/guard/listen/issues/434
# Also, if you force polling it will absolutely destroy your CPU.
echo "Starting the rails app using guard"
bundle exec guard -di

