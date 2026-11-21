#!/bin/bash
# Builds the FFmpeg sound decoders Encore Cinema uses (DTS incl. DTS-HD MA, TrueHD/MLP) and media3's JNI bridge
# (src/main/jni/ffmpeg_jni.cc) into libffmpegJNI.so for each Android ABI, on a Linux PC:
#   bash build-ffmpeg-linux.sh <ffmpeg-6.0.x source dir> <android-ndk-r26b dir> <out dir>
# Then copy <out dir>/<abi>/libffmpegJNI.so into src/main/jniLibs/<abi>/.
#
# LICENCE: FFmpeg is configured WITHOUT --enable-gpl / --enable-nonfree, so the result is LGPL 2.1+. It's linked
# into libffmpegJNI.so; to meet the LGPL, the FFmpeg source used, this script and the JNI source (Apache 2.0) are
# published so anyone can rebuild/relink it. Never add --enable-gpl here.
#
# Based on media3 1.9.0's libraries/decoder_ffmpeg/src/main/jni/build_ffmpeg.sh (Apache 2.0).
set -eu
FFMPEG="$(cd "$1" && pwd)"; NDK="$(cd "$2" && pwd)"; OUT="$(mkdir -p "$3" && cd "$3" && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
API=26   # = the app's minSdk
DECODERS=(dca truehd mlp)
TC="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
JOBS="$(nproc)"
OPTS="--target-os=android --enable-static --disable-shared --disable-doc --disable-programs --disable-everything
  --disable-avdevice --disable-avformat --disable-swscale --disable-postproc --disable-avfilter --disable-symver
  --enable-swresample --disable-v4l2-m2m --disable-vulkan --disable-network --disable-autodetect"
for d in "${DECODERS[@]}"; do OPTS="$OPTS --enable-decoder=$d"; done

build() {   # abi arch cpu triple extra-configure-flags...
  local abi="$1" arch="$2" cpu="$3" triple="$4"; shift 4
  echo "=== $abi"
  cd "$FFMPEG"
  make distclean >/dev/null 2>&1 || true
  ./configure --prefix="$OUT/build/$abi" --arch="$arch" --cpu="$cpu" --cross-prefix="$TC/$triple$API-" \
    --cc="$TC/$triple$API-clang" --cxx="$TC/$triple$API-clang++" \
    --nm="$TC/llvm-nm" --ar="$TC/llvm-ar" --ranlib="$TC/llvm-ranlib" --strip="$TC/llvm-strip" \
    --extra-cflags="-fPIC" "$@" $OPTS >/dev/null
  grep -q 'FFMPEG_LICENSE "LGPL' config.h || { echo "FFmpeg isn't configured as LGPL: stopping"; exit 1; }
  make -j"$JOBS" >/dev/null
  make install-libs install-headers >/dev/null
  local L="$OUT/build/$abi/lib" extra=""
  [ "$abi" = arm64-v8a ] && extra="-Wl,-Bsymbolic"
  mkdir -p "$OUT/$abi"
  "$TC/$triple$API-clang++" -std=c++11 -O2 -fPIC -shared -I"$OUT/build/$abi/include" "$HERE/src/main/jni/ffmpeg_jni.cc" \
    -o "$OUT/$abi/libffmpegJNI.so" "$L/libswresample.a" "$L/libavcodec.a" "$L/libavutil.a" \
    -landroid -llog -lm -static-libstdc++ -Wl,--gc-sections -Wl,-z,max-page-size=16384 $extra
  "$TC/llvm-strip" --strip-unneeded "$OUT/$abi/libffmpegJNI.so"
  echo "    $(du -h "$OUT/$abi/libffmpegJNI.so" | cut -f1)  $(grep -o 'FFMPEG_LICENSE "[^"]*"' config.h)"
}

build armeabi-v7a arm armv7-a armv7a-linux-androideabi --extra-ldflags="-Wl,--fix-cortex-a8"
build arm64-v8a aarch64 armv8-a aarch64-linux-android
build x86 x86 i686 i686-linux-android --disable-asm
build x86_64 x86_64 x86-64 x86_64-linux-android --disable-asm
echo "Done: $OUT/<abi>/libffmpegJNI.so"
