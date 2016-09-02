set -e

mix local.hex --force
mix deps.get
nvm use 6.2
rbenv local 2.3
gem install sass pronto pronto-credo pronto-eslint
cd apps/site && npm install && ./node_modules/brunch/bin/brunch build && cd -
