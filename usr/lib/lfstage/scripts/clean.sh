#!/bin/bash
# Script to clean up any artifacts of a previous LFStage build

# Sanity check
if [[ "$LFS" != "/var/lib/lfstage/mount" ]]; then 
    die "\$LFS isn't properly set: $LFS" 33
fi

# Unmount anything from a previous lfstage build
if mount | grep " on $LFS" -q; then
    umount -vR "$LFS"/*
fi

# Remove any stale files
rm -rf "${LFS:?}/"*
