#!/usr/bin/env bash
# Test script to build zstd
# Note the shebang isn't used

# shellcheck disable=SC1091

source "$ENVS/build.env"
cd "$LFS/sources" || die "Failed to enter $LFS/sources"


# 8.10 Zstd-1.5.7 (anachronous)
# Specialized build to only produce a binary capable of zst decompression,
# omitting support for everything else. Also optimized for size.
pre zstd

make -dC programs zstd-decompress
strip -s programs/zstd-decompress
make prefix=/usr DESTDIR="$LFS" install

post zstd

msg "Finished test build"
