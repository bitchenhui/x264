#!/bin/sh

export PLATFORM="iPhoneOS"
export MIN_VERSION="10.0"
export SDK_VERSION="16.4"
export OUTPUT=$(pwd)/build
export ARCH="arm64"

function build_x264()
{
    unset DEVROOT SDKROOT CFLAGS CC CXX CPP CPPFLAGS CXXFLAGS LDFLAGS CFLAGS_FOR_TARGET
    export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer
    export SDKROOT=$DEVROOT/SDKs/${PLATFORM}${SDK_VERSION}.sdk
    export CFLAGS="-std=c99 -arch ${ARCH} -isysroot ${SDKROOT} -O3 -DNDEBUG -miphoneos-version-min=${MIN_VERSION}"
    # export LDFLAGS="-L${SDKROOT}/usr/lib/"
    export CC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
    export CXX=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
    
    make clean
    ./configure --host=aarch64-apple-darwin --sysroot=$SDKROOT --prefix="$OUTPUT/${PLATFORM}${SDK_VERSION}-${ARCH}.sdk" \
    --extra-cflags="-arch ${ARCH} -isysroot ${SDKROOT}" --extra-ldflags="-arch ${ARCH} ${LDFLAGS}" --enable-pic --enable-static
    make && make install
}
build_x264