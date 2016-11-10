#!/bin/bash
set -e -x
PREFIX=apps/site/
APP=site
BUILD_TAG=$APP:_build
VERSION=$(grep -o 'version: .*"' ${PREFIX}mix.exs  | grep -E -o '([0-9]+\.)+[0-9]+')
BUILD_ARTIFACT=$APP-build.zip

docker build -t $BUILD_TAG .
CONTAINER=$(docker run -d ${BUILD_TAG} sleep 2000)

rm -rf rel/$APP rel/$APP.tar.gz
docker cp $CONTAINER:/root/${PREFIX}rel/$APP/releases/$VERSION/$APP.tar.gz rel/$APP.tar.gz

docker kill $CONTAINER
tar -zxf rel/$APP.tar.gz -C rel/
rm rel/$APP.tar.gz

test -f $BUILD_ARTIFACT && rm $BUILD_ARTIFACT || true
pushd rel
zip -r ../$BUILD_ARTIFACT *
rm -fr bin erts* lib releases
popd
