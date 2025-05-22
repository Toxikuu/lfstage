#!/bin/bash
# Actions performed in the LFS chroot

# shellcheck disable=SC2068

# 7.5. Creating Directories
mkdir -pv /{boot,home,mnt,opt}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /usr/{include,src}
mkdir -pv /usr/lib/locale
mkdir -pv /usr/share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/share/man/man{1..8}
mkdir -pv /var/{cache,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -vdm 0750 /root
install -vdm 1777 /tmp /var/tmp

# 7.6. Creating Essential Files and Symlinks
ln -sfv /proc/self/mounts /etc/mtab

cat > /etc/hosts << EOF
127.0.0.1  localhost lfstage
::1        localhost lfstage
EOF

cat > /etc/hostname << EOF
lfstage
EOF

cat > /etc/resolv.conf << EOF
nameserver 1.1.1.1
EOF

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

# Just to be safe
# shellcheck disable=SC1091
. /etc/profile
set -eu
cd /sources

# 7.7. Gettext-0.24
pre gettext

./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

post gettext


# 7.8. Bison-3.8.2
pre bison

./configure --prefix=/usr
make
make install

post bison


# 7.9. Perl-5.40.2
pre perl

sh Configure -des                                         \
             -D prefix=/usr                               \
             -D vendorprefix=/usr                         \
             -D useshrplib                                \
             -D privlib=/usr/lib/perl5/5.40/core_perl     \
             -D archlib=/usr/lib/perl5/5.40/core_perl     \
             -D sitelib=/usr/lib/perl5/5.40/site_perl     \
             -D sitearch=/usr/lib/perl5/5.40/site_perl    \
             -D vendorlib=/usr/lib/perl5/5.40/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.40/vendor_perl
make
make install

post perl


# 7.10. Python-3.13.3
pre Python

./configure --prefix=/usr           \
            --enable-shared         \
            --disable-test-modules  \
            --without-dtrace        \
            --without-valgrind      \
            --without-ensurepip
make
make install

post Python


# 7.11 Texinfo-7.2
pre texinfo

./configure --prefix=/usr
make
make install

post texinfo


# 7.12. Util-linux-2.41
pre util-linux

mkdir -pv /var/lib/hwclock

# WARN: Configure option divergence from LFS
_custom_cfg_opts=(
    # disable some utils
    --disable-bfs
    --disable-cramfs
    --disable-minix
    # --disable-cal
    # --disable-ul
    # --disable-wall
    # --disable-mesg
    --disable-rename
    --disable-more
)

./configure --libdir=/usr/lib      \
            --runstatedir=/run     \
            --disable-chfn-chsh    \
            --disable-login        \
            --disable-nologin      \
            --disable-su           \
            --disable-setpriv      \
            --disable-runuser      \
            --disable-pylibmount   \
            --disable-static       \
            --disable-liblastlog2  \
            --without-python       \
            ${_custom_cfg_opts[@]} \
            ADJTIME_PATH=/var/lib/hwclock/adjtime
make
make install

unset _custom_cfg_opts

post util-linux


# 8.10 Zstd-1.5.7 (anachronous)
pre zstd

make prefix=/usr
make prefix=/usr install
rm -vf /usr/lib/libzstd.a

post zstd


# Cleanup and junk removal
# Roughly corresponds to Chapter 7.13
# WARN: The removal of some of these may cause issues
(
    # remove temporary files
    rm -rf {,/var}/tmp/*

    # remove lfstage artifacts
    rm -rf /{tools,sources}
    rm -vf /chroot.sh
    rm -vf /etc/profile

    # remove documentation
    rm -rf /usr/share/{man,info,doc}/*

    # remove unused binaries
    rm -vf /usr/bin/tzselect
    rm -vf /usr/bin/{perl,bash,gawk}{bug,thanks}
    rm -vf /usr/bin/*zmore

    # remove idle
    rm -vf /usr/bin/idle3*
    rm -rf /usr/lib/python3.*/idlelib

    # remove libtool archives
    find /usr/{lib,libexec} -name '*.la' -exec rm -vf {} \;

    # remove stray readmes
    find / -type f -name 'README*' -exec rm -vf {} \;

    # remove batch scripts
    find / -type f -name '*.bat' -exec rm -vf {} \;

    # remove uncommon character encodings
    # (utf8 is built into glibc)
    find /usr/lib/gconv -type f  \
        ! -name 'ISO8859-1.so'   \
        ! -name 'UTF-16.so'      \
        ! -name 'UTF-32.so'      \
        ! -name 'gconv-modules*' \
        -exec rm -vf {} \;

    # remove unused locales
    find /usr/share/locale/ -type d \
        ! -name 'en*'   \
        -exec rm -vf {} \;
)

# Ephemeral file used to denote success
touch /good
