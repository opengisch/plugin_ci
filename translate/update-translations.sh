#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# If we are on the master branch and not on a fork, upload translation strings
if [[ ${TRAVIS_SECURE_ENV_VARS} == "true" && ${TRAVIS_BRANCH} == "master" ]];
then
  ${DIR}/update-strings.sh en
  ${DIR}/push-transifex-translations.sh
else
  echo "Not pushing any translation sources. We only use transifex if TRAVIS_BRANCH is master (currently ${TRAVIS_BRANCH}) and TRAVIS_SECURE_ENV_VARS is true (currently ${TRAVIS_SECURE_ENV_VARS})."
fi