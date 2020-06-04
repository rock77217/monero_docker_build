FROM ubuntu:16.04 as builder

RUN set -ex && \
    apt-get update && \
    apt-get --no-install-recommends --yes install \
        build-essential \
        ca-certificates \
        cmake \
        tofrodos \
        g++ \
        make \
        pkg-config \
        graphviz \
        doxygen \
        git \
        curl \
        libtool-bin \
        autoconf \
        automake \
        bzip2 \
        xsltproc \
        gperf \
        wget \
        python \
        unzip

WORKDIR /opt/android

# Prepare NDK
RUN set -ex && \
curl -O -L https://dl.google.com/android/repository/android-ndk-r17c-linux-x86_64.zip && \
unzip android-ndk-r17c-linux-x86_64.zip && \
mv android-ndk-r17c ndk

#RUN git clone https://github.com/Ryan4Work/xmrwallet -b custom_build
WORKDIR /opt/android/external-libs
#RUN rm -rf script
COPY . .

ENV TARGET_ARCHS="arm64 arm"
ENV DEFAULT_API=26

RUN make toolchain
RUN make libsodium
RUN make openssl
RUN make openssl_sysroot
RUN make boost
RUN make monero_dl
RUN ./script/monero-build.sh

WORKDIR /out/external-libs

RUN mkdir -p /out/external-libs/libsodium/lib/arm64-v8a && \
    cp /opt/android/xmrwallet/external-libs/build/build/libsodium/arm64/lib/*.a /out/external-libs/libsodium/lib/arm64-v8a/
RUN mkdir -p /out/external-libs/openssl/lib/arm64-v8a && \
    cp /opt/android/xmrwallet/external-libs/build/build/openssl/arm64/lib/*.a /out/external-libs/openssl/lib/arm64-v8a/
RUN mkdir -p /out/external-libs/boost/lib/arm64-v8a && \
    cp /opt/android/xmrwallet/external-libs/build/build/boost/arm64/lib/*.a /out/external-libs/boost/lib/arm64-v8a/
RUN mkdir -p /out/external-libs/monero/lib/arm64-v8a && \
    cp /opt/android/xmrwallet/external-libs/build/build/monero/arm64/lib/*.a /out/external-libs/monero/lib/arm64-v8a/

RUN mkdir -p /out/external-libs/libsodium/lib/armeabi-v7a && \
    cp /opt/android/xmrwallet/external-libs/build/build/libsodium/arm/lib/*.a /out/external-libs/libsodium/lib/armeabi-v7a/
RUN mkdir -p /out/external-libs/openssl/lib/armeabi-v7a && \
    cp /opt/android/xmrwallet/external-libs/build/build/openssl/arm/lib/*.a /out/external-libs/openssl/lib/armeabi-v7a/
RUN mkdir -p /out/external-libs/boost/lib/armeabi-v7a && \
    cp /opt/android/xmrwallet/external-libs/build/build/boost/arm/lib/*.a /out/external-libs/boost/lib/armeabi-v7a/
RUN mkdir -p /out/external-libs/monero/lib/armeabi-v7a && \
    cp /opt/android/xmrwallet/external-libs/build/build/monero/arm/lib/*.a /out/external-libs/monero/lib/armeabi-v7a/

RUN mkdir -p /out/external-libs/monero/include && \
    cp /opt/android/xmrwallet/external-libs/build/build/monero/include/* /out/external-libs/monero/include/

ENTRYPOINT [ "/bin/bash" ]
