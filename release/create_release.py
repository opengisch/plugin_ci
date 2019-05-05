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
import argparse


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
    elif len(release_files) == 0:
        print('No file to release')
        return release_notes
    else:
        print('Creating release from tag {}'.format(os.environ['TRAVIS_TAG']))

    headers = {
        'User-Agent': 'Deploy-Script',
        'Authorization': 'token {}'.format(os.environ['GH_TOKEN'])
    }

    changelog_content = ''
    if changelog:
        with open(changelog, 'r') as changelog_file:
            changelog_content = changelog_file.read()

    create_raw_data = {
        "tag_name": os.environ['TRAVIS_TAG'],
        "body": "\n\n{}".format(changelog_content)
    }

    # if a release exist with this tag_name delete it first
    # this allows to create the release from github website
    url = '/repos/{repo_slug}/releases/tags/{tag}'.format(
        repo_slug=os.environ['TRAVIS_REPO_SLUG'],
        tag=os.environ['TRAVIS_TAG'])
    conn = http.client.HTTPSConnection('api.github.com')
    conn.request('GET', url, headers=headers)
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
        headers['Content-Type'] = 'application/zip'
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
            print('File:')
            print('  Size: {}'.format(os.path.getsize(release_file)))

    if output:
        with open(output, 'w') as f:
            print("Writing release notes")
            print(release_notes)
            f.write(release_notes)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-c", "--changelog", help="Detailed changelog (appended to the one entered online)")
    parser.add_argument(
        "-o", "--output", help="Write release notes to output files")
    parser.add_argument(
        '-f', '--file', help='File to add to the release', action='append')
    args = parser.parse_args()
    create_release(args.file, args.changelog, args.output)
