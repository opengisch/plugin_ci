#!/usr/bin/env bash

export REPO_NAME=$(echo $TRAVIS_REPO_SLUG | ${GP}sed -r 's#^[^/]+/([^/]+)$#\1#')
export PLUGIN_NAME=$(echo $TRAVIS_REPO_SLUG | ${GP}sed -r 's#^[^/]+/(qgis_)?([^/]+)$#\2#')

if [ -z "$PLUGIN_SRC_DIR" ]; then
  export PLUGIN_SRC_DIR=${PLUGIN_NAME}
fi