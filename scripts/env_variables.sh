#!/usr/bin/env bash

set -e

# GNU prefix command for mac os support (gsed, gsplit)
GP=
if [[ "$OSTYPE" =~ darwin* ]]; then
  GP=g
fi

export PLUGIN_REPO_NAME=$(echo $TRAVIS_REPO_SLUG | ${GP}sed -r 's#^[^/]+/(qgis_)?([^/]+)$#\2#')

if [ -z "$PLUGIN_SRC_DIR" ]; then
  export PLUGIN_SRC_DIR=${PLUGIN_REPO_NAME}
fi

export PLUGIN_NAME=$(${GP}sed -n -r '/^name=/p' ${PLUGIN_SRC_DIR}/metadata.txt | ${GP}sed -r 's/^name=//')

if [ -z "$PLUGIN_AUTHOR" ]; then
  export PLUGIN_AUTHOR=OpenGIS.ch
fi
if [ -z "$OSGEO_USERNAME" ]; then
  export OSGEO_USERNAME=OpenGISch
fi

if [ -z "$APPEND_CHANGELOG" ]; then
  export APPEND_CHANGELOG=""
fi

# remove potential revision
export TAG_VERSION=${TRAVIS_TAG}
export RELEASE_VERSION=$(${GP}sed -r 's/-\w+$//; s/^v//' <<< ${TRAVIS_TAG})

export ZIPFILENAME="${PLUGIN_REPO_NAME}.${TAG_VERSION}.zip"
