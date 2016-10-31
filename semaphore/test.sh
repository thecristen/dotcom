set -e

mix test --cover
cd apps/site && npm test && cd -
