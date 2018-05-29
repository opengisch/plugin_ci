#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# If we are on the master branch and not on a fork, upload translation strings
if [[ ${TRAVIS_SECURE_ENV_VARS} == "true" && ${TRAVIS_BRANCH} == "master" ]];
then
  #echo -e "[https://www.transifex.com]\nhostname = https://www.transifex.com\nusername = api\npassword = ${TRANSIFEX_API_TOKEN}\ntoken =\n" > ~/.transifexrc

  ${DIR}/update-strings.sh en
  ${DIR}/push-transifex-translations.sh
else
  echo "Not pushing any translation sources. We only use transifex if TRAVIS_BRANCH is master (currently ${TRAVIS_BRANCH}) and TRAVIS_SECURE_ENV_VARS is true (currently ${TRAVIS_SECURE_ENV_VARS})."
fi

# If we are doing a release, pull in the latest strings from transifex
if [[ ${TRAVIS_SECURE_ENV_VARS} == "true" && ${RELEASE_VERSION+x} ]] ;
then
  # echo -e "[https://www.transifex.com]\nhostname = https://www.transifex.com\nusername = api\npassword = ${TRANSIFEX_API_TOKEN}\ntoken =\n" > ~/.transifexrc

  ${DIR}/pull-transifex-translations.sh
  ${DIR}/compile-strings.sh i18n/*.ts
else
  echo "Not pulling any translations. We only use transifex if TRAVIS_BRANCH is master (currently ${TRAVIS_BRANCH}) and if we are doing a release (git tag matches metadata.txt)."
fi
