#!/usr/bin/env bash
# Script to build chapter 7 of LFS

# shellcheck disable=SC2086,SC2164,SC1091

source "$LFSTAGE_ENVS/build.env"
cd "$LFS/sources" || die "Failed to enter $LFS/sources"


# Helper function for mounting
mount_if_needed() {

    local mount_target="${!#}"
    if mountpoint -q "$mount_target"; then
        echo "Skipping $mount_target as it's already mounted"
    else
        mount "$@" || return 1
    fi

}

# Chroot into $LFS
# NOTE: No partition or disk is mounted, we just chroot into the $LFS directory
mkdir -pv "$LFS"/{dev,proc,sys,run}

mount_if_needed -v --bind  /dev   "$LFS/dev"
mount_if_needed -vt devpts devpts -o gid=5,mode=0620 "$LFS/dev/pts"
mount_if_needed -vt proc   proc   "$LFS/proc"
mount_if_needed -vt sysfs  sysfs  "$LFS/sys"
mount_if_needed -vt tmpfs  tmpfs  "$LFS/run"

if [ -h $LFS/dev/shm ]; then
    install -vdm 1777 "$LFS$(realpath /dev/shm)"
else
    mount_if_needed -vt tmpfs -o nosuid,nodev tmpfs "$LFS/dev/shm"
fi

# Make some stuff available. These files will be deleted later.
cp -vf "$LFSTAGE_ENVS/build.env" "$LFS/etc/profile"
install -vm755 "$LFSTAGE_SHARED/scripts/libexec/chroot.sh" "$LFS/chroot.sh"

# NOTE: The environment variable specification in env is necessary for
# reasons entirely beyond my comprehension. Simply placing the exact same
# variables in /etc/profile to be sourced by bash does not suffice. An
# entirely identical environment (as tested with `declare` and `diff`), with
# the only difference being how that environment was reached, causes a
# critical failure in gcc. If you know why this happens, please tell me.
# UPDATE:
# This is most likely caused by some esoteric failure related to the
# temporary build of bash not liking profiles.
chroot "$LFS" /usr/bin/env -i \
    HOME=/root                    \
    TERM=xterm-256color           \
    PATH=/usr/bin:/usr/sbin       \
    SOURCES=/sources              \
    MAKEFLAGS=-j$(nproc)          \
    TESTSUITEFLAGS=-j$(nproc)     \
    /bin/bash --login -e /chroot.sh || die "Something failed in chroot" 7

# Unmount virtual kernel file systems
umount "$LFS/dev/shm" || true
umount "$LFS/dev/pts"
umount "$LFS/"{sys,proc,run,dev}

msg "Exited LFS chroot" >&2

# Sanity check
if [[ ! -e "$LFS/good" ]]; then
    die "Detected a failure in LFS chroot"
fi
rm -vf "$LFS/good"

# Sanity checks
if [[ "$LFS" != "/mnt/lfstage" ]]; then
    die "\$LFS isn't properly set" 33
fi

if ! lsblk | grep "$LFS" &>/dev/null; then
    die "Couldn't find '$LFS' in lsblk output"
fi

# Add custom files (preferring rsync)
if [ -d "/etc/lfstage/custom" ]; then
    if command -v rsync; then
        rsync -avHAX "/etc/lfstage/custom/" "$LFS/"
    else
        echo "Warning: rsync not installed, falling back to cp" >&2
        cp -avf "/etc/lfstage/custom/"* "$LFS/"
    fi
fi

# Mass strip
msg "Mass stripping..." >&2
find "$LFS" -type f -executable -exec file {} + |
    grep 'not stripped' |
    cut -d: -f1         |
    xargs strip -v --strip-unneeded
msg "Stripped!"

# Save
msg "Saving stage file..."
cd "$LFS"
XZ_OPT=-9e tar -cJpf "/var/tmp/lfstage/stages/lfstage@$TS.tar.xz" .

cd
umount -R "$LFS"
msg "Done!"
