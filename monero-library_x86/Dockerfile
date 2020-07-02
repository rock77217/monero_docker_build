FROM ubuntu:16.04 as builder

RUN apt-get update && apt-get install -y unzip automake build-essential curl file pkg-config git python libtool libtinfo5 xsltproc gperf openjdk-8-jdk maven

ENV CFLAGS='-fPIC'
ENV CXXFLAGS='-fPIC'

ARG JLIB_PATH=/monero-java
ARG JLIB_BUILD_PATH=${JLIB_PATH}/build
ARG CLIB_PATH=${JLIB_PATH}/external/monero-cpp
ARG CLIB_BUILD_PATH=${CLIB_PATH}/build
ARG CLIB_EXT_PATH=${CLIB_PATH}/external
ARG CLIB_EXTLIB_PATH=${CLIB_PATH}/external-libs
ARG XMR_CORE_PATH=${CLIB_EXT_PATH}/monero-core
RUN git config --global http.postBuffer 2000000000
ENV PREFIX /opt/android/prefix

# Clone monero git
RUN git clone https://github.com/monero-ecosystem/monero-java ${JLIB_PATH}
RUN git clone https://github.com/monero-ecosystem/monero-cpp ${CLIB_PATH}
RUN git clone https://github.com/monero-project/monero ${XMR_CORE_PATH}

WORKDIR /usr/local

#INSTALL cmake
ARG CMAKE_VERSION=3.14.6
ARG CMAKE_VERSION_DOT=v3.14
ARG CMAKE_HASH=4e8ea11cabe459308671b476469eace1622e770317a15951d7b55a82ccaaccb9
RUN set -ex \
    && curl -O -L --retry 5 https://cmake.org/files/${CMAKE_VERSION_DOT}/cmake-${CMAKE_VERSION}.tar.gz \
    && echo "${CMAKE_HASH}  cmake-${CMAKE_VERSION}.tar.gz" | sha256sum -c \
    && tar -xzf cmake-${CMAKE_VERSION}.tar.gz \
    && cd cmake-${CMAKE_VERSION} \
    && ./configure \
    && make \
    && make install

WORKDIR ${CLIB_EXT_PATH}

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
    && ./bootstrap.sh  --prefix=${PREFIX} \
    && ./b2 --build-type=minimal link=static runtime-link=static --with-chrono --with-date_time --with-filesystem --with-program_options --with-regex --with-serialization --with-system --with-thread --with-locale threading=multi threadapi=pthread cflags="$CFLAGS" cxxflags="$CXXFLAGS" install

ENV HOST_PATH=$PATH
ENV BOOST_ROOT ${PREFIX}

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

RUN cd openssl-sdk && \
    ./Configure linux-x86_64 --prefix=${PREFIX} --openssldir=${PREFIX} -fPIC && \
    make build_generated && \
    make libcrypto.a && \
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
    && ./configure --prefix=${PREFIX} --enable-static --disable-shared \
    && make -j4 \
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

WORKDIR ${CLIB_EXT_PATH}

# Sodium
ARG SODIUM_VERSION=1.0.18
ARG SODIUM_HASH=4f5e89fa84ce1d178a6765b8b46f2b6f91216677
RUN set -ex \
    && git clone https://github.com/jedisct1/libsodium.git -b ${SODIUM_VERSION} libsodium-sdk \
    && cd libsodium-sdk \
    && test `git rev-parse HEAD` = ${SODIUM_HASH} || exit 1 \
    && ./autogen.sh \
    && ./configure --prefix=${PREFIX} --enable-static --disable-shared \
    && make -j4 \
    && make install

ARG DIFF_PATH=/monero_docker_build
# Copy diffs
WORKDIR ${DIFF_PATH}
COPY *.diff ./

# Update Monero version
ARG MONERO_VERSION=v0.16.0.1
ARG MONERO_HASH=a498a1b4ce432941dee47d74c7e05bf87acd3ad6
WORKDIR ${XMR_CORE_PATH}
RUN set -ex && \
    git fetch --tags && \
    git checkout ${MONERO_VERSION} && \
    test `git rev-parse HEAD` = ${MONERO_HASH} || exit 1 && \
    git submodule init && git submodule update

ARG MONERO_CPP_VERSION=v0.3.3
ARG MONERO_CPP_HASH=5644876fe38814ea0bb376c8118e1469be9b4aa6
WORKDIR ${CLIB_PATH}
RUN set -ex && \
    git fetch --tags && \
    git checkout ${MONERO_CPP_VERSION} && \
    test `git rev-parse HEAD` = ${MONERO_CPP_HASH} || exit 1 && \
    git apply ${DIFF_PATH}/monero-cpp.diff

ARG MONERO_JAVA_VERSION=v0.3.3
ARG MONERO_JAVA_HASH=b0518f5abe058eddb9bda97ed0ff90a78879155e
WORKDIR ${JLIB_PATH}
RUN set -ex && \
    git fetch --tags && \
    git checkout ${MONERO_JAVA_VERSION} && \
    test `git rev-parse HEAD` = ${MONERO_JAVA_HASH} || exit 1 && \
    git apply ${DIFF_PATH}/monero-java.diff

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
RUN cp ${JAVA_HOME}/include/linux/jni_md.h ${JAVA_HOME}/include/
RUN mvn install

# Build Monero
ENV PATH=${HOST_PATH}
WORKDIR ${XMR_CORE_PATH}
RUN sed -i 's/option(BUILD_GUI_DEPS "Build GUI dependencies." OFF)/option(BUILD_GUI_DEPS "Build GUI dependencies." ON)/g' CMakeLists.txt 
ENV CMAKE_INCLUDE_PATH="${PREFIX}/include"
ENV CMAKE_LIBRARY_PATH="${PREFIX}/lib"
ENV USE_SINGLE_BUILDDIR=1
RUN make release-static -j4 && \
    make release-static -j4

# Copy libs
WORKDIR ${CLIB_EXTLIB_PATH}
RUN mkdir boost openssl libsodium
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

RUN find ${PREFIX}/lib -name "libsodium.a" -exec cp {} ${CLIB_EXTLIB_PATH}/libsodium \;

WORKDIR ${CLIB_BUILD_PATH}

RUN cmake \
    -DCMAKE_BUILD_TYPE=release \
    -DBUILD_SHARED_LIBS=ON \
    -DBoost_USE_STATIC_LIBS=ON \
    -DBoost_USE_STATIC_RUNTIME=ON ..

RUN cmake --build .
RUN make .

WORKDIR ${JLIB_BUILD_PATH}
RUN cp ${CLIB_BUILD_PATH}/libmonero-cpp.so ${JLIB_BUILD_PATH}

RUN JAVA_HOME=`dirname $(dirname $(readlink -f $(which javac)))` && \
    cmake -DCMAKE_BUILD_TYPE=release ..

RUN cmake --build .
RUN make .

WORKDIR /out
RUN mv ${JLIB_BUILD_PATH}/*.so ./

ENTRYPOINT ["/bin/bash"]

