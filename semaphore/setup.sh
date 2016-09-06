set -e

mix local.hex --force
MIX_ENV=test mix do deps.get --only test, deps.compile
nvm use 6.2
rbenv local 2.3
gem install sass pronto pronto-credo pronto-eslint
npm run install
npm run brunch:build
MIX_ENV=test mix compile --force
