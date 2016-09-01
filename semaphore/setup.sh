set -e

mix local.hex --force
nvm use 6.2
rbenv local 2.3
gem install sass pronto pronto-credo pronto-eslint
cd apps/site && npm install && ./node_modules/brunch/bin/brunch build && cd -
MIX_ENV=test mix do deps.get --only test, deps.compile, compile
