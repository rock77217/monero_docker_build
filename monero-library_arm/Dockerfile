FROM ubuntu:16.04 as builder

RUN apt-get update && apt-get install -y unzip automake build-essential curl file pkg-config git python libtool libtinfo5 xsltproc gperf openjdk-8-jdk maven

ARG JLIB_PATH=/monero-java
ARG JLIB_BUILD_PATH=${JLIB_PATH}/build
ARG CLIB_PATH=${JLIB_PATH}/external/monero-cpp
ARG CLIB_BUILD_PATH=${CLIB_PATH}/build
ARG CLIB_EXT_PATH=${CLIB_PATH}/external
ARG CLIB_EXTLIB_PATH=${CLIB_PATH}/external-libs
ARG XMR_CORE_PATH=${CLIB_EXT_PATH}/monero-core
RUN git config --global http.postBuffer 2000000000

# Clone monero git
RUN git clone https://github.com/monero-ecosystem/monero-java ${JLIB_PATH}
RUN git clone https://github.com/monero-ecosystem/monero-cpp ${CLIB_PATH}
RUN git clone https://github.com/monero-project/monero ${XMR_CORE_PATH}

# Define args
ARG ARCH
ARG ARCH_ABI
ARG TARGET_API
ARG TARGET_HOST
ARG MONERO_BUILD_CMD
ARG HOST_NCORES

ENV ARCH=${ARCH:-arm64}
ENV ARCH_ABI=${ARCH_ABI:-arm64-v8a}
ENV TARGET_API="${TARGET_API:-26}"
ENV TARGET_HOST=${TARGET_HOST:-aarch64-linux-android}
ENV MONERO_BUILD_CMD=${MONERO_BUILD_CMD:-release-static-android-armv8}
ENV HOST_NCORES=${HOST_NCORES:-4}

RUN echo "Core[${HOST_NCORES}]"

#RUN export findJavaHome=`dirname $(dirname $(readlink -f $(which javac)))`
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Prepare NDK
WORKDIR /opt/android
ARG NDK_VERSION=android-ndk-r17c
ARG NDK_HASH=12cacc70c3fd2f40574015631c00f41fb8a39048
RUN set -ex && \
    curl -O -L --retry 5 https://dl.google.com/android/repository/${NDK_VERSION}-linux-x86_64.zip && \
    echo "${NDK_HASH} ${NDK_VERSION}-linux-x86_64.zip" | sha1sum -c && \
    unzip ${NDK_VERSION}-linux-x86_64.zip && \
    mv ${NDK_VERSION} ndk
ARG DEFAULT_ANDROID_NDK_ROOT=/opt/android/ndk
ENV ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-${DEFAULT_ANDROID_NDK_ROOT}}"
ENV NDK_TOOL_DIR=/opt/android/toolchains-${ARCH}
ENV PREFIX /opt/android/prefix

RUN PATH=$ANDROID_NDK_ROOT/build/tools/:$PATH && \
    args="--api ${TARGET_API} --stl=libc++" && \
    echo "installing $ANDROID_NDK_ROOT $ARCH $args" && \
    make_standalone_toolchain.py $args --arch $ARCH --install-dir $NDK_TOOL_DIR

WORKDIR ${CLIB_EXT_PATH}

#INSTALL cmake
ARG CMAKE_VERSION=3.14.6
ARG CMAKE_VERSION_DOT=v3.14
ARG CMAKE_HASH=82e08e50ba921035efa82b859c74c5fbe27d3e49a4003020e3c77618a4e912cd
RUN cd /usr/local \
    && curl -O -L --retry 5 https://cmake.org/files/${CMAKE_VERSION_DOT}/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz \
    && echo "${CMAKE_HASH}  cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz" | sha256sum -c \
    && tar -xzf /usr/local/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz \
    && rm -f /usr/local/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz

ENV PATH /usr/local/cmake-${CMAKE_VERSION}-Linux-x86_64/bin:$PATH

