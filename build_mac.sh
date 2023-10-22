#!/bin/bash
###
 # @Author: zhangda
 # @Date: 2023-10-15 13:41:47
 # @LastEditors: bitchenhui 13261281092@163.com
 # @LastEditTime: 2023-10-22 10:24:10
 # @FilePath: /codecbuildtool/x264/build_mac.sh
 # @Description: 
 # 
 # Copyright (c) 2023 by ${git_name_email}, All Rights Reserved. 
### 
# 设置环境变量
export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin:$PATH"

# 获取CPU架构
CPU_ARCH=$(uname -m)
INSTALL_PATH=$(pwd)/build/mac/$CPU_ARCH
echo $INSTALL_PATH

# 配置和编译x264
if [ "$CPU_ARCH" == "arm64" ]; then
    # 编译适用于M1芯片的x264库
    HOST=aarch64-apple-darwin
else
    # 编译适用于Intel芯片的x264库
    HOST=x86_64-apple-darwin
fi

./configure --prefix=$INSTALL_PATH --enable-debug --enable-pic --host=$HOST --extra-cflags="-arch $CPU_ARCH" --extra-ldflags="-arch $CPU_ARCH" --enable-shared --enable-static --bit-depth=8 --disable-interlaced  --disable-opencl --disable-gpl --disable-avs --disable-swscale --disable-lavf --disable-ffms --disable-gpac --disable-lsmash

make -j8
make install
make clean