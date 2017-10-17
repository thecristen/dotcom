#!/bin/bash
set -e -x

VERSION=$(grep -o 'version: .*"' apps/site/mix.exs  | grep -E -o '([0-9]+\.)+[0-9]+')
BUILD_ARTIFACT=site-build.zip
TEMP_DIR=tmp_unzip

unzip $BUILD_ARTIFACT -d $TEMP_DIR

aws s3 sync $TEMP_DIR/lib/site-$VERSION/priv/static/css s3://mbta-dotcom/css --size-only
aws s3 sync $TEMP_DIR/lib/site-$VERSION/priv/static/js s3://mbta-dotcom/js --size-only

rm -rf $TEMP_DIR
