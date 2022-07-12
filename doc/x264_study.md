# 1.编译
mac平台debug x264 代码步骤  https://zhuanlan.zhihu.com/p/439996198

```shell
./configure --prefix=$HOME/Documents/ppcodec/codec_output/x264 --enable-static --disable-opencl --disable-win32thread --disable-interlaced --disable-asm --enable-debug --disable-avs --disable-swscale --disable-lavf --disable-ffms --disable-gpac --disable-lsmash
make
make install
```

测试命令行:
```shell
--input-res 1920x1080  -o /Users/chenhuiduan/Documents/ppcodec/x264/sequence/test.264 /Users/chenhuiduan/Documents/ppcodec/x264/sequence/Tennis+1920x1080.yuv
```
