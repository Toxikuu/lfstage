#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR"/../envs/base.env
source "$SCRIPT_DIR"/../envs/prechroot.env
SOURCES="$LFS/sources"


### BINUTILS PASS 1
pre binutils
mkdir -pv build
cd        build

../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-default-hash-style=gnu \
             --enable-multilib

make
make install
post binutils


### GCC PASS 1
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

mkdir -v build
cd       build

mlist=m64,m32
CFLAGS="-Oz"                                       \
CXXFLAGS="${CFLAGS}"                               \
../configure                                       \
    --target=$LFS_TGT                              \
    --prefix=$LFS/tools                            \
    --with-glibc-version=2.40                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --enable-initfini-array                        \
    --disable-nls                                  \
    --disable-shared                               \
    --enable-multilib --with-multilib-list=$mlist  \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++

make
make install

cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h

post gcc


## LINUX API HEADERS
pre linux

make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr

post linux


### GLIBC
pre glibc
ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3

patch -Np1 -i ../glibc-2.40-fhs-1.patch
mkdir -v build
cd       build

echo "rootsbindir=/usr/sbin" > configparms

CFLAGS="-Oz -fno-common"                 \
CXXFLAGS="${CFLAGS}"                     \
../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=6.11               \
      --with-headers=$LFS/usr/include    \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib

[ -z "$LFS" ] && { echo 'How the fuck have you made it this far with $LFS still unset' ; exit 1 ;}
make
make DESTDIR=$LFS install

sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

aout=$(
  echo 'int main(){}' | $LFS_TGT-gcc -xc -
  readelf -l a.out | grep ld-linux
)

if [[ "$aout" == *"[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]"* ]]; then
  echo 'Cross compiler is working'
else
  echo 'Cross compiler is not working!!' >&2
  exit 1
fi

rm -v a.out

make clean
find .. -name "*.a" -delete

CFLAGS="-Oz -fno-common"                 \
CXXFLAGS="${CFLAGS}"                     \
CC="$LFS_TGT-gcc -m32"                   \
CXX="$LFS_TGT-g++ -m32"                  \
../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT32                  \
      --build=$(../scripts/config.guess) \
      --enable-kernel=5.4                \
      --with-headers=$LFS/usr/include    \
      --disable-nscd                     \
      --libdir=/usr/lib32                \
      --libexecdir=/usr/lib32            \
      libc_cv_slibdir=/usr/lib32

make
make DESTDIR=$PWD/DESTDIR install
cp -a DESTDIR/usr/lib32 $LFS/usr/
install -vm644 DESTDIR/usr/include/gnu/{lib-names,stubs}-32.h \
               $LFS/usr/include/gnu/
ln -svf ../lib32/ld-linux.so.2 $LFS/lib/ld-linux.so.2

aout=$(
  echo 'int main(){}' > dummy.c
  $LFS_TGT-gcc -m32 dummy.c
  readelf -l a.out | grep '/ld-linux'
)

if [[ "$aout" == *"[Requesting program interpreter: /lib/ld-linux.so.2]"* ]]; then
  echo 'm32 cross compiler is working'
else
  echo 'm32 cross compiler is not working!!' >&2
  exit 1
fi

post glibc


### LIBSTDC++
pre gcc
mkdir -v build
cd       build

../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --enable-multilib               \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0

make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la
post gcc


### END CHAPTER 5
