#!/usr/bin/env bash

set -e

source script/env.sh

TARGET_DIR=$EXTERNAL_LIBS_ROOT/boost

version=1_58_0
dot_version=1.58.0

cd $EXTERNAL_LIBS_BUILD_ROOT/boost_${version}

if [ ! -f "b2" ]; then
  ./bootstrap.sh
fi

args="--build-type=minimal link=static runtime-link=static --with-chrono \
--with-date_time --with-filesystem --with-program_options --with-regex \
--with-serialization --with-system --with-thread \
--includedir=$TARGET_DIR/include \
toolset=clang threading=multi threadapi=pthread target-os=android"

for arch in ${archs[@]}; do
    case ${arch} in
        "arm")
            target_host=arm-linux-androideabi
            ;;
        "arm64")
            target_host=arm-aarch64-linux-androideabi
            ;;
        "x86")
            target_host=i686-linux-android
            ;;
        "x86_64")
            target_host=x86_64-linux-android
            ;;
        *)
            exit 16
            ;;
    esac

    PATH=$NDK_TOOL_DIR/$arch/$target_host/bin:$NDK_TOOL_DIR/$arch/bin:$PATH \
        ./b2 --build-dir=android-$arch --prefix=$TARGET_DIR/$arch $args \
        install
    ln -sf ../include $TARGET_DIR/$arch
done
