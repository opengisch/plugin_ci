#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/../scripts/env_variables.sh

pyrcc5 -o ${PLUGIN_SRC_DIR}/resources_rc.py ${PLUGIN_SRC_DIR}/resources.qrc