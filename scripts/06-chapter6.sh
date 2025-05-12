#!/usr/bin/env bash
# Script to build chapter 6 of LFS

# shellcheck disable=SC2086,SC2164,SC1091,SC2046
# TODO: Explicitly disable acl and xattrs

source /usr/share/lfstage/envs/base.env
source "${LFSTAGE_ENVS:?}/build.env"

cd "${LFS:?}/sources" || die "Failed to enter $LFS/sources"

# 6.2. M4-1.4.20
pre m4

./configure --prefix=/usr       \
            --host=${LFS_TGT:?} \
            --disable-rpath     \
            --disable-nls       \
            --disable-assert    \
            --build=$(build-aux/config.guess)
make
make DESTDIR=${LFS:?} install

post m4


# 6.3. Ncurses-6.5
pre ncurses

mkdir build
pushd build
  ../configure AWK=gawk
  make -C include
  make -C progs tic
popd

_cfg_opts=(
    --prefix=/usr
    --host=${LFS_TGT:?}
    --build=$(./config.guess)
    --mandir=/usr/share/man
    --with-manpage-format=normal
    --with-shared
    --without-normal
    --with-cxx-shared
    --without-debug
    --without-ada
    --disable-stripping
    AWK=gawk

    --without-develop
)

./configure ${_cfg_opts[@]}

make
make DESTDIR=${LFS:?} TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so ${LFS:?}/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i ${LFS:?}/usr/include/curses.h

post ncurses


# 6.4. Bash-5.2.37
pre bash

_cfg_opts=(
    --prefix=/usr
    --build=$(sh support/config.guess)
    --host=$LFS_TGT
    --without-bash-malloc

    --disable-nls
    --disable-rpath
)

./configure ${_cfg_opts[@]}

make
make DESTDIR="$LFS" install
ln -sv bash $LFS/bin/sh

post bash


# 6.5. Coreutils-9.7
pre coreutils

# WARN: Several programs are disabled. This may cause issues.
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-nls                     \
            --disable-rpath                   \
            --disable-assert                  \
            --enable-no-install-program=\
            hostname,\
            kill,\
            uptime,\
            vdir,\
            pinky,\
            hostid,\
            sha224sum,\
            sha384sum,\
            shred,\
            who,\
            nl
make
make DESTDIR=$LFS install

mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8

post coreutils


# 6.6. Diffutils-3.12
pre diffutils

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --disable-nls   \
            --disable-rpath \
            gl_cv_func_strcasecmp_works=y \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install

post diffutils


# 6.7. File-5.46
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


# 6.8. Findutils-4.10.0
pre findutils

./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --disable-nls                   \
            --disable-rpath                 \
            --disable-assert                \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

post findutils


# 6.9. Gawk-5.3.2
pre gawk

sed -i 's/extras//' Makefile.in
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --disable-nls   \
            --disable-rpath \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

post gawk


# 6.10. Grep-3.12
pre grep

./configure --prefix=/usr    \
            --host=$LFS_TGT  \
            --disable-nls    \
            --disable-rpath  \
            --disable-assert \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install

post grep


# 6.11. Gzip-1.14
pre gzip

./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install

post gzip


# 6.12. Make-4.4.1
pre make

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --disable-nls   \
            --disable-rpath \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

post make


# 6.13. Patch-2.8
pre patch

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

post patch


# 6.14. Sed-4.9
pre sed

./configure --prefix=/usr    \
            --host=$LFS_TGT  \
            --disable-assert \
            --disable-nls    \
            --disable-rpath  \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install

post sed


# 6.15. Tar-1.35
pre tar

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --disable-rpath \
            --disable-nls   \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

post tar


# 6.16. Xz-5.8.1
pre xz

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-rpath --disable-nls     \
            --disable-static
make
make DESTDIR=$LFS install

rm -v $LFS/usr/lib/liblzma.la

post xz


# 6.17. Binutils-2.44 - Pass 2
pre binutils

sed '6031s/$add_dir//' -i ltmain.sh

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
    --enable-new-dtags         \
    --enable-default-hash-style=gnu
make
make DESTDIR=$LFS install

rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

post binutils


# 6.18. GCC-14.2.0 - Pass 2
pre gcc

tar -xf ../mpfr-4.2.2.tar.xz
mv -v mpfr-4.2.2 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build
cd       build

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
    --disable-multilib                             \
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
