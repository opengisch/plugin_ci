#!/usr/bin/env bash

export REPO_NAME=$(echo $TRAVIS_REPO_SLUG | ${GP}sed -r 's#^[^/]+/([^/]+)$#\1#')
export PLUGIN_NAME=$(echo $TRAVIS_REPO_SLUG | ${GP}sed -r 's#^[^/]+/(qgis_)?([^/]+)$#\2#')

if [ -z "$PLUGIN_SRC_DIR" ]; then
  export PLUGIN_SRC_DIR=${PLUGIN_NAME}
fi

if [ -z "$PLUGIN_AUTHOR" ]; then
  export PLUGIN_AUTHOR=OpenGIS.ch
fi
if [ -z "$OSGEO_USERNAME" ]; then
  export OSGEO_USERNAME=OpenGISch
fi

# remove potential revision
export TAG_VERSION=${TRAVIS_TAG}
export RELEASE_VERSION=$(${GP}sed -r 's/-\w+$//; s/^v//' <<< ${TRAVIS_TAG})

export ZIPFILENAME="${PLUGIN_NAME}-${TAG_VERSION}.zip"