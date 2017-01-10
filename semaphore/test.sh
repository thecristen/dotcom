#!/usr/bin/env bash
set -e

MIX_ENV=test mix coveralls.json -u
cd apps/site && npm test && cd -
