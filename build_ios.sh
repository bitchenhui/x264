#!/bin/bash
# 设置环境变量
export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin:$PATH"
export CC="xcrun -sdk iphoneos clang -arch arm64 -mios-version-min=9.0"
export CXX="xcrun -sdk iphoneos clang++ -arch arm64 -mios-version-min=9.0"
export LD="xcrun -sdk iphoneos ld -arch arm64"

INSTALL_PATH=$(pwd)/build/ios

# 配置和编译x264
./configure --prefix=$INSTALL_PATH --disable-cli --enable-pic --host=aarch64-apple-darwin --extra-cflags="-arch arm64 -mios-version-min=9.0" --extra-ldflags="-arch arm64 -mios-version-min=9.0" --enable-shared --enable-static --bit-depth=8 --disable-interlaced --disable-opencl --disable-gpl --disable-avs --disable-swscale --disable-lavf --disable-ffms --disable-gpac --disable-lsmash

make -j8
make install
make clean