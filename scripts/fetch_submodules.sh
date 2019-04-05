#!/usr/bin/env bash

set -e

# cannot use SSH to fetch submodule
sed -i 's#git@github.com:#https://github.com/#' .gitmodules
git submodule update --init --recursive