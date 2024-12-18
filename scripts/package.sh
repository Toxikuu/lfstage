#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR"/../envs/base.env

[ -z "$LFS" ] && exit 1


### STRIP
mass_strip() {
  cd "$1"

  binaries=()
  while IFS= read -r f; do
    binaries+=("$f")
  done < <(find . -type f -exec file {} \; | grep -i "not stripped" | cut -d':' -f1)

  for binary in "${binaries[@]}"; do
    echo "Stripping $binary..."
    strip --strip-all "$binary"
  done
}

mass_strip "$LFS/usr/bin"
mass_strip "$LFS/usr/sbin"
mass_strip "$LFS/usr/lib"
mass_strip "$LFS/usr/lib32"
mass_strip "$LFS/usr/libexec"
mass_strip "$LFS/usr/x86_64-lfs-linux-gnu/bin"


### UPX
mass_upx() {
  cd "$1"

  binaries=()
  while IFS= read -r f; do
    binaries+=("$f")
  done < <(find . -type f -exec file {} \; | grep -i "stripped" | cut -d':' -f1)

  for binary in "${binaries[@]}"; do
    echo "Packing $binary..."
    upx --best --lzma "$binary" || true
  done
}

mass_upx "$LFS/usr/bin"
mass_upx "$LFS/usr/sbin"
mass_upx "$LFS/usr/lib"
mass_upx "$LFS/usr/lib32"
mass_upx "$LFS/usr/libexec"
mass_upx "$LFS/usr/x86_64-lfs-linux-gnu/bin"


### CREATE STAGE2 TARBALL
rm -vf "$LFS"/chroot.{env,sh}
rm -rvf "$LFS"/tmp/extract
rm -rvf "$LFS"/sources/*

cd "$LFS"
XZ_OPT=-9e tar cJpvf lfs-stage2-$(date +%Y-%m-%d_%H-%M-%S).tar.xz . || true

mkdir -pv "$SCRIPT_DIR"/../../stages
mv -vf lfs-stage2-*.tar.xz "$SCRIPT_DIR"/../../stages
