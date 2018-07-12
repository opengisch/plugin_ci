#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURDIR=$(pwd)

# GNU prefix command for mac os support (gsed, gsplit)
GP=
if [[ "$OSTYPE" =~ darwin* ]]; then
  GP=g
fi

if [[ ! ${TRAVIS_SECURE_ENV_VARS} == "true" || -z ${TRAVIS_TAG} ]]; then
  echo "Not releasing: not on main repo or master branch or missing tag"
  exit 1
fi

source ${DIR}/../scripts/env_variables.sh

# remove potential revision
export TAG_VERSION=${TRAVIS_TAG}
export RELEASE_VERSION=$(${GP}sed -r 's/-\w+$//; s/^v//' <<< ${TRAVIS_TAG})

# Inject metadata version from git tag
${GP}sed -r -i "s/^version=.*\$/version=${RELEASE_VERSION}/" ${PLUGIN_SRC_DIR}/metadata.txt

# Ensure DEBUG is False in main plugin file
if [[ -f ${PLUGIN_NAME}_plugin.py ]]; then
  ${GP}sed -r -i 's/^DEBUG\s*=\s*True/DEBUG = False/' ${PLUGIN_SRC_DIR}/${PLUGIN_NAME}_plugin.py
fi

# Pull translations from transifx
${DIR}/../translate/pull-transifex-translations.sh
${DIR}/../translate/compile-strings.sh i18n/*.ts

# Tar up all the static files from the git directory
echo -e " \e[33mExporting plugin version ${TRAVIS_TAG} from folder ${PLUGIN_NAME}"
# create a stash to save uncommitted changes (metadata)
STASH=$(git stash create)
git archive --prefix=${PLUGIN_NAME}/ -o ${CURDIR}/${PLUGIN_NAME}-${RELEASE_VERSION}.tar $STASH ${PLUGIN_SRC_DIR}

# include submodules as part of the tar
echo "also archive submodules..."
git submodule foreach | while read entering path; do
    temp="${path%\'}"
    temp="${temp#\'}"
    path=${temp}
    [ "$path" = "" ] && continue
    [[ ! "$path" =~ ^"${PLUGIN_SRC_DIR}" ]] && echo "skipping non-plugin submodule $path" && continue
    pushd ${path} > /dev/null
    git archive --prefix=${PLUGIN_NAME}/${path}/ HEAD > /tmp/tmp.tar
    tar --concatenate --file=${CURDIR}/${PLUGIN_NAME}-${RELEASE_VERSION}.tar /tmp/tmp.tar
    rm /tmp/tmp.tar
    popd > /dev/null
done

# Extract to a temporary location and add translations
TEMPDIR=/tmp/build-${PLUGIN_NAME}
mkdir -p ${TEMPDIR}/${PLUGIN_NAME}/${PLUGIN_NAME}/i18n
tar -xf ${CURDIR}/${PLUGIN_NAME}-${RELEASE_VERSION}.tar -C ${TEMPDIR}
mv i18n/*.qm ${TEMPDIR}/${PLUGIN_NAME}/${PLUGIN_NAME}/i18n

pushd ${TEMPDIR}/${PLUGIN_NAME}
zip -r ${CURDIR}/${PLUGIN_NAME}-${TAG_VERSION}.zip ${PLUGIN_NAME}
popd

echo "## Detailed changelod" > /tmp/changelog
git log HEAD^...$(git describe --abbrev=0 --tags HEAD^) --pretty=format:"### %s%n%n%b" >> /tmp/changelog

${DIR}/create_release.py -f ${CURDIR}/${PLUGIN_NAME}-${TAG_VERSION}.zip -c /tmp/changelog -o /tmp/release_notes
cat /tmp/release_notes
if [[ ${PUSH_TO} =~ ^github$ ]]; then
  ${DIR}/publish_plugin_github.sh ${TAG_VERSION} ${PLUGIN_NAME}-${TAG_VERSION}.zip
else
  ${DIR}/publish_plugin_osgeo.py -u "${OSGEO_USERNAME}" -w "${OSGEO_PASSWORD}" -r "${TRAVIS_TAG}" ${PLUGIN_NAME}-${TAG_VERSION}.zip -c /tmp/release_notes
fi
