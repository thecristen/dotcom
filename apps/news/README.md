# News

Responsible for the news entries.

## Updating S3 with the most recent news entries from the Ektron DB

First, ensure you have all the dependencies:

* `python3` version 3.6 (3.4 is known to not work)
* AWS access keys with permissions to write to the S3 bucket (can obtain from Paul, Gabe, or Dave Maltzan).
* `aws` command line tool ([instructions here](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)). Configure with above access keys.
* `bsqldb`, a part of FreeTDS (`brew install freetds`)

You will need the following 5 environment variables before running the import script:

* MBTA_SQL_SERVER
* MBTA_SQL_USERNAME
* MBTA_SQL_PASSWORD
* MBTA_SQL_DATABASE
* S3_BUCKET

The Ektron database is only accessible from within the MBTA network, so this script must be run while hardwired (not WiFi) in the office.

You should then be able to run the `upload_to_s3.sh` script from the `dotcom/apps/news/` directory, which will download the news entries from the Ektron DB, format them for the web, select the most recent ones, bundle them into a `zip` file, and then upload the zip file to the S3 bucket.

The site will update the news within 3 hours, but you can immediately check that the script worked by downloading [the zip file from S3](https://s3.amazonaws.com/mbta-gtfs-s3/posts.zip), and ensuring the correct, recent news entries are in it.
