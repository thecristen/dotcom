set -e

export MIX_HOME=$SEMAPHORE_CACHE_DIR

. /home/runner/.kerl/installs/19.1/activate
kiex install 1.4.0
kiex use 1.4.0

mix local.hex --force
mix local.rebar --force
MIX_ENV=test mix do deps.get, deps.compile
nvm use 6.2
rbenv local 2.3
GEM_SPEC=$SEMAPHORE_CACHE_DIR/gems gem install sass pronto pronto-credo pronto-eslint pronto-scss -N
NODEJS_ORG_MIRROR=$NVM_NODEJS_ORG_MIRROR npm run install
npm run brunch:build
MIX_ENV=test mix compile --force
