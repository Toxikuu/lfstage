#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")

source "$SCRIPT_DIR"/../envs/base.env

SOURCES="$LFS/sources"

cp -vf "$SCRIPT_DIR"/../sources/* "$SOURCES"

download() {
  local url="$1"
  local filename=$(basename "$url")

  if [ ! -e "$SOURCES/$filename" ]; then
    echo "Downloading $filename..."
    wget -P "$SOURCES" "$url"
  else
    echo "SKIPPING: $filename already exists in $SOURCES"
  fi
}

# only packages needed for the stage2
links=(
  "https://ftp.gnu.org/gnu/bash/bash-5.2.37.tar.gz"
  "https://sourceware.org/pub/binutils/releases/binutils-2.43.1.tar.xz"
  "https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz"
  "https://ftp.gnu.org/gnu/coreutils/coreutils-9.5.tar.xz"
  "https://ftp.gnu.org/gnu/diffutils/diffutils-3.10.tar.xz"
  "https://astron.com/pub/file/file-5.46.tar.gz"
  "https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz"
  "https://ftp.gnu.org/gnu/gawk/gawk-5.3.1.tar.xz"
  "https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz"
  "https://ftp.gnu.org/gnu/gettext/gettext-0.23.tar.xz"
  "https://ftp.gnu.org/gnu/glibc/glibc-2.40.tar.xz"
  "https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz"
  "https://ftp.gnu.org/gnu/grep/grep-3.11.tar.xz"
  "https://ftp.gnu.org/gnu/gzip/gzip-1.13.tar.xz"
  "https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.12.1.tar.xz"
  "https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz"
  "https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz"
  "https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz"
  "https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.xz"
  "https://invisible-mirror.net/archives/ncurses/ncurses-6.5.tar.gz"
  "https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz"
  "https://www.cpan.org/src/5.0/perl-5.40.0.tar.xz"
  "https://www.python.org/ftp/python/3.13.1/Python-3.13.1.tar.xz"
  "https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz"
  "https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz"
  "https://ftp.gnu.org/gnu/texinfo/texinfo-7.1.1.tar.xz"
  "https://www.kernel.org/pub/linux/utils/util-linux/v2.40/util-linux-2.40.2.tar.xz"
  "https://github.com//tukaani-project/xz/releases/download/v5.6.3/xz-5.6.3.tar.xz"
  "https://www.linuxfromscratch.org/patches/lfs/development/glibc-2.40-fhs-1.patch"
)

for l in "${links[@]}"; do
  download "$l"
done

echo "Downloaded necessary files"
