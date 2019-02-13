set -e
ELIXIR_VERSION=1.6.6
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

# retry setup if it fails
n=0
until [ $n -ge 3 ]; do
    MIX_ENV=test mix do local.hex --force, local.rebar --force, deps.get && break
    n=$[$n+1]
    sleep 3
done

nvm use 8.15.0
npm install -g npm@6.7.0
echo npm version is `npm -v`

# set cache dir for node
npm config set cache $SEMAPHORE_CACHE_DIR/npm
NODEJS_ORG_MIRROR=$NVM_NODEJS_ORG_MIRROR npm run ci-install --no-optional


rbenv local 2.4.1
# Setup scss
GEM_SPEC=$SEMAPHORE_CACHE_DIR/gems
gem install sass -v 3.4.23

npm run webpack:build
npm run react:setup
npm run react:build

MIX_ENV=test mix compile --warnings-as-errors --force

mix format --check-formatted