## Boost
#https://downloads.sourceforge.net/project/boost/boost/${BOOST_VERSION_DOT}/boost_${BOOST_VERSION}.tar.bz2
#https://dl.bintray.com/boostorg/release/${BOOST_VERSION_DOT}/source/boost_${BOOST_VERSION}.tar.bz2
ARG BOOST_VERSION=1_72_0
ARG BOOST_VERSION_DOT=1.72.0
ARG BOOST_HASH=59c9b274bc451cf91a9ba1dd2c7fdcaf5d60b1b3aa83f2c9fa143417cc660722
RUN set -ex \
    && curl -L -o boost_${BOOST_VERSION}.tar.bz2 https://dl.bintray.com/boostorg/release/${BOOST_VERSION_DOT}/source/boost_${BOOST_VERSION}.tar.bz2 \
    && echo "${BOOST_HASH}  boost_${BOOST_VERSION}.tar.bz2" | sha256sum -c \
    && tar -xvf boost_${BOOST_VERSION}.tar.bz2 \
    && mv boost_${BOOST_VERSION} boost-sdk
RUN set -ex \
    && cd boost-sdk \
    && ./bootstrap.sh --prefix=${PREFIX}

ENV HOST_PATH=$PATH
ENV PATH=${NDK_TOOL_DIR}/${TARGET_HOST}/bin/:${NDK_TOOL_DIR}/bin/:$PATH

# Build iconv for lib boost locale
ENV ICONV_VERSION 1.15
ENV ICONV_HASH  ccf536620a45458d26ba83887a983b96827001e92a13847b45e4925cc8913178
RUN curl -O -L --retry 5 http://ftp.gnu.org/pub/gnu/libiconv/libiconv-${ICONV_VERSION}.tar.gz \
    && echo "${ICONV_HASH}  libiconv-${ICONV_VERSION}.tar.gz" | sha256sum -c \
    && tar -xzf libiconv-${ICONV_VERSION}.tar.gz \
    && rm -f libiconv-${ICONV_VERSION}.tar.gz \
    && cd libiconv-${ICONV_VERSION} \
    && CC=${TARGET_HOST}-clang CXX=${TARGET_HOST}-clang++ ./configure --build=x86_64-linux-gnu --host=arm-eabi --prefix=${PREFIX} --disable-rpath \
    && make -j${HOST_NCORES} && make install

RUN cd boost-sdk && \
    ./b2 architecture=arm --build-type=minimal link=static runtime-link=static --with-chrono --with-date_time --with-filesystem --with-program_options --with-regex --with-serialization --with-system --with-thread --with-locale toolset=clang threading=multi threadapi=pthread target-os=android -sICONV_PATH=${PREFIX} install -j${HOST_NCORES}
ENV BOOST_ROOT ${PREFIX}

# download, configure and make Zlib
ENV ZLIB_VERSION 1.2.11
ENV ZLIB_HASH c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1
RUN curl -O -L --retry 5 https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz \
    && echo "${ZLIB_HASH}  zlib-${ZLIB_VERSION}.tar.gz" | sha256sum -c \
    && tar -xzf zlib-${ZLIB_VERSION}.tar.gz \
    && rm zlib-${ZLIB_VERSION}.tar.gz \
    && mv zlib-${ZLIB_VERSION} zlib \
    && cd zlib && CC=${TARGET_HOST}-clang CXX=${TARGET_HOST}-clang++ ./configure --static \
    && make -j${HOST_NCORES}

# OpenSSL
ARG OPENSSL_VERSION=1.1.1b
ARG OPENSSL_VERSION_BASIC=1.1.1
ARG OPENSSL_HASH=5c557b023230413dfb0756f3137a13e6d726838ccd1430888ad15bfb2b43ea4b
RUN set -ex \
    && curl -O -L --retry 5 https://www.openssl.org/source/old/${OPENSSL_VERSION_BASIC}/openssl-${OPENSSL_VERSION}.tar.gz \
    && echo "${OPENSSL_HASH}  openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c \
    && tar -xzf openssl-${OPENSSL_VERSION}.tar.gz \
    && mv openssl-${OPENSSL_VERSION} openssl-sdk
