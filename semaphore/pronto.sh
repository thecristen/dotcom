#/usr/bin/env bash
set -e

gem install pronto -v 0.7.1
gem install pronto-eslint -v 0.7.0
gem install pronto-scss -v 0.7.0

# install custom pronto-credo
if test -d $SEMAPHORE_CACHE_DIR/gems/pronto-credo; then
    pushd $SEMAPHORE_CACHE_DIR/gems/pronto-credo
else
    pushd $SEMAPHORE_CACHE_DIR/gems
    git clone https://github.com/paulswartz/pronto-credo.git
    cd pronto-credo
fi
git checkout no-full-path
gem build pronto-credo.gemspec
gem install pronto-credo*.gem
popd

# run pronto
MIX_ENV=test pronto run -f github github_status -c origin/master

# Make sure static build happened
test -f apps/site/priv/static/css/app.css && test -f apps/site/priv/static/js/app.js
