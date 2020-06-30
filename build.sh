#!/bin/bash
set -e -x
PREFIX=_build/prod/
APP=site
BUILD_TAG=$APP:_build
VERSION=$(grep -o 'version: .*"' apps/$APP/mix.exs  | grep -E -o '([0-9]+\.)+[0-9]+')
BUILD_ARTIFACT=$APP-build.zip

docker build -t $BUILD_TAG --build-arg SENTRY_DSN=$SENTRY_DSN .
CONTAINER=$(docker run -d ${BUILD_TAG} sleep 2000)

rm -rf rel/$APP rel/app.js
docker cp $CONTAINER:/root/${PREFIX}rel/$APP/. rel/
docker cp $CONTAINER:/root/apps/site/react_renderer/dist/app.js rel/app.js

docker kill $CONTAINER

test -f $BUILD_ARTIFACT && rm $BUILD_ARTIFACT || true
pushd rel
zip -r ../$BUILD_ARTIFACT * .ebextensions
rm -fr bin erts* lib releases
popd
