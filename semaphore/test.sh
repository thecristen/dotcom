set -e

mix coveralls.json
cd apps/site && npm test && cd -
