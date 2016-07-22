FROM elixir:1.3

WORKDIR /root

# Install Hex+Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Install node/npm
# Instructions from https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g brunch

# Install Sass
RUN apt-get install -y ruby-sass

# Clean up
RUN apt-get clean

ENV MIX_ENV=prod

ADD . .

WORKDIR /root/apps/site
RUN mix do deps.get, deps.compile && \
    npm install && \
    brunch build --production && \
    mix do compile, phoenix.digest, release --verbosity=verbose --no-confirm-missing
