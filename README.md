# FFmpeg for PalaceRef

This fork of [BtbN/FFmpeg-Builds](https://github.com/BtbN/FFmpeg-Builds) builds the FFmpeg that
PalaceRef ships: BtbN's `win64` `lgpl-shared` `8.1` build, from the same recipes, with four changes
on the `palaceref` branch:

- **No GPL code in LGPL builds.** BtbN's LGPL variants linked FFTW (GPL, through chromaprint) into
  `avformat` and a GPL-2.0-only zvbi file into `avcodec`. `scripts.d/25-fftw3.sh`,
  `50-chromaprint.sh` and `50-zvbi.sh` are disabled for LGPL variants, as BtbN does for its other
  GPL-only libraries; FFmpeg is configured with `--disable-chromaprint --disable-libzvbi`.
- **Pinned.** FFmpeg is built from the `n8.1.3` tag (`addins/8.1.sh`), not the branch head;
  crosstool-NG and Rust are pinned to what BtbN used on 2026-09-24; every library stays at the
  commit its `scripts.d` stage pins.
- **Upstream fixes.** `patches/ffmpeg/<tag>` holds FFmpeg commits from upstream `master` that the
  tag lacks, as `git format-patch` files; `build.sh` applies them, uncommitted, so the version stays
  the tag's. For `n8.1.3`, three D3D12 decoder fixes: it sizes its bitstream buffers to each
  frame (`af4bfe85e456` for AV1's tile groups, then `9997fd060680`; each upload buffer was a whole
  uncompressed frame); its surfaces take the coded
  size, so NVIDIA decodes HEVC coded taller than shown, as NVENC's 3840x2176 for 2160p
  (`2e92077e2269`, backported without its P012 context); and hardware that needs reference-only
  surfaces no longer runs out of reference slots (`bcd2c69e087a`).
- **One build, kept.** `.github/workflows/palaceref.yml` builds only that variant, fails if FFTW,
  chromaprint or zvbi reach the binaries, and on a manual run with "Publish release" releases it
  with FFmpeg's source and every library's source (`source-*`). Releases are never pruned: each is
  the source offer for a PalaceRef version that shipped it.

To update FFmpeg, merge BtbN's `master`, change the tag in `addins/8.1.sh`, push, and run the
workflow with "Publish release"; then point PalaceRef's `scripts\ffmpeg-build.ps1` at the release.

The rest of this file is BtbN's.

# FFmpeg Static Auto-Builds

Static Windows (x86_64) and Linux (x86_64) Builds of ffmpeg master and latest release branch.

Windows builds are targetting Windows 7 and newer, provided UCRT is installed.
The minimum supported version is Windows 10 22H2, no guarantees on anything older.

Linux builds are targetting RHEL/CentOS 8 (glibc-2.28 + linux-4.18) and anything more recent.

## Auto-Builds

Builds run daily at 12:00 UTC (or GitHubs idea of that time) and are automatically released on success.

**Auto-Builds run ONLY for win(arm)64 and linux(arm)64. There are no win32/x86 auto-builds, though you can produce win32 builds yourself following the instructions below.**

### Release Retention Policy

- The last build of each month is kept for two years.
- The last 14 daily builds are kept.
- The special "latest" build floats and provides consistent URLs always pointing to the latest build.

## Package List

For a list of included dependencies check the scripts.d directory.
Every file corresponds to its respective package.

## How to make a build

### Prerequisites

* bash
* docker

### Build Image

* `./makeimage.sh target variant [addin [addin] [addin] ...]`

### Build FFmpeg

* `./build.sh target variant [addin [addin] [addin] ...]`

On success, the resulting zip file will be in the `artifacts` subdir.

### Targets, Variants and Addins

Available targets:
* `win64` (x86_64 Windows)
* `win32` (x86 Windows)
* `linux64` (x86_64 Linux, glibc>=2.28, linux>=4.18)
* `linuxarm64` (arm64 (aarch64) Linux, glibc>=2.28, linux>=4.18)

The linuxarm64 target will not build some dependencies due to lack of arm64 (aarch64) architecture support or cross-compiling restrictions.

* `davs2` and `xavs2`: aarch64 support is broken.
* `libmfx` and `libva`: Library for Intel QSV, so there is no aarch64 support.

Available variants:
* `gpl` Includes all dependencies, even those that require full GPL instead of just LGPL.
* `lgpl` Lacking libraries that are GPL-only. Most prominently libx264 and libx265.
* `nonfree` Includes fdk-aac in addition to all the dependencies of the gpl variant.
* `gpl-shared` Same as gpl, but comes with the libav* family of shared libs instead of pure static executables.
* `lgpl-shared` Same again, but with the lgpl set of dependencies.
* `nonfree-shared` Same again, but with the nonfree set of dependencies.

All of those can be optionally combined with any combination of addins:
* `4.4`/`5.0`/`5.1`/`6.0`/`6.1`/`7.0`/`7.1` to build from the respective release branch instead of master.
* `debug` to not strip debug symbols from the binaries. This increases the output size by about 250MB.
* `lto` build all dependencies and ffmpeg with -flto=auto (HIGHLY EXPERIMENTAL, broken for Windows, sometimes works for Linux)
