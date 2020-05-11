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
    diffcmd="diff $built_lock_file $current_lock_file"
    diff=$diffcmd
    if [ "${diff}" != "" 2>/dev/null ]; then
        cp_built_lock_file
    fi
else
    cp_built_lock_file
fi

# Run yarn. Must be BEFORE any rake/rails calls.
yarn install --check-files

# Migrate the db, if needed.
bundle exec rake db:migrate

# Fix "inotify event queue has overflowed."
# https://github.com/guard/listen/wiki/Increasing-the-amount-of-inotify-watchers
sysctl fs.inotify.max_user_watches=524288
sysctl fs.inotify.max_queued_events=524288
sysctl fs.inotify.max_user_instances=524288

if [[ "${RAILS_ENV:-'development'}" == 'development' ]]; then
  # Note: there are some issues with the listen gem and certain editors
  # where gaurd won't detect changes made from the host machine on a Mac
  # inside the container when the volume is mounted. For VIM, you need to add
  #   set backupcopy=yes 
  # in your .vimrc
  # See: https://github.com/guard/listen/issues/434
  # Also, if you force polling it will absolutely destroy your CPU.
  echo "Starting the rails app using guard"
  bundle exec guard -di
else

  echo "Precompiling assets in production mode"
  bundle exec rake assets:precompile

  # Puma expect this folder to already exist and don't create 
  mkdir -p /app/tmp/pids/

  echo "Starting the rails app using puma"
  bundle exec puma -C config/puma.rb
fi
