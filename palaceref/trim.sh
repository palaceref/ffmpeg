#!/bin/bash
# PalaceRef's FFmpeg: BtbN's win64 LGPL shared build without the libraries that
# nothing running it reaches. util/vars.sh sources this; generate.sh asks
# stage_enabled, and addins/8.1.sh applies palaceref_configure.
#
# Kept whole: FFmpeg's own code (every native decoder, demuxer, muxer, parser,
# bitstream filter, protocol and filter). PalaceRef hands FFmpeg any file with a
# video extension, and yt-dlp and gallery-dl run ffmpeg on whatever a site
# serves, so any of it may be the one a file needs; the planned features (PSD,
# HEIF/AVIF, APNG, EXR/HDR, textures, more containers, atempo slow motion, bwdif
# deinterlacing, GIF/APNG export) use only native code. Kept libraries, each
# the default for some path:
#   dav1d      the AV1 decoder for software decoding and posters (AVIF stills)
#   zlib, xz   PNG, EXR and TIFF, compressed MP4/Matroska headers; LZMA TIFF
#   libxml2    DASH and IMF demuxers (yt-dlp's ffmpeg downloader), with libiconv
#   snappy     the native HAP decoder (HAP Alpha is transparent video)
#   uavs3d     the only AVS3 decoder
#   lcevcdec   LCEVC enhancement inside the H.264/HEVC decoders
#   libvpx     VP8/VP9 with alpha (transparent WebM), which FFmpeg's own
#              decoders drop; its encoders go with the others below
#   schannel   TLS, from Windows
PALACEREF_DROP=(
    # Encoders, and decoders FFmpeg never picks over its own (AV1 by aom,
    # H.264 by openh264, Opus, Vorbis, AMR, JPEG 2000, Theora): nothing
    # running this build encodes video or audio.
    aom kvazaar openh264 rav1e svtav1 vvenc openapv libwebp libmp3lame twolame
    libtheora libopus libvorbis opencore-amr openjpeg
    # Merges rav1e's and librsvg's Rust runtimes; both are gone.
    rustdedup
    # Text and subtitle rendering (drawtext, subtitles and ass filters, ARIB
    # captions): PalaceRef draws no text through FFmpeg; yt-dlp copies subtitles.
    fribidi fonts libass libaribb24 libaribcaption
    # Filters' libraries: OpenCL, Vulkan and libplacebo, VMAF, zscale, LV2
    # plugins, and the SoX resampler (swresample's own engine is the one used).
    opencl vulkan libplacebo vmaf zimg lilv soxr
    # Other vendors' GPU decoding and encoding; PalaceRef decodes with D3D12VA.
    amf ffnvcodec onevpl vaapi
    # Audio-only formats; PalaceRef plays files with a video stream.
    gme openmpt
    # Protocols nothing reaches: PalaceRef allows only files; yt-dlp uses file,
    # http(s), tcp, tls, crypto, data and rtmp. GMP served only rtmpe, OpenSSL
    # only these libraries (FFmpeg's TLS is Windows').
    libbluray libssh librist srt libzmq gmp openssl
    # JPEG XL and SVG: PalaceRef never sends these files to FFmpeg.
    libjxl librsvg
    # Devices and ffplay, which are not shipped.
    openal sdl
    # Linked only by the libraries above; FFmpeg's PNG codec is its own.
    libpng
)

# Whether a stage script (scripts.d/NN-name.sh, or a script in scripts.d/NN-name/)
# belongs to a stage PalaceRef drops.
palaceref_dropped() {
    local name="${1##*scripts.d/}"
    name="${name%%/*}"
    name="${name%.sh}"
    name="${name#[0-9][0-9]-}"
    [[ " ${PALACEREF_DROP[*]} " == *" $name "* ]]
}

# A stage's own ffbuild_enabled, less the stages PalaceRef drops. $SELF is the
# stage script, as generate.sh sets it before sourcing one.
stage_enabled() {
    palaceref_dropped "$SELF" && return 1
    ffbuild_enabled
}

# FFmpeg's configure for PalaceRef, after the variant's (addins/8.1.sh).
palaceref_configure() {
    # LGPL 2.1 or later: no kept library needs version 3.
    FF_CONFIGURE="${FF_CONFIGURE//--enable-version3/}"
    LICENSE_FILE="COPYING.LGPLv2.1"
    # Only what a stage enables: a library found on the build machine cannot
    # slip in, as FFTW did through chromaprint.
    FF_CONFIGURE+=" --disable-autodetect --enable-d3d12va"
    # PalaceRef decodes on the GPU with D3D12VA, the formats it can.
    FF_CONFIGURE+=" --disable-hwaccels --enable-hwaccel=av1_d3d12va,h264_d3d12va,hevc_d3d12va,mpeg2_d3d12va,vc1_d3d12va,vp9_d3d12va,wmv3_d3d12va"
    # Encoders: subtitles (yt-dlp converts them when it joins a video's parts),
    # GIF, APNG and PNG (exporting loops and frames), and the raw ones ffmpeg's
    # null and checksum outputs use (verifying a build).
    FF_CONFIGURE+=" --disable-encoders --enable-encoder=ass,ssa,dvbsub,dvdsub,movtext,srt,subrip,text,ttml,webvtt,xsub,gif,apng,png,rawvideo,wrapped_avframe,pcm_s16le"
    FF_CONFIGURE+=" --disable-avdevice --disable-ffplay"
    # iconv converts subtitle charsets (avcodec) and DVB service names in MPEG-TS
    # (avformat). The libraries whose links brought libiconv along are gone.
    FF_LIBS+=" -liconv"
}
