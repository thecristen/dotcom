#!/usr/bin/env bash -e

# Uploads the recent posts to the S3 bucket.
# Required environment variables:
# * MBTA_SQL_SERVER
# * MBTA_SQL_USERNAME
# * MBTA_SQL_PASSWORD
# * MBTA_SQL_DATABASE
# * S3_BUCKET

./import_posts.py priv/posts
test -f posts.zip && rm -f posts.zip
zip -9j posts.zip priv/posts/201{6,7,8,9}-*
../../aws/bin/aws s3 cp posts.zip s3://$S3_BUCKET/posts.zip --acl=public-read
