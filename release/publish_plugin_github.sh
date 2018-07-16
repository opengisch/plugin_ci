#!/usr/bin/env bash

set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# GNU prefix command for mac os support (gsed, gsplit)
GP=
if [[ "$OSTYPE" =~ darwin* ]]; then
  GP=g
fi

echo "creating release version $RELEASE_VERSION"

PLUGIN_XML=${TRAVIS_BUILD_DIR}/plugins.xml

NOW=$(${GP}date -Iseconds -u)
CREATE_DATE=$(git show -s --format=%cI $(git rev-list --max-parents=0 HEAD))

cp ${DIR}/plugins.xml.template ${PLUGIN_XML}

echo "AAA"

${GP}sed -i -r "s/__VERSION__/${RELEASE_VERSION}/" ${PLUGIN_XML}
${GP}sed -i -r "s/__PLUGIN_NAME__/${PLUGIN_NAME}/" ${PLUGIN_XML}
${GP}sed -i -r "s@__RELEASE_DATE__@${NOW}@" ${PLUGIN_XML}
${GP}sed -i -r "s@__CREATE_DATE__@${CREATE_DATE}@" ${PLUGIN_XML}

echo "BBBB"


${GP}sed -i -r "s@__ORG__/__REPO__@${TRAVIS_REPO_SLUG}@" ${PLUGIN_XML}
${GP}sed -i -r "s@__PLUGINZIP__@${ZIPFILENAME}@" ${PLUGIN_XML}
${GP}sed -i -r "s@__AUTHOR__@${PLUGIN_AUTHOR}@" ${PLUGIN_XML}
${GP}sed -i -r "s@__OSGEO_USERNAME__@${OSGEO_USERNAME}@" ${PLUGIN_XML}

declare -A metadata_settings
metadata_settings["description"]="__DESCRIPTION__"
metadata_settings["qgisMinimumVersion"]="__QGIS_MIN_VERSION__"
metadata_settings["icon"]="__ICON__"
metadata_settings["tags"]="__TAGS__"
metadata_settings["experimental"]="__EXPERIMENTAL__"
metadata_settings["deprecated"]="__DEPRECATED__"

for setting in "${!metadata_settings[@]}"; do
  echo "CCC $setting"
  value=$(${GP}sed -n -r "/^${setting}=/p" ${PLUGIN_SRC_DIR}/metadata.txt | ${GP}sed -r "s/^${setting}=//")
  echo "ddd"
  ${GP}sed -i -r "s@${metadata_settings[${setting}]}@${value}@" ${PLUGIN_XML}
done

pushd ${TRAVIS_BUILD_DIR}
git add plugins.xml
git commit -m "Release $1 on repo"
git push git@github.com:${TRAVIS_REPO_SLUG} HEAD:master
popd