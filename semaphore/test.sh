set -e

cd apps/site && mix test --cover && cd -
mix test
cd apps/site && npm test && cd -
