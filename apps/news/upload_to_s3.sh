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

../../aws/bin/aws s3 cp posts.zip s3://$S3_BUCKET/posts.zip --acl=public-read
