FROM elixir:1.2.5

WORKDIR /root

# Install Hex+Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Install node/npm
# Instructions from https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install -y nodejs && npm install -g brunch

ENV MIX_ENV=prod

ADD . .

WORKDIR /root/apps/site
RUN mix do deps.get, deps.compile && \
    npm install && \
    brunch build --production && \
    mix do compile, phoenix.digest, release --verbosity=verbose --no-confirm-missing
