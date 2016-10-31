#!/bin/sh
if [[ "$1" ]]; then
    DOMAIN=$1
else
    DOMAIN="localhost:4001"
fi
if time wget -D $DOMAIN --delete-after -nv -t 1 -e robots=off -r http://$DOMAIN/ -o - | grep --before-context=1 " ERROR "; then
    echo FAILED!
    exit 1
else
    echo PASSED!
fi