# Prepare args

ARG ANDROID_NDK_HOME=${ANDROID_NDK_ROOT}
RUN cd openssl-sdk && \
    PATH=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH && \
    CC=${TARGET_HOST}-clang CXX=${TARGET_HOST}-clang++ \
           ./Configure android-${ARCH} \
           no-asm \
           #no-shared --static \
           -fPIC \
           -D__ANDROID_API__=${TARGET_API} \
           --with-zlib-include=${CLIB_EXT_PATH}/zlib/include --with-zlib-lib=${CLIB_EXT_PATH}/zlib/lib \
           --prefix=${PREFIX} --openssldir=${PREFIX} && \
    make clean && \
    make && \
    make install
#ENV OPENSSL_ROOT_DIR=${CLIB_EXT_PATH}/openssl

# ZMQ
ARG ZMQ_VERSION=v4.3.2
ARG ZMQ_HASH=a84ffa12b2eb3569ced199660bac5ad128bff1f0
RUN set -ex \
    && git clone https://github.com/zeromq/libzmq.git -b ${ZMQ_VERSION} \
    && cd libzmq \
    && test `git rev-parse HEAD` = ${ZMQ_HASH} || exit 1 \
    && ./autogen.sh \
    && CC=${TARGET_HOST}-clang CXX=${TARGET_HOST}-clang++ ./configure --prefix=${PREFIX} --host=${TARGET_HOST} --enable-static --disable-shared \
    && make -j${HOST_NCORES} \
    && make install \
    && ldconfig

# zmq.hpp
ARG CPPZMQ_VERSION=v4.4.1
ARG CPPZMQ_HASH=f5b36e563598d48fcc0d82e589d3596afef945ae
RUN set -ex \
    && git clone https://github.com/zeromq/cppzmq.git -b ${CPPZMQ_VERSION} \
    && cd cppzmq \
    && test `git rev-parse HEAD` = ${CPPZMQ_HASH} || exit 1 \
    && cp *.hpp ${PREFIX}/include

# Sodium
ARG SODIUM_VERSION=1.0.18
ARG SODIUM_HASH=4f5e89fa84ce1d178a6765b8b46f2b6f91216677
RUN set -ex \
    && git clone https://github.com/jedisct1/libsodium.git -b ${SODIUM_VERSION} libsodium-sdk \
    && cd libsodium-sdk \
    && test `git rev-parse HEAD` = ${SODIUM_HASH} || exit 1 \
    && ./autogen.sh \
    && CC=${TARGET_HOST}-clang CXX=${TARGET_HOST}-clang++ ./configure --prefix=${PREFIX} --host=${TARGET_HOST} --enable-static --disable-shared \
    && make -j${HOST_NCORES} \
    && make install

