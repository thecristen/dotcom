#!/bin/bash
set -ex
if [[ "$1" ]]; then
    DOMAIN=$1
    HOST=$1
    shift
else
    HOST=localhost
    DOMAIN="$HOST:4001"
fi
OUTPUT_DIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")
OUTPUT_FILE=$OUTPUT_DIR/wget_output
touch $OUTPUT_FILE
if time wget -D $HOST --spider --delete-after --timeout 30 -nv -e robots=off -r "http://$DOMAIN/" -o $OUTPUT_FILE "$@"; then
    rm -r $OUTPUT_DIR
    echo PASSED!
else
    grep -v 'URL:' $OUTPUT_FILE
    echo FAILED!
    exit 1
fi
