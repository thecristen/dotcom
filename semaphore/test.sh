set -e

mix test
cd apps/site && npm test && cd -
