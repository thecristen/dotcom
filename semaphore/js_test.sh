#/usr/bin/env bash
set -e

# run javascript  tests
cd apps/site && npm test && cd -
