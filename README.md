# Braven Platform

[![Codacy Health Badge](https://api.codacy.com/project/badge/Grade/f800f0c485164dacb4b493d8acfb19e6)](https://www.codacy.com/manual/bebraven/platform)
[![Codacy Coverage Badge](https://api.codacy.com/project/badge/Coverage/f800f0c485164dacb4b493d8acfb19e6)](https://www.codacy.com/manual/bebraven/platform)

This is the Braven Platform!

Add to this README please. It's easy to edit and see your changes locally using [grip](https://github.com/joeyespo/grip).

## Initial setup

First, we need to copy a couple of environment files in the app directory:

    cp .env.example .env
    cp .env.database.example .env.database

**Note: At the time of writing, the SSO login requires the Join server to be running locally at http://joinweb.** Look at the `server` config value in `config/rubycas.yml` for where that comes from. You can login with any user that
exists in the Join server's database and admins are anyone with an `@bebraven.org` email. See the section below on setting up the join server.

You don't really need to change the database passwords in these files, so we're doing this mainly to conform to "best
practices" for Rails apps in general. But if you do want to pick a different database password, make sure it matches in
both files.

Now fire up and build the docker environment. This will create/launch the Rails app, as well as a PostgreSQL database
server for the app to use:

    docker-compose up -d

This will take a while the first time, because Docker has to download a Ruby image and a PostgreSQL image and set them
up. It will also install all the necessary Ruby gems and JavaScript libraries the app requires.

Now create the needed databases:

    docker-compose exec platformweb bundle exec rake db:create db:schema:load db:migrate db:seed

We've configured Docker to run our Rails app on port 3020, so go to http://localhost:3020 in your favorite browser. If
everything's working correctly, you should be brought to the app's homepage.

Add a `127.0.0.1   platformweb` to your `/etc/hosts` file to access the Platform app via http://platformweb:3020.

You can also use [nginx-dev
container](https://github.com/beyond-z/nginx-dev) to access the app without specifying the port number.

### Join server

First, you'll need AWS credentials and to add them to your `~/.bash_profile`:

    export AWS_ACCESS_KEY_ID=<your_key>
    export AWS_SECRET_ACCESS_KEY=<your_secret>

Then, fork the [development](https://github.com/beyond-z/development) and [beyondz-platform](https://github.com/beyond-z/beyondz-platform) repositories from the [beyondz project](https://github.com/beyond-z).

Clone the repositories, with `beyondz-platform` under `development`:

    git clone https://github.com/[your_username]/development.git development
    cd development/
    git clone https://github.com/[your_username]/beyondz-platform.git beyondz-platform

Now build the Docker environment:

    cd beyondz-platform/
    docker-compose up -d

And set up the database in your Join server's dev environment:

    docker-compose exec joinweb bundle exec rake db:create && ./docker-compose/scripts/dbrefresh.sh

(These commands are from `development/setup.sh`. Search for `$join_src_path` to see what it's doing.)

Add `127.0.0.1   joinserver` to your `/etc/hosts` and access via http://platformweb:3020/.

### Salesforce

If you need to work on anything that hits the Salesforce API, you'll need to setup the following
environment variables in your `~/.bash_profile`.
[Here is an article](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/quickstart_oauth.htm) to help you through the below steps.


    export SALESFORCE_PLATFORM_CONSUMER_KEY=<the_key>
    export SALESFORCE_PLATFORM_CONSUMER_SECRET=<the_secret>
    export SALESFORCE_PLATFORM_USERNAME=<the_username>
    export SALESFORCE_PLATFORM_PASSWORD=<the_password>
    export SALESFORCE_PLATFORM_SECURITY_TOKEN=<the_security_token>

The values to use come from the Connected App in the Salesforce environment you are working against and
for the user that setup that connected app. To create them in a given Salesforce environment (prod, staging, dev)
first ask someone to create a Salesforce account for you (or get the admin account). 

1. Login and go to Setup (the little gear in the top right)
2. In the Quick Find type "App Manager". 
3. Under App Manager, you can create a "New Connected App" in the top right.
4. Enable OAuth settings, put in anything for the callback URL (since we don't currently use it), and give it Full Access scope.

*Tip*: If you want to get the key/secret for an existing app click on the little dropdown arrow to the right of it and choose "View".

**Important Note**: whenever you change the password for the account that created the connected app, a new security token
will be emailed to that user in an email titled "Your new Salesforce security token".

### Dummy Data

In dev or staging environments, we may want a few users, etc to work with. Unlike the seed data above,
this data is NOT meant for production. Therefore, it has a separate source file (db/dummies.rb) and rake task:

    rake db:dummies

This currently generates a number of users. It uses our the factories from our test suite,
which have been updated to show more variety in names and emails.

## Making changes

The app should automatically pick up any changes you make and live-reload in your browser. If for some reason you need
to rebuild the container (e.g. you added a `gem` dependency), you can do so in two ways - with or without the docker
cache.

With cache (recommended):

    docker-compose down
    docker-compose build

Without cache (slow! usually not necessary):

    docker-compose down -v --rmi all --remove-orphans  # deletes all container data!
    docker-compose build --force-rm --no-cache

In rare cases, you may need to bypass docker-compose and use docker directly to remove all volumes:

    docker volume rm platform_db-platform

If you change JavaScript dependencies, you need to restart the container, so yarn runs:

    docker-compose down

In all cases, to bring the container back up after a rebuild, run:

    docker-compose up -d

**Note:** there is a bug where on a Mac if you edit a file on the host machine (as opposed to inside the container)
then live reloading doesn't work. To fix this for vim, add the following to your .vimrc to make it work:

    set backupcopy=yes

See [this](https://github.com/guard/listen/issues/434) for more info and a link talking about other editors and
how they interact with gaurd.

### Testing

You can run all tests like this:

    docker-compose exec platformweb bundle exec rspec

Or only tests in a particular directory, like our feature tests which use Selenium to click around in the browser:

    docker-compose exec platformweb bundle exec rspec spec/feature

You can also run a single spec ofc.

### Project structure

This app is built with React and Rails. Generally speaking, developers will spend the most time in the Rails code
(models, views, controllers, and libs/helpers) and React components; designers will spend the most time in the React
components (HTML/JS/JSX) and CSS.

Rails views (ERB; these load the React components and handle backend API pages):

    app/views/layouts/application.html.erb
    app/views/*.erb

Rails models (database):

    app/models/*.rb

Rails controllers (business logic):

    app/controllers/*.rb

Rails routes:

    config/routes.rb

React components (JS/JSX/HTML):

    app/javascript/components/*/

React entrypoint (load and initialize JS dependencies):

    app/javascript/packs/platform.js

Stylesheets (CSS/SCSS):

    app/assets/stylesheets/*

Tests:

    spec/*

### Adding new code

Rails has generators that let you add new code more easily by automatically creating the scaffolding
for the particular type of thing you are adding. Rails has a bunch of default generators you can use.
For example, to create a new model you can do:

    rails generate scaffold User name:string

which will create the model, migration, routes, views, controllers, tests, etc.

However, the default ones create a lot of cruft and things we don't use. Also, we can enforce our
project structure and make it easier to get any boilerplate in that matches how we've set things up
by creating our own generators. See [here](https://guides.rubyonrails.org/generators.html) for more info.

**TODO:** We have one custom generator that let's us take a model that we've defined and add scaffolding
that matches how the data-central project was structured. See [USAGE here](lib/generators/dscaffold/USAGE)
It is out of date and we're in the early stages of designing how the Braven Platform code will be structured
and work together. Update it and add more generators that make it easy to add code properly to our codebase.

### Email
In all environments other than production, we need to be careful not to email actual users. The following
environment variable ensures that

    MAILER_DELIVERY_OVERRIDE_ADDRESS=someaddress@example.com

When creating new outgoing emails, it's convenient to preview them as you work on them. See the following for
how we've [enabled previews](http://platformwe/rails/mailers/braven_devise_mailer) for the account creation
email flows:

    spec/mailers/previews/braven_devise_mailer_preview.rb

**TODO** talk about SMTP settings and what to do in the dev environment if you want real emails to go out so you
can view them in your email client.

### Troubleshooting

If something isn't working, you can watch the docker logs live with:

    docker-compose logs -f

Or search through them with e.g.:

    docker-compose logs | grep "ERROR_I_WANT_TO_SEE"

We also have the [web-console gem](https://github.com/rails/web-console)
in the dev env so that when you get an error page in the browser, it includes an interactive ruby console at the bottom
so that you can inspect the variables or run code. E.g. Type `instance_variables` or `local_variables` to see a list.
Or, for example you can inspect one such as the `@current_user` by writing `instance_variable_get(:@current_user)`

We also have the pry and rescue gems so that you can break and debug code. Here is an example for how to debug
a spec that is throwing an exception.

    bundle exec rescue rspec spec/a_failing_spec.rb --format documentation   

See [this FANTASTIC article](https://supergood.software/a-ruby-gem-debugging-strategy/) for some general advice around
debugging and troubleshooting things if you're new to RoR development.

Of specific note, if you need to debug the code inside a gem, our gems are installed
at `vendor/bundle` inside the container. If you attach to the container you can dig down in there and add a 
some logging inside the gem code. You have to restart the container for the change to be picked up and if you 
make a mess of things and want to blow it away you need to remove the vendor-bundle volume using:

    docker volume rm platform_vendor-bundle

**NOTE:** pry doesn't currently work with our setup. Need to figure that out.

For troubleshooting ckeditor-specific issues in the content editor, append '?debug' to the URL:

    http://platformweb/course_contents/new?debug

That will attach the [CKEditor Inspector](https://ckeditor.com/docs/ckeditor5/latest/framework/guides/development-tools.html#ckeditor-5-inspector).

### Development environment setup

If when you're running `docker-compose up -d` and running into "file not found"/"no such file/directory" errors, it could be a `LF/CRLF` issue that will cause the scripts to execute, for example, `/bin/bash^M`.

This is caused by `autocrlf=true` in your Git configuration.

Try re-cloning your repository with the flag:

    --config core.autocrlf=input

so it uses whatever exists in the repository instead of having Git control it.

You can also add the following to your `~/.gitconfig` and `./.git/config`or:

    [core]
        autocrlf = input

### Updating dependencies

To update Ruby dependencies, run:

    bundle update

To update JavaScript dependencies, run:

    yarn upgrade-interactive --latest

CKEditor updates tend to have major breaking changes often, so be sure to test and make sure everything still works.

Once the dependencies are updated, you will need to rebuild your container:

    docker-compose build

### Accessibility testing

This project includes [axe](https://www.deque.com/axe/) in development, for live, in-browser accessibility reporting.
Open your browser's console to view axe reports.
