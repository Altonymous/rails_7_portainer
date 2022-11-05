FROM ruby:3.1.2-slim

RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    libpq-dev \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3 \
  RAILS_ENV=production \
  SECRET_KEY_BASE=c447d106a0029c1ffb60b0857bb9e752c63014b2caca89809431c4943bf309b4fd609decc01502253a9f67948f1b7db58b5d3010b4c6f838c17be74b8950782a

RUN gem update --system && gem install bundler

WORKDIR /usr/src/app

COPY Gemfile* ./

RUN bundle config frozen true \
 && bundle config jobs 4 \
 && bundle config deployment true \
 && bundle config without 'development test' \
 && bundle install

COPY . .

# Precompile assets
# SECRET_KEY_BASE or RAILS_MASTER_KEY is required in production, but we don't
# want real secrets in the image or image history. The real secret is passed in
# at run time
ARG SECRET_KEY_BASE=fakekeyforassets
RUN bin/rails assets:clobber && bundle exec rails assets:precompile

# Run database migrations when deploying to Render. It is not great, maybe there's a better way?
# https://community.render.com/t/release-command-for-db-migrations/247/6
ARG RENDER
ARG DATABASE_URL
RUN if [ -z "$RENDER" ]; then echo "var is unset"; else bin/rails db:migrate; fi

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
