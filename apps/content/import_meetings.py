#!/usr/bin/env python3
from __future__ import print_function
import random
import subprocess
import xml.etree.ElementTree as ET
import sys
import os
import os.path
from pathlib import Path
import json

SEPARATOR = b"------%i-----" % hash(random.random())
FETCH_SQL = b"""select convert(varchar(30), date_created, 120), content_id, content_html, "%s" from dbo.content where xml_config_id="28" and content_type != "3"
""" % SEPARATOR

try:
    POSTS_DIR = sys.argv[1]
except IndexError:
    print("Usage: %s <directory to put posts in>" % sys.argv[0])
    sys.exit(1)
else:
    Path(POSTS_DIR).mkdir(parents=True, exist_ok=True)

def news_entries():
    with open("/dev/null") as null:
        try:
            process = subprocess.run(["bsqldb", "-t", "\\n",
                                      "-S", os.environ['MBTA_SQL_SERVER'],
                                      "-U", os.environ['MBTA_SQL_USERNAME'],
                                      "-P", os.environ['MBTA_SQL_PASSWORD'],
                                      "-D", os.environ['MBTA_SQL_DATABASE']],
                                     input=FETCH_SQL,
                                     stderr=subprocess.PIPE,
                                     stdout=subprocess.PIPE,
                                     check=True)
        except subprocess.CalledProcessError as e:
            print("ERROR: while calling bsqldb")
            print(e.stderr.decode('utf8'))
            sys.exit(1)

        for row in process.stdout.split(SEPARATOR)[:-1]:
            [date, content_id, xml] = row.decode('utf8').split("\n", 3)[1:]

            yield {
                "date_created": date,
                "content_id": content_id,
                "content_html": xml
            }


def to_dict(tree):
    d = {}
    for child in tree:
        d[child.tag] = element_to_string(child)
    return d

def element_to_string(body):
    return (body.text or '') + \
        ''.join([ET.tostring(child).decode('utf8') for child in body.getchildren()])

def row_filename(row):
    [date, time] = row['date_created'].split(' ')
    return '%s-%s.json' % (date, row['content_id'])

def main():
    for row in news_entries():
        try:
            tree = ET.fromstring(row['content_html'])
        except ET.ParseError:
            continue

        filename = row_filename(row)

        d = to_dict(tree)
        d['meeting_id'] = row['content_id']
        with open(os.path.join(POSTS_DIR, filename), 'w') as post:
            json.dump(d, post)

if __name__ == "__main__":
    main()
