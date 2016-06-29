# News

Responsible for the news entries.


## `import_posts.py`

This script pulls the news entries out of the Ektron DB, and reformats them
into Jekyll-style Markdown files in a given directory.

### Environment:

The script expects 4 environment variables with the configuration for the Ektron DB:

* MBTA_SQL_SERVER
* MBTA_SQL_USERNAME
* MBTA_SQL_PASSWORD
* MBTA_SQL_DATABASE

### Usage:

    python3 import_posts.py priv/posts
