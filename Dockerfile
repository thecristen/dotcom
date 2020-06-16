FROM elixir:1.10.3

WORKDIR /root

ARG SENTRY_DSN="" 

# Configure Git to use HTTPS in order to avoid issues with the internal MBTA network
RUN git config --global url.https://github.com/.insteadOf git://github.com/

# Install Hex+Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Install node/npm
# Instructions from https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get install -y nodejs

# Clean up
RUN apt-get clean

ENV MIX_ENV=prod

ADD . .

WORKDIR /root/apps/site/
RUN mix do deps.get, deps.compile

WORKDIR /root/apps/site/assets/
RUN npm install && npm run webpack:build -- --env.SENTRY_DSN=$SENTRY_DSN

WORKDIR /root/apps/site/react_renderer/
RUN npm install && npx webpack

WORKDIR /root/apps/site/
RUN mix phx.digest

WORKDIR /root
RUN mix release --verbose
