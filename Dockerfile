# See https://github.com/ledermann/docker-rails/blob/develop/Dockerfile
FROM ruby:2.6.5-alpine

RUN apk add --update --no-cache \
    build-base \
    postgresql-dev \
    git \
    imagemagick \
    nodejs \
    yarn \
    tzdata

COPY Gemfile* /usr/src/app/
WORKDIR /usr/src/app

ENV BUNDLE_PATH /gems

RUN bundle install
COPY . /usr/src/app/
RUN yarn install --check-files

CMD ["bundle", "exec", "rails", "s", "-p", "3020", "-b", "0.0.0.0"]