## Udev
#ARG UDEV_VERSION=v3.2.8
#ARG UDEV_HASH=d69f3f28348123ab7fa0ebac63ec2fd16800c5e0
#RUN set -ex \
#    && git clone https://github.com/gentoo/eudev
#RUN cd eudev \
#    #&& test `git rev-parse HEAD` = ${UDEV_HASH} || exit 1 \
#    && ./autogen.sh \
#    && ./configure --prefix=${PREFIX} --disable-introspection --disable-hwdb \
#    && make \
#    && make install
#
## Libusb
#ARG USB_VERSION=v1.0.22
#ARG USB_HASH=0034b2afdcdb1614e78edaa2a9e22d5936aeae5d
#RUN set -ex \
#    && git clone https://github.com/libusb/libusb.git -b ${USB_VERSION} \
#    && cd libusb \
#    && test `git rev-parse HEAD` = ${USB_HASH} || exit 1 \
#    && ./autogen.sh \
#    && ./configure --prefix=${PREFIX} \
#    && make \
#    && make install
#
## Hidapi
#ARG HIDAPI_VERSION=hidapi-0.8.0-rc1
#ARG HIDAPI_HASH=40cf516139b5b61e30d9403a48db23d8f915f52c
#RUN set -ex \
#    && git clone https://github.com/signal11/hidapi -b ${HIDAPI_VERSION}
#RUN cd hidapi \
#    && test `git rev-parse HEAD` = ${HIDAPI_HASH} || exit 1 \
#    && ./bootstrap \
#    && PKG_CONFIG_DIR= \
#    PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig \
#    PKG_CONFIG_SYSROOT_DIR=$PREFIX \
#    CC=${TARGET_HOST}-clang CXX=${TARGET_HOST}-clang++ ./configure --host=arm-linux --prefix=${PREFIX} --enable-static --disable-shared \
#    && make \
#    && make install

ARG DIFF_PATH=/monero_docker_build
# Copy diffs
WORKDIR ${DIFF_PATH}
COPY *.diff ./

# Update Monero version
ARG MONERO_VERSION=v0.17.1.1
ARG MONERO_HASH=76cc82c29234fc2805f936f0fc53d48acc9cedf7
WORKDIR ${XMR_CORE_PATH}
RUN set -ex && \
    git fetch --tags && \
    git checkout ${MONERO_VERSION} && \
    test `git rev-parse HEAD` = ${MONERO_HASH} || exit 1 && \
    git submodule init && git submodule update

ARG MONERO_CPP_VERSION=v0.3.7
ARG MONERO_CPP_HASH=478de96f4bf846b266514fa71ab99f2fde574c6c
WORKDIR ${CLIB_PATH}
RUN set -ex && \
    git fetch --tags && \
    git checkout ${MONERO_CPP_VERSION} && \
    test `git rev-parse HEAD` = ${MONERO_CPP_HASH} || exit 1 && \
    git apply ${DIFF_PATH}/monero-cpp.diff

ARG MONERO_JAVA_VERSION=v0.3.7
ARG MONERO_JAVA_HASH=b8902876b822c8b64bc0113fd4abd1802613673c
WORKDIR ${JLIB_PATH}
RUN set -ex && \
    git fetch --tags && \
    git checkout ${MONERO_JAVA_VERSION} && \
    test `git rev-parse HEAD` = ${MONERO_JAVA_HASH} || exit 1 && \
    git apply ${DIFF_PATH}/monero-java.diff

RUN cp ${JAVA_HOME}/include/linux/jni_md.h ${JAVA_HOME}/include/
RUN mvn install

# Build Monero
ENV PATH=${HOST_PATH}
WORKDIR ${XMR_CORE_PATH}
RUN sed -i 's/option(BUILD_GUI_DEPS "Build GUI dependencies." OFF)/option(BUILD_GUI_DEPS "Build GUI dependencies." ON)/g' CMakeLists.txt 
ARG CMAKE_INCLUDE_PATH="${PREFIX}/include"
ARG CMAKE_LIBRARY_PATH="${PREFIX}/lib"
ARG ANDROID_STANDALONE_TOOLCHAIN_PATH=${NDK_TOOL_DIR}
ARG USE_SINGLE_BUILDDIR=1
ARG MONERO_WALLET_CRYPTO_LIBRARY=cn
RUN make ${MONERO_BUILD_CMD} -j${HOST_NCORES} && \
    make ${MONERO_BUILD_CMD} -j${HOST_NCORES}

