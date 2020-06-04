#!/bin/bash

root_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd ${root_path}

TARGET_API=26
if [ "$1" == "arm" ]; then
    archs=($1)
    
elif [ "$1" == "arm64" ]; then
    archs=($1)
else
    archs=("arm" "arm64")
fi

for arch in ${archs[@]}; do
    case ${arch} in
        "arm")
            ARCH=arm
            ARCH_ABI=armeabi-v7a
            TARGET_API=26
            TARGET_HOST="arm-linux-androideabi"
            MONERO_BUILD_CMD="release-static-android-armv7"
            ;;
        "arm64")
            ARCH=arm64
            ARCH_ABI=arm64-v8a
            TARGET_API=26
            TARGET_HOST="aarch64-linux-android"
            MONERO_BUILD_CMD="release-static-android-armv8"
            ;;
        *)
            exit 1
            ;;
    esac

    echo "======================================================"
    echo "Build for $ARCH..."
    echo "======================================================"
    docker build -t "monero-library:$ARCH" \
    --build-arg ARCH=$ARCH \
    --build-arg ARCH_ABI=$ARCH_ABI \
    --build-arg TARGET_API=$TARGET_API \
    --build-arg TARGET_HOST=$TARGET_HOST \
    --build-arg MONERO_BUILD_CMD=$MONERO_BUILD_CMD \
    . || exit 1
    echo "======================================================"
    echo "Build done"
    echo "======================================================"

    container_name=monero-library-$ARCH
    container_exists=`docker ps -f name=${container_name} -a | tail -n 1`
    if [ -z "${container_exists}" ]; then
        docker stop ${container_name}
        docker rm ${container_name}
    fi

    out_path=${root_path}/jniLibs/$ARCH_ABI/
    jar_path=${root_path}/jniLibs/
    docker run --name ${container_name} -i monero-library:$ARCH &
    wait
    mkdir -p ${out_path}
    docker cp monero-library-$ARCH:/out/*.so ${out_path}
    docker cp monero-library-$ARCH:/out/*.jar ${jar_path}
    docker stop monero-library-$ARCH
    docker rm $(docker ps -a -q)

    echo "======================================================"
    echo "$ARCH Done. Output path: ${out_path}"
    echo "======================================================"
done

call_user=`who am i | awk '{print $1}'`
chown -R $call_user:$call_user ${root_path}/jniLibs