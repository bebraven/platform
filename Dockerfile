# See https://github.com/ledermann/docker-rails/blob/develop/Dockerfile
FROM ruby:2.6.5-alpine

RUN apk add --update --no-cache \
    build-base \
    postgresql-dev \
    imagemagick \
    nodejs \
    yarn \
    tzdata \
    libnotify \
    git \
    python2 \
    vim

# Allow local builds to change it. Defaults to development.
ARG RAILS_ENV=development
ENV RAILS_ENV ${RAILS_ENV}
ENV NODE_ENV=${RAILS_ENV}

WORKDIR /app

ENV BUNDLE_PATH /gems

COPY Gemfile Gemfile.lock /app/
RUN bundle install && cp Gemfile.lock /tmp

COPY . /app/

CMD ["/bin/sh"]
