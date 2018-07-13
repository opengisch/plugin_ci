#!/usr/bin/env bash

set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# GNU prefix command for mac os support (gsed, gsplit)
GP=
if [[ "$OSTYPE" =~ darwin* ]]; then
  GP=g
fi

echo "creating release version $1 ($2)"

PLUGIN_XML=${TRAVIS_BUILD_DIR}/plugins.xml

VERSION=$1
FILENAME=$2
NOW=$(${GP}date -Iseconds -u)
CREATE_DATE=$(git show -s --format=%cI $(git rev-list --max-parents=0 HEAD))

if [ -z "$PLUGIN_AUTHOR" ]; then
  PLUGIN_AUTHOR=OpenGIS.ch
fi
if [ -z "$OSGEO_USERNAME" ]; then
  OSGEO_USERNAME=OpenGISch
fi

cp ${DIR}/plugins.xml.template ${PLUGIN_XML}

${GP}sed -i "s/__VERSION__/${VERSION}/" ${PLUGIN_XML}
${GP}sed -i "s/__PLUGIN_NAME__/${PLUGIN_NAME}/" ${PLUGIN_XML}
${GP}sed -i "s@__RELEASE_DATE__@${NOW}@" ${PLUGIN_XML}
${GP}sed -i "s@__CREATE_DATE__@${CREATE_DATE}@" ${PLUGIN_XML}
${GP}sed -i "s@__ORG__/__REPO__@${TRAVIS_REPO_SLUG}@" ${PLUGIN_XML}
${GP}sed -i "s@__PLUGINZIP__@${FILENAME}@" ${PLUGIN_XML}
${GP}sed -i "s@__AUTHOR__@${PLUGIN_AUTHOR}@" ${PLUGIN_XML}
${GP}sed -i "s@__OSGEO_USERNAME__@${OSGEO_USERNAME}@" ${PLUGIN_XML}

declare -A metadata_settings
metadata_settings["description"]="__DESCRIPTION__"
metadata_settings["qgisMinimumVersion"]="__QGIS_MIN_VERSION__"
metadata_settings["icon"]="__ICON__"
metadata_settings["tags"]="__TAGS__"
metadata_settings["experimental"]="__EXPERIMENTAL__"
metadata_settings["deprecated"]="__DEPRECATED__"

for setting in "${!metadata_settings[@]}"; do
  value=$(${GP}sed -n -r "/^${setting}=/p" ${PLUGIN_SRC_DIR}/metadata.txt | ${GP}sed -r "s/^${setting}=//")
  ${GP}sed -i "s@${metadata_settings[${setting}]}@${value}@" ${PLUGIN_XML}
done

git add .
git commit -m "Release $1 on repo"
git push