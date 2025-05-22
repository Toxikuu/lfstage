#!/bin/bash
# Script to fetch sources for lfstage

# shellcheck disable=SC1091
source /usr/share/lfstage/envs/base.env

LFSTAGE_SOURCES="/var/tmp/lfstage/sources"
LFSTAGE_SOURCES_TXT="/var/tmp/lfstage/sources.txt"

SOURCE_URLS=(
    "https://ftp.gnu.org/gnu/bash/bash-5.2.37.tar.gz"
    "https://sourceware.org/pub/binutils/releases/binutils-2.44.tar.xz"
    "https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz"
    "https://ftp.gnu.org/gnu/coreutils/coreutils-9.7.tar.xz"
    "https://ftp.gnu.org/gnu/diffutils/diffutils-3.12.tar.xz"
    "https://astron.com/pub/file/file-5.46.tar.gz"
    "https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz"
    "https://ftp.gnu.org/gnu/gawk/gawk-5.3.2.tar.xz"
    "https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz"
    "https://ftp.gnu.org/gnu/gettext/gettext-0.25.tar.xz"
    "https://ftp.gnu.org/gnu/glibc/glibc-2.41.tar.xz"
    "https://www.linuxfromscratch.org/patches/lfs/development/glibc-2.41-fhs-1.patch"
    "https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz"
    "https://ftp.gnu.org/gnu/grep/grep-3.12.tar.xz"
    "https://ftp.gnu.org/gnu/gzip/gzip-1.14.tar.xz"
    "https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.14.6.tar.xz"
    "https://ftp.gnu.org/gnu/m4/m4-1.4.20.tar.xz"
    "https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz"
    "https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz"
    "https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz"
    "https://invisible-mirror.net/archives/ncurses/ncurses-6.5.tar.gz"
    "https://ftp.gnu.org/gnu/patch/patch-2.8.tar.xz"
    "https://www.cpan.org/src/5.0/perl-5.40.2.tar.xz"
    "https://www.python.org/ftp/python/3.13.3/Python-3.13.3.tar.xz"
    "https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz"
    "https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz"
    "https://ftp.gnu.org/gnu/texinfo/texinfo-7.2.tar.xz"
    "https://www.kernel.org/pub/linux/utils/util-linux/v2.41/util-linux-2.41.tar.xz"
    "https://github.com//tukaani-project/xz/releases/download/v5.8.1/xz-5.8.1.tar.xz"
    "https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz"
)

# Write sources list
printf "%s\n" "${SOURCE_URLS[@]}" > "$LFSTAGE_SOURCES_TXT"

msg "Fetching sources"
# Fetch without overwriting, continuing, prefixed to $LFSTAGE_SOURCES, from the
# list $LFSTAGE_SOURCES_TXT
wget -c --no-clobber -P "$LFSTAGE_SOURCES" -i "$LFSTAGE_SOURCES_TXT"

# Copy sources
mkdir -v      "$LFS/sources"
chmod -v a+wt "$LFS/sources"

# Create a list of registered sources, and delete all unregistered files in the
# source directory.
# TODO: Consider oxidizing as rust might be better suited for this
registered_sources=()
pushd "${LFSTAGE_SOURCES}" &>/dev/null

# Register sources
for url in "${SOURCE_URLS[@]}"; do
    registered_sources+=("$(basename "$url")")
done

# Delete unregistered files
for file in *; do
    [[ -f "$file" ]] || continue  # skip directories or weird stuff
    if [[ ! " ${registered_sources[*]} " =~ " $file " ]]; then
        echo "Deleting unregistered source: $file" >&2
        rm -vf "$file"
    fi
done
popd &>/dev/null

# Copy sources to the chroot
cp -vf "$LFSTAGE_SOURCES/"* "$LFS/sources"
msg "Fetched all sources"
