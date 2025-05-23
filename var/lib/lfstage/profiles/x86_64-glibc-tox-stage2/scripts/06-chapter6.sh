#!/usr/bin/env bash
# Script to build chapter 6 of LFS

# shellcheck disable=SC2086,SC2164,SC1091,SC2046
# TODO: Consider disabling acl and xattrs
# TODO: Disable rpath, nls, and assert where available

source "$ENVS/build.env"
cd "$LFS/sources"

# 6.2. M4
pre m4

export BUILD="$(build-aux/config.guess)"

./configure --prefix=/usr       \
            --host=$LFS_TGT     \
            --build=$BUILD      \
            --disable-nls       \
            --disable-rpath     \
            --disable-assert    \
            --with-packager=Tox
make
make DESTDIR=$LFS install

post m4


# 6.3. Ncurses
pre ncurses

mkdir build
pushd build
  ../configure AWK=gawk
  make -C include
  make -C progs tic
popd

_cfg=(
    --prefix=/usr
    --host=$LFS_TGT
    --build=$BUILD
    --without-manpages
    --with-shared
    --without-tests
    --with-cxx-shared
    --without-normal
    --without-debug
    --without-develop
    --without-profile
    --without-dlsym
    --without-ada
    --disable-stripping
    --disable-home-terminfo
    AWK=gawk
)

./configure "${_cfg[@]}"

unset _cfg

make
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h

post ncurses


# 6.4. Bash
pre bash

_cfg_opts=(
    --prefix=/usr
    --build=$BUILD
    --host=$LFS_TGT
    --without-bash-malloc
    --disable-bang-history
    --disable-nls
    --disable-rpath
)

./configure "${_cfg_opts[@]}"

unset _cfg

make
make DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh

post bash


# 6.5. Coreutils
pre coreutils

./configure --prefix=/usr                       \
            --host=$LFS_TGT                     \
            --build=$BUILD                      \
            --with-packager=Tox                 \
            --disable-assert                    \
            --disable-rpath                     \
            --disable-nls                       \
            --disable-systemd                   \
            --enable-single-binary=symlinks     \
            --enable-install-program=hoshtname  \
            --enable-no-install-program=kill,uptime
make
make DESTDIR=$LFS install

mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8

post coreutils


# 6.6. Diffutils
pre diffutils

./configure --prefix=/usr                   \
            --host=$LFS_TGT                 \
            --build=$BUILD                  \
            --disable-rpath                 \
            --disable-nls                   \
            gl_cv_func_strcasecmp_works=y
make
make DESTDIR=$LFS install

post diffutils


# 6.7. File
pre file

_cfg=(
    --disable-libseccomp
    --disable-zlib
    --disable-bzlib
    --disable-xzlib
    --disable-lzlib
    --disable-zstdlib
    --disable-lrziplib
    --disable-shared
    --disable-static
)

mkdir -v build
pushd build
    ../configure "${_cfg[@]}"
    make
popd

./configure "${_cfg[@]}"    \
    --prefix=/usr           \
    --host=$LFS_TGT         \
    --build=$BUILD          \
    --enable-shared         \
    --datadir=/usr/share/file

unset _cfg

make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la

post file


# 6.8. Findutils
pre findutils

./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$BUILD                  \
            --disable-assert                \
            --disable-nls                   \
            --disable-rpath                 \
            --with-packager=Tox
make
make DESTDIR=$LFS install

post findutils


# 6.9. Gawk
pre gawk

sed -i 's/extras//' Makefile.in
# WARN: --disable-lint may be problematic(?)
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$BUILD  \
            --disable-lint  \
            --disable-nls   \
            --disable-rpath
make
make DESTDIR=$LFS install

post gawk


# 6.10. Grep
pre grep

./configure --prefix=/usr       \
            --host=$LFS_TGT     \
            --build=$BUILD      \
            --disable-assert    \
            --disable-nls       \
            --disable-rpath     \
            --with-packager=Tox
make
make DESTDIR=$LFS install

post grep


# 6.11. Gzip
pre gzip

./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install

post gzip


# 6.12. Make
pre make

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$BUILD  \
            --disable-nls   \
            --disable-rpath
make
make DESTDIR=$LFS install

post make


# 6.13. Patch
pre patch

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$BUILD  \
            --disable-xattr
make
make DESTDIR=$LFS install

post patch


# 6.14. Sed
pre sed

./configure --prefix=/usr       \
            --host=$LFS_TGT     \
            --build=$BUILD      \
            --disable-acl       \
            --disable-i18n      \
            --disable-assert    \
            --disable-nls       \
            --disable-rpath     \
            --with-packager=Tox
make
make DESTDIR=$LFS install

post sed


# 6.15. Tar
pre tar

./configure --prefix=/usr       \
            --host=$LFS_TGT     \
            --build=$BUILD      \
            --disable-acl       \
            --disable-nls       \
            --disable-rpath     \
            --without-xattrs    \
            --with-packager=Tox
make
make DESTDIR=$LFS install

post tar


# 6.16. Xz
pre xz

./configure --prefix=/usr           \
            --host=$LFS_TGT         \
            --build=$BUILD          \
            --disable-microlzma     \
            --disable-lzip-decoder  \
            --enable-small          \
            --enable-threads=posix  \
            --disable-lzmadec       \
            --disable-lzmainfo      \
            --disable-lzma-links    \
            --disable-scripts       \
            --disable-doc           \
            --disable-nls           \
            --disable-rpath         \
            --disable-static
make
make DESTDIR=$LFS install

rm -v $LFS/usr/lib/liblzma.la

post xz


# 6.17. Binutils - Pass 2
pre binutils

sed '6031s/$add_dir//' -i ltmain.sh

mkdir -v build
cd       build

../configure            \
    --prefix=/usr       \
    --build=$BUILD      \
    --host=$LFS_TGT     \
    --disable-nls       \
    --enable-shared     \
    --disable-gprofng   \
    --disable-werror    \
    --enable-64-bit-bfd \
    --enable-new-dtags  \
    --enable-default-hash-style=gnu
make
make DESTDIR=$LFS install

rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

post binutils


# 6.18. GCC - Pass 2
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

../configure                                    \
    --build=$BUILD                              \
    --host=$LFS_TGT                             \
    --target=$LFS_TGT                           \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc   \
    --prefix=/usr                               \
    --with-build-sysroot=$LFS                   \
    --enable-default-pie                        \
    --enable-default-ssp                        \
    --disable-nls                               \
    --disable-multilib                          \
    --disable-libatomic                         \
    --disable-libgomp                           \
    --disable-libquadmath                       \
    --disable-libsanitizer                      \
    --disable-libssp                            \
    --disable-libvtv                            \
    --enable-languages=c,c++

make
make DESTDIR=$LFS install

ln -sfv gcc $LFS/usr/bin/cc

post gcc
