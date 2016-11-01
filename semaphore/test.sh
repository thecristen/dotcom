set -e

MIX_ENV=test mix coveralls
cd apps/site && npm test && cd -
