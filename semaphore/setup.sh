set -e
ELIXIR_VERSION=1.4
ERLANG_VERSION=20

mkdir -p $SEMAPHORE_CACHE_DIR/gems $SEMAPHORE_CACHE_DIR/npm $SEMAPHORE_CACHE_DIR/mix

SERVICES="cassandra elasticsearch mysql mongod docker memcached postgresql apache2 redis-server"
if ! grep 1706 /etc/hostname > /dev/null; then
    # Platform version 1706 has a bug with stopping RabbitMQ.  If we're not
    # on that version, we can stop that service.
    SERVICES="rabbitmq-server $SERVICES"
fi
# Turn off some high-memory apps
for service in $SERVICES; do
    sudo service $service stop
done
killall Xvfb

# Add more swap memory. Default is ~200m, make it 2G
sudo swapoff -a
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo mkswap /swapfile
sudo swapon /swapfile

export MIX_HOME=$SEMAPHORE_CACHE_DIR/mix

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

GEM_SPEC=$SEMAPHORE_CACHE_DIR/gems gem install -g gem.deps.rb sass pronto pronto-eslint pronto-scss -N
# install custom pronto-credo
if test -d $SEMAPHORE_CACHE_DIR/gems/pronto-credo; then
    pushd $SEMAPHORE_CACHE_DIR/gems/pronto-credo
else
    pushd $SEMAPHORE_CACHE_DIR/gems
    git clone https://github.com/paulswartz/pronto-credo.git
    cd pronto-credo
fi
git checkout no-full-path
gem build pronto-credo.gemspec
gem install pronto-credo*.gem
popd

# drop phantomjs/backstop/casper from the deps to install
sed -r -e 's/.*"(phantomjs-prebuilt|backstopjs|casperjs)".*//' -i'' apps/site/package.json
# set cache dir for node
npm config set cache $SEMAPHORE_CACHE_DIR/npm
NODEJS_ORG_MIRROR=$NVM_NODEJS_ORG_MIRROR npm run install --no-optional
npm run brunch:build
MIX_ENV=test mix compile --warnings-as-errors --force
