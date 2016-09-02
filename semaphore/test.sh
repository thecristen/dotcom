set -e

pronto run -f github -c origin/master || true
mix test
cd apps/site && npm test && cd -
