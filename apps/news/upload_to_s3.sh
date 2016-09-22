#!/usr/bin/env bash -e

# Uploads the recent posts to the S3 bucket.
# Required environment variables:
# * MBTA_SQL_SERVER
# * MBTA_SQL_USERNAME
# * MBTA_SQL_PASSWORD
# * MBTA_SQL_DATABASE
# * S3_BUCKET

# number of posts to include
POST_COUNT=10

./import_posts.py priv/posts
test -f posts.zip && rm -f posts.zip
find priv/posts | sort | tail -n $POST_COUNT | xargs zip -9j posts.zip
../../aws/bin/aws s3 cp posts.zip s3://$S3_BUCKET/posts.zip --acl=public-read
