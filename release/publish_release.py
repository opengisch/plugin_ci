#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
***************************************************************************
    create_release.py
    ---------------------
    Date                 : May 2018
    Copyright            : (C) 2018 by Denis Rouzaud
    Email                : denis@opengis.ch
***************************************************************************
*                                                                         *
*   This program is free software; you can redistribute it and/or modify  *
*   it under the terms of the GNU General Public License as published by  *
*   the Free Software Foundation; either version 2 of the License, or     *
*   (at your option) any later version.                                   *
*                                                                         *
***************************************************************************
"""

__author__ = 'Denis Rouzaud'
__date__ = 'May 2018'
__copyright__ = '(C) 2018,Denis Rouzaud'
# This will get replaced with a git SHA1 when you do a git archive
__revision__ = '$Format:%H$'


import http.client
import os
import json
from optparse import OptionParser


def create_release(release_files, changelog="", output="") -> str:
    """
    Publish the files in a release on github
    If a release already exist, it will copy its data (title, description, etc),
    delete it and create a new one with the same data and adding the dump files
    :returns: the release notes as entered on Travis
    """
    release_notes = ""
    if 'TRAVIS_TAG' not in os.environ or not os.environ['TRAVIS_TAG']:
        print('No git tag: not deploying anything')
        return release_notes
    elif os.environ['TRAVIS_SECURE_ENV_VARS'] != 'true':
        print('No secure environment variables: not deploying anything')
        return release_notes
    elif len(release_files):
        print('No file to release')
        return release_notes
    else:
        print('Creating release from tag {}'.format(os.environ['TRAVIS_TAG']))

    headers = {
        'User-Agent': 'Deploy-Script',
        'Authorization': 'token {}'.format(os.environ['GH_TOKEN'])
    }

    create_raw_data = {
        "tag_name": os.environ['TRAVIS_TAG'],
        "body": "\n\n{}".format(changelog) if changelog else ""
    }

    # if a release exist with this tag_name delete it first
    # this allows to create the release from github website
    url = '/repos/{repo_slug}/releases/latest'.format(
        repo_slug=os.environ['TRAVIS_REPO_SLUG'])
    conn = http.client.HTTPSConnection('api.github.com')
    conn.request('GET', url, headers=headers)
    response = conn.getresponse()
    release = json.loads(response.read().decode())
    if 'tag_name' in release and release['tag_name'] == os.environ['TRAVIS_TAG']:
        print("Deleting release {}".format(release['tag_name']))
        url = '/repos/{repo_slug}/releases/{id}'.format(
            repo_slug=os.environ['TRAVIS_REPO_SLUG'],
            id=release['id'])
        conn = http.client.HTTPSConnection('api.github.com')
        conn.request('DELETE', url, headers=headers)
        response = conn.getresponse()
        if response.status == 204:
            print('Existing release deleted!')
            create_raw_data["target_commitish"] = release['target_commitish']
            create_raw_data["name"] = release['name']
            create_raw_data["body"] = release['body'] + create_raw_data["body"]
            release_notes = release['body']
        else:
            print('Failed to delete release!')
            print('Github API replied:')
            print('{} {}'.format(response.status, response.reason))

    data = json.dumps(create_raw_data)
    url = '/repos/{repo_slug}/releases'.format(
        repo_slug=os.environ['TRAVIS_REPO_SLUG'])
    conn = http.client.HTTPSConnection('api.github.com')
    conn.request('POST', url, body=data, headers=headers)
    response = conn.getresponse()
    release = json.loads(response.read().decode())

    if 'upload_url' not in release:
        print('Failed to create release!')
        print('Github API replied:')
        print('{} {}'.format(response.status, response.reason))
        print(repr(release))
        exit(-1)

    conn = http.client.HTTPSConnection('uploads.github.com')
    for release_file in release_files:
        _, filename = os.path.split(release_file)
        headers['Content-Type'] = 'text/plain'
        # headers['Transfer-Encoding'] = 'gzip'
        url = '{release_url}?name={filename}'.format(release_url=release['upload_url'][:-13], filename=filename)
        print('Upload to {}'.format(url))

        with open(release_file, 'rb') as f:
            conn.request('POST', url, f, headers)

        response = conn.getresponse()
        result = response.read()
        if response.status != 201:
            print('Failed to upload filename {filename}'.format(filename=filename))
            print('Github API replied:')
            print('{} {}'.format(response.status, response.reason))
            print(repr(json.loads(result.decode())))

    if output:
        with open(output, 'w') as f:
            f.write(release_notes)


if __name__ == "__main__":
    parser = OptionParser(usage="%prog")
    parser.add_argument(
        "-c", "--changelog", help="Detailed changelog (appended to the one entered online)")
    parser.add_argument(
        "-o", "--output", help="Write release notes to output files")
    parser.add_argument(
        '-f', '--file', help='File to add to the release', action='append')
    args = parser.parse_args()
    create_release(args.file, args.changelog, args.output)
