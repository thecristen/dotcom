#!/usr/bin/env bash
set -e

ERLANG_VERSION=22.3.3
ELIXIR_VERSION=1.10.3

export ERL_HOME="${SEMAPHORE_CACHE_DIR}/.kerl/installs/${ERLANG_VERSION}"
if [ ! -d "${ERL_HOME}" ]; then
    mkdir -p "${ERL_HOME}"
    KERL_BUILD_BACKEND=git kerl build $ERLANG_VERSION $ERLANG_VERSION
    kerl install $ERLANG_VERSION $ERL_HOME
fi
. $ERL_HOME/activate

kiex use $ELIXIR_VERSION || kiex install $ELIXIR_VERSION && kiex use $ELIXIR_VERSION

# Turn off some high-memory services
SERVICES="apache2 cassandra docker elasticsearch memcached mongod mysql \
postgresql sphinxsearch rabbitmq-server redis-server"
for service in $SERVICES; do sudo service "$service" stop; done
killall Xvfb

# Free up some disk space since we use a lot of swap and our repo is huge
# (per Semaphore support, this should fix issues with the cache not persisting)
sudo tune2fs -m 1 /dev/dm-0
rm -rf ~/.kiex ~/.lein ~/.kerl ~/.phpbrew ~/.sbt

# Add more swap space (~200MB => 2GB)
sudo swapoff -a
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo mkswap /swapfile
sudo swapon /swapfile

# Ensure cache directories exist
CACHE=$SEMAPHORE_CACHE_DIR
mkdir -p "$CACHE/asdf/installs" "$CACHE/mix/deps" "$CACHE/npm"

export MIX_ENV=test
export MIX_DEPS_PATH=$CACHE/mix/deps

# Install asdf and link cached languages
ASDF_GIT=https://github.com/asdf-vm/asdf.git
git clone $ASDF_GIT ~/.asdf --branch v0.7.6
ln -s "$CACHE/asdf/installs" ~/.asdf/installs
source ~/.asdf/asdf.sh

# Add asdf plugins and install languages
asdf plugin-add erlang
asdf plugin-add elixir
asdf plugin-add nodejs
~/.asdf/plugins/nodejs/bin/import-release-team-keyring
asdf install
asdf reshim # Needed to pick up languages that were already installed in cache

# Fetch Elixir dependencies
#   Note: Must be done before NPM, since some NPM packages are installed from
#   files inside Elixir packages
mix local.hex --force
mix local.rebar --force
mix deps.get

# Fetch Node dependencies
#   Note: Must be done before compiling Elixir apps, since some Elixir macros
#   require frontend assets to be present at compile time
npm config set cache "$CACHE/npm"
npm run install:ci
npm run react:setup:ci
