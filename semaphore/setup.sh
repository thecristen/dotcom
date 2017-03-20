set -e
ELIXIR_VERSION=1.4.2
ERLANG_VERSION=19

mkdir -p $SEMAPHORE_CACHE_DIR/gems $SEMAPHORE_CACHE_DIR/npm $SEMAPHORE_CACHE_DIR/mix

# Turn off some high-memory apps
for service in cassandra elasticsearch mysql rabbitmq-server mongod docker memcached postgresql apache2 redis-server; do
    sudo service $service stop
done
killall Xvfb

# Add more swap memory. Default is ~200m, make it 1G
sudo swapoff -a
sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
sudo mkswap /swapfile
sudo swapon /swapfile

export MIX_HOME=$SEMAPHORE_CACHE_DIR/mix

. /home/runner/.kerl/installs/$ERLANG_VERSION/activate
if ! kiex use $ELIXIR_VERSION; then
    kiex install $ELIXIR_VERSION
    kiex use $ELIXIR_VERSION
fi

# install credo
curl -L -o ./credo.tar.gz https://github.com/rrrene/credo/archive/v0.7.0.tar.gz
tar xzf ./credo.tar.gz
cd credo-0.7.0
mix deps.get
mix archive.build
mix archive.install --force
cd ..

mix local.hex --force
mix local.rebar --force
MIX_ENV=test mix do deps.get, deps.compile
nvm use 6.2
rbenv local 2.4.0
GEM_SPEC=$SEMAPHORE_CACHE_DIR/gems gem install -g gem.deps.rb sass pronto pronto-credo pronto-eslint pronto-scss -N
# drop phantomjs/backstop/casper from the deps to install
sed -r -e 's/.*"(phantomjs-prebuilt|backstopjs|casperjs)".*//' -i'' apps/site/package.json
# set cache dir for node
npm config set cache $SEMAPHORE_CACHE_DIR/npm
NODEJS_ORG_MIRROR=$NVM_NODEJS_ORG_MIRROR npm run install --no-optional
npm run brunch:build
MIX_ENV=test mix compile --force
