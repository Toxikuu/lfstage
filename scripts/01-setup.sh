#!/bin/bash
# Script to set up the lfstage build

# shellcheck disable=SC1091

source /usr/share/lfstage/envs/base.env

# Sanity check
if [[ "$LFS" != "/mnt/lfstage" ]]; then 
    echo "\$LFS isn't properly set" >&2
    exit 33
fi

LFSTAGE_IMG="/var/tmp/lfstage/lfstage.img"

# Set up a loopback device, or reuse an existing one
if [ -e "$LFSTAGE_IMG" ]; then
    msg "Reusing image"
else
    msg "Creating image -- this may take a while"
    dd if=/dev/zero of="${LFSTAGE_IMG:?}" bs=1M count=32768 # TODO: Make size configurable with minimum
    msg "Created image"
fi

# Unmount a previous lfstage build
umount -vR "${LFS:?}"

# Detach stale loopback devices
# https://tldr.inbrowser.app/pages/common/readarray
(
    readarray -t STALE_LFSTAGE_LOOPBACK_DEVICES < <(
        {
            mount | grep "${LFS:?}" | cut -d' ' -f1
            losetup -a | grep "${LFS:?}" | cut -d: -f1
        } | uniq
    )

    if [ "${#STALE_LFSTAGE_LOOPBACK_DEVICES[@]}" -gt 0 ]; then
        losetup -d "${STALE_LFSTAGE_LOOPBACK_DEVICES[@]}"
    fi
)

# Set up a loopback device, set its fs, and mount it
LOOPBACK_DEVICE="$(losetup -f "$LFSTAGE_IMG" --show)"
yes y | mkfs.ext4 -v "${LOOPBACK_DEVICE:?}"
mount -vm "$LOOPBACK_DEVICE" "$LFS"

# Sanity check
mount | grep "${LFS:?}" || die "Image not mounted"

# 4.2. Creating a Limited Directory Layout in the LFS Filesystem
rm -rf "${LFS:?}/"* # remove any stale files, and lost+found
mkdir -pv "$LFS"/{etc,var,tools} "$LFS"/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i "$LFS/$i"
done

case $(uname -m) in
  x86_64) mkdir -pv "$LFS/lib64" ;;
esac

msg "Populated image"

# NOTE: The LFS user is skipped
