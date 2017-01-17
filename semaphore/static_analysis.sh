#/usr/bin/env bash
set -e

bash <(curl -s https://codecov.io/bash) -t $CODECOV_UPLOAD_TOKEN
pronto run -f github github_status -c origin/master || true
# check for unsed variables and such
mix compile --force --warnings-as-errors

# Make sure stativ build happened
test -f apps/site/priv/static/css/app.css && test -f apps/site/priv/static/js/app.js

npm run dialyzer
