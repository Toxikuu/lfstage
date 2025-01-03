#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR"/../envs/base.env
SOURCES="$LFS/sources"

[ -z "$LFS" ] && exit 1

### CHOWN
chown -vR 0:0 $LFS

pushd "$LFS"
umount -vR . || true
popd


### PREPARE VIRTUAL KERNEL FILE SYSTEMS
mkdir -pv $LFS/{dev,proc,sys,run}
mount -v --bind /dev $LFS/dev
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi


### CHROOT
cp -vf "$SCRIPT_DIR/../envs/chroot.env" "$LFS"/chroot.env
cp -vf "$SCRIPT_DIR/chroot.sh" "$LFS"/chroot.sh
chroot $LFS /bin/bash -c "/chroot.sh"

echo "Exited chroot" >&2
sleep 5


### POST-CHROOT
[ -z "$LFS" ] && { echo '$LFS unset' >&2 ; exit 1 ; }

mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
umount $LFS/dev/pts
umount $LFS/{sys,proc,run,dev}


### CUSTOM-TARBALL
[ -z "$CUSTOM_TARBALL" ] || {
  "$SCRIPT_DIR"/custom-tarball.sh "$CUSTOM_TARBALL"
}


### PACKAGE
"$SCRIPT_DIR"/package.sh
