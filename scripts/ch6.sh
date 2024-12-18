#!/bin/bash
# WARNING: AUTOMAKE 1.17 breaks things - use 1.16 
# WARNING: The above warning may or may not be obsolete

set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR"/../envs/base.env
source "$SCRIPT_DIR"/../envs/prechroot.env
SOURCES="$LFS/sources"

[ -z "$LFS" ] && exit 1

### M4
pre m4

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$LFS install

post m4


### NCURSES
pre ncurses

mkdir build
pushd build
  ../configure AWK=gawk
  make -C include
  make -C progs tic
popd

./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            AWK=gawk

make
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sfv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h

make distclean
CC="$LFS_TGT-gcc -m32"                \
CXX="$LFS_TGT-g++ -m32"               \
./configure --prefix=/usr             \
            --host=$LFS_TGT32         \
            --build=$(./config.guess) \
            --libdir=/usr/lib32       \
            --mandir=/usr/share/man   \
            --with-shared             \
            --without-normal          \
            --with-cxx-shared         \
            --without-debug           \
            --without-ada             \
            --disable-stripping
make

make DESTDIR=$PWD/DESTDIR TIC_PATH=$(pwd)/build/progs/tic install
ln -sfv libncursesw.so DESTDIR/usr/lib32/libncurses.so
cp -Rv DESTDIR/usr/lib32/* $LFS/usr/lib32
rm -rf DESTDIR

post ncurses


### BASH
pre bash

./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc
make
make DESTDIR=$LFS install
ln -sfv bash $LFS/bin/sh

post bash


### COREUTILS
pre coreutils

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime

make
make DESTDIR=$LFS install

mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8

post coreutils


### DIFFUTILS
pre diffutils

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

make
make DESTDIR=$LFS install

post diffutils


### FILE
pre file

mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd

./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)

make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la

post file


### FINDUTILS
pre findutils

./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

post findutils


### GAWK
pre gawk

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

post gawk


### GREP
pre grep

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install

post grep

### GZIP
pre gzip

./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install

post gzip


### MAKE
pre make

./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

post make


### PATCH
pre patch

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

post patch


### SED
pre sed

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install

post sed


### TAR
pre tar

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

post tar


### XZ
pre xz

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.6.3
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la

post xz


### BINUTILS PASS 2
pre binutils

sed '6009s/$add_dir//' -i ltmain.sh

mkdir -v build
cd       build

../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-default-hash-style=gnu \
    --enable-multilib

make
make DESTDIR=$LFS install

rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

post binutils


### GCC PASS 2
pre gcc

tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

sed -e '/m64=/s/lib64/lib/' \
    -e '/m32=/s/m32=.*/m32=..\/lib32$(call if_multiarch,:i386-linux-gnu)/' \
    -i.orig gcc/config/i386/t-linux64

sed '/STACK_REALIGN_DEFAULT/s/0/(!TARGET_64BIT \&\& TARGET_SSE)/' \
      -i gcc/config/i386/i386.h

sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build
cd       build

mlist=m64,m32
CFLAGS="-Oz"                                       \
CXXFLAGS="${CFLAGS}"                               \
../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --enable-multilib --with-multilib-list=$mlist  \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++

make
make DESTDIR=$LFS install

ln -sfv gcc $LFS/usr/bin/cc

post gcc


### END CHAPTER 6
