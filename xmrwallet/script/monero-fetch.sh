#!/usr/bin/env bash

set -e

source script/env.sh

cd $EXTERNAL_LIBS_BUILD_ROOT

url="https://github.com/monero-project/monero"
version="v0.15.0.1"

if [ ! -d "monero" ]; then
  git clone ${url} -b ${version}
  cd monero
  git submodule update --recursive --init
else
  cd monero
  git checkout ${version}
  git pull
  git submodule update --recursive --init
fi
