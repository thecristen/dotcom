set -e
ELIXIR_VERSION=1.4.0
ERLANG_VERSION=19

export MIX_HOME=$SEMAPHORE_CACHE_DIR

. /home/runner/.kerl/installs/$ERLANG_VERSION/activate
if ! kiex use $ELIXIR_VERSION; then
    kiex install $ELIXIR_VERSION
    kiex use $ELIXIR_VERSION
fi

mix local.hex --force
mix local.rebar --force
MIX_ENV=test mix do deps.get, deps.compile
nvm use 6.2
rbenv local 2.3
GEM_SPEC=$SEMAPHORE_CACHE_DIR/gems gem install -g gem.deps.rb sass pronto pronto-credo pronto-eslint pronto-scss -N
NODEJS_ORG_MIRROR=$NVM_NODEJS_ORG_MIRROR npm run install
npm run brunch:build
MIX_ENV=test mix compile --force
