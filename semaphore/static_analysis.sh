set -e

export MIX_ENV=test

pronto run -f github github_status -c origin/master || true
# check for unsed variables and such
mix compile --force --warnings-as-errors
