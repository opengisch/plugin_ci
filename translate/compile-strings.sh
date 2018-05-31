#!/usr/bin/env bash

set -e

if [[ -z ${LRELEASE} ]]; then
  echo "$LRELEASE is not set, defaulting to lrelease"
  LRELEASE=lrelease
fi
$LRELEASE $*
