#!/bin/bash
# Script to set up the lfstage build

# Sanity check
if [[ "$LFS" != "/mnt/lfstage" ]]; then 
    die "\$LFS isn't properly set" 33
fi

# Unmount elements of a previous lfstage build
if mountpoint -q "$LFS"/*; then
    umount -vR "$LFS"
fi

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
# NOTE: The loopback device is no longer used either
