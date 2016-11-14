set -e

MIX_ENV=test mix coveralls.json
cd apps/site && npm test && cd -
