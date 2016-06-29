#!/usr/bin/env python3
from __future__ import print_function
import random
import subprocess
import xml.etree.ElementTree as ET
import sys
import os
import os.path

SEPARATOR = b"------%i-----" % hash(random.random())
FETCH_SQL = b"""select convert(varchar(30), date_created, 120), content_id, content_html, "%s" from dbo.content where xml_config_id="60"
""" % SEPARATOR

try:
    POSTS_DIR = sys.argv[1]
except IndexError:
    print("Usage: %s <directory to put posts in>" % sys.argv[0])
    sys.exit(1)

def news_entries():
    with open("/dev/null") as null:
        process = subprocess.run(["bsqldb", "-t", "\\n",
                                  "-S", os.environ['MBTA_SQL_SERVER'],
                                  "-U", os.environ['MBTA_SQL_USERNAME'],
                                  "-P", os.environ['MBTA_SQL_PASSWORD'],
                                  "-D", os.environ['MBTA_SQL_DATABASE']],
                                 input=FETCH_SQL,
                                 stderr=null,
                                 stdout=subprocess.PIPE,
                                 check=True)
        for row in process.stdout.split(SEPARATOR)[:-1]:
            [date, content_id, xml] = row.decode('utf8').split("\n", 3)[1:]

            yield {
                "date_created": date,
                "content_id": content_id,
                "content_html": xml
            }


def to_dict(tree, filter_=True):
    d = {}
    for child in tree:
        d[child.tag] = element_to_string(child)
    return d

def element_to_string(body):
    return (body.text or '') + \
        ''.join([ET.tostring(child).decode('utf8') for child in body.getchildren()])

def row_filename(row):
    [date, time] = row['date_created'].split(' ')
    return '%s-%s.md' % (date, row['content_id'])

def main():
    for row in news_entries():
        try:
            tree = ET.fromstring(row['content_html'])
        except ET.ParseError:
            continue

        filename = row_filename(row)

        d = to_dict(tree, False)
        body = d.pop('Information')
        with open(os.path.join(POSTS_DIR, filename), 'w') as post:
            print('---', file=post)
            for (k, v) in d.items():
                if not v:
                    continue
                print("%s: %s" % (k.lower(), v), file=post)
            print('---', file=post)
            print(body, file=post)

if __name__ == "__main__":
    main()
