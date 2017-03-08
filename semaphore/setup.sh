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
rbenv local 2.4.0
mkdir -p $SEMAPHORE_CACHE_DIR/gems $SEMAPHORE_CACHE_DIR/npm
GEM_SPEC=$SEMAPHORE_CACHE_DIR/gems gem install -g gem.deps.rb sass pronto pronto-credo pronto-eslint pronto-scss -N
# drop phantomjs/backstop/casper from the deps to install
sed -r -e 's/.*"(phantomjs-prebuilt|backstopjs|casperjs)".*//' -i'' apps/site/package.json
# set cache dir for node
npm config set cache $SEMAPHORE_CACHE_DIR/npm
NODEJS_ORG_MIRROR=$NVM_NODEJS_ORG_MIRROR npm run install --no-optional
npm run brunch:build
MIX_ENV=test mix compile --force