# Copy libs
WORKDIR ${CLIB_EXTLIB_PATH}
RUN mkdir boost openssl hidapi libsodium
RUN find ${PREFIX}/lib -name "libboost_chrono.a" -exec cp {} ${CLIB_EXTLIB_PATH}/boost \; && \
    find ${PREFIX}/lib -name "libboost_date_time.a" -exec cp {} ${CLIB_EXTLIB_PATH}/boost \; && \
    find ${PREFIX}/lib -name "libboost_filesystem.a" -exec cp {} ${CLIB_EXTLIB_PATH}/boost \; && \
    find ${PREFIX}/lib -name "libboost_program_options.a" -exec cp {} ${CLIB_EXTLIB_PATH}/boost \; && \
    find ${PREFIX}/lib -name "libboost_regex.a" -exec cp {} ${CLIB_EXTLIB_PATH}/boost \; && \
    find ${PREFIX}/lib -name "libboost_serialization.a" -exec cp {} ${CLIB_EXTLIB_PATH}/boost \; && \
    find ${PREFIX}/lib -name "libboost_wserialization.a" -exec cp {} ${CLIB_EXTLIB_PATH}/boost \; && \
    find ${PREFIX}/lib -name "libboost_system.a" -exec cp {} ${CLIB_EXTLIB_PATH}/boost \; && \
    find ${PREFIX}/lib -name "libboost_thread.a" -exec cp {} ${CLIB_EXTLIB_PATH}/boost \;

RUN find ${PREFIX}/lib -name "libcrypto.a" -exec cp {} ${CLIB_EXTLIB_PATH}/openssl \; && \
    find ${PREFIX}/lib -name "libssl.a" -exec cp {} ${CLIB_EXTLIB_PATH}/openssl \;

#RUN find ${CLIB_EXT_PATH}/hidapi -name "libhidapi-libusb.a" -exec cp {} ${CLIB_EXTLIB_PATH}/hidapi/libhidapi.a \;
RUN find ${PREFIX}/lib -name "libsodium.a" -exec cp {} ${CLIB_EXTLIB_PATH}/libsodium \;
RUN cp ${XMR_CORE_PATH}/build/release/src/crypto/libcncrypto.a ${XMR_CORE_PATH}/build/release/src/crypto/wallet/libwallet-crypto.a

WORKDIR ${CLIB_BUILD_PATH}
RUN CC=${TARGET_HOST}-clang CXX=${TARGET_HOST}-clang++ \
    cmake \
    -DCMAKE_BUILD_TYPE=release \
    -DANDROID=true \
    -DCMAKE_SYSTEM_NAME="Android" \
    -DCMAKE_ANDROID_API=${TARGET_API} \
    -DCMAKE_ANDROID_STANDALONE_TOOLCHAIN=${NDK_TOOL_DIR} \
    -DCMAKE_ANDROID_ARCH_ABI=${ARCH_ABI} \
    -DBUILD_SHARED_LIBS=ON \
    -DBoost_USE_STATIC_LIBS=ON \
    -DBoost_USE_STATIC_RUNTIME=ON ..

RUN cmake --build .
RUN make .

WORKDIR ${JLIB_BUILD_PATH}
RUN cp ${CLIB_BUILD_PATH}/libmonero-cpp.so ${JLIB_BUILD_PATH}

RUN JAVA_HOME=`dirname $(dirname $(readlink -f $(which javac)))` && \
    CC=${TARGET_HOST}-clang CXX=${TAhRGET_HOST}-clang++ \
    cmake \
    -DCMAKE_BUILD_TYPE=release \
    -DANDROID=true \
    -DCMAKE_SYSTEM_NAME="Android" \
    -DCMAKE_ANDROID_API=${TARGET_API} \
    -DCMAKE_ANDROID_STANDALONE_TOOLCHAIN=${NDK_TOOL_DIR} \
    -DCMAKE_ANDROID_ARCH_ABI=${ARCH_ABI} \
    ..

RUN cmake --build .
RUN make .

WORKDIR /out
RUN mv ${JLIB_BUILD_PATH}/*.so ./

ENTRYPOINT ["/bin/bash"]
