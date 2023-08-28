    
###
 # @Author: zhangda
 # @Date: 2023-08-28 17:17:05
 # @LastEditors: 段晨辉 duanchenhui@xiaohongshu.com
 # @LastEditTime: 2023-08-28 17:31:25
 # @FilePath: /codeccmakebuild/x264enc/x264/x264_mac_build.sh
 # @Description: 
 # 
 # Copyright (c) 2023 by ${git_name_email}, All Rights Reserved. 
### 
#!/bin/sh
export CFLAGS="-std=c99 -arch ${ARCH} -O3"
export CC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
export CXX=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
export ARCH="arm64"

./configure --host=aarch64-apple-darwin --extra-cflags="-arch ${ARCH}" --enable-pic --enable-static
make clean
make && make install
make clean