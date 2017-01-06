#/usr/bin/env bash
set -e

export MIX_ENV=test
export MIX_HOME=$SEMAPHORE_CACHE_DIR

bash <(curl -s https://codecov.io/bash) -t $CODECOV_UPLOAD_TOKEN
pronto run -f github github_status -c origin/master || true
# check for unsed variables and such
mix compile --force --warnings-as-errors

npm run brunch:build && test -f apps/site/priv/static/css/app.css && test -f apps/site/priv/static/js/app.js

MIX_ENV=dev npm run dialyzer
