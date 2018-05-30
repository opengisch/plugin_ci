#!/usr/bin/env bash

set -e

if [ -z ${LRELEASE+x} ];
then
  echo "$LRELEASE is not set, defaulting to lrelease"
  LRELEASE=lrelease
fi
$LRELEASE $*
