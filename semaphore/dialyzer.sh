#/usr/bin/env bash
set -e

mix compile --force --warnings-as-errors

# copy any pre-built PLTs to the right directory
find $SEMAPHORE_CACHE_DIR -name "dialyxir_*_deps-dev.plt*" | xargs -I{} cp '{}' _build/dev

export ERL_CRASH_DUMP=/dev/null
mix dialyzer --plt

# copy build PLTs back
cp _build/dev/*_deps-dev.plt* $SEMAPHORE_CACHE_DIR

/usr/bin/time -v mix dialyzer --halt-exit-status
