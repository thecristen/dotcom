#/usr/bin/env bash
set -e

bash <(curl -s https://codecov.io/bash) -t $CODECOV_UPLOAD_TOKEN
MIX_ENV=test pronto run -f github github_status -c origin/master || true

# check for unsed variables and such
mix compile --force --warnings-as-errors

# Make sure static build happened
test -f apps/site/priv/static/css/app.css && test -f apps/site/priv/static/js/app.js

# copy any pre-built PLTs to the right directory
find $SEMAPHORE_CACHE_DIR -name "dialyxir_*elixir-${ELIXIR_VERSION}_deps-dev.plt*" | xargs -I{} cp '{}' _build/dev

export ERL_CRASH_DUMP=/dev/null
mix dialyzer --plt

# copy build PLTs back
cp _build/dev/*_deps-dev.plt* $SEMAPHORE_CACHE_DIR

mix dialyzer --halt-exit-status
