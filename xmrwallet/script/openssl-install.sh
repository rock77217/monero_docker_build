#!/usr/bin/env bash

set -e

source script/env.sh

SRC_DIR=$EXTERNAL_LIBS_ROOT/android-openssl
TARGET_DIR=$EXTERNAL_LIBS_ROOT/openssl

for arch in ${archs[@]}; do
    ln -sf $TARGET_DIR/include $NDK_TOOL_DIR/$arch/sysroot/usr/include/openssl
    ln -sf $TARGET_DIR/$arch/lib/*.so $NDK_TOOL_DIR/$arch/sysroot/usr/lib
done
