#!/usr/bin/env bash
# Script to build chapter 7 of LFS

# shellcheck disable=SC2086,SC2164,SC1091

source /usr/share/lfstage/envs/base.env
source "${LFSTAGE_ENVS:?}/build.env"

cd "${LFS:?}/sources" || die "Failed to enter $LFS/sources"


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
#
# At this point, the loopback device should already be mounted on $LFS.
# Additionally, no ESP is used.

mkdir -pv "${LFS:?}/"{dev,proc,sys,run}

mount_if_needed -v --bind  /dev   "${LFS:?}/dev"
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
cp -vf "${LFSTAGE_ENVS:?}/build.env" "${LFS:?}/etc/profile"
install -vm755 "${LFSTAGE_SHARED:?}/scripts/libexec/chroot.sh" "${LFS:?}/chroot.sh"

# NOTE: The environment variable specification in env is necessary for
# reasons entirely beyond my comprehension. Simply placing the exact same
# variables in /etc/profile to be sourced by bash does not suffice. An
# entirely identical environment (as tested with `declare` and `diff`), with
# the only difference being how that environment was reached, causes a
# critical failure in gcc. If you know why this happens, please tell me.
# UPDATE:
# This is most likely caused by some esoteric failure related to the
# temporary build of bash not liking profiles.
chroot "${LFS:?}" /usr/bin/env -i \
    HOME=/root                    \
    TERM=xterm-256color           \
    PS1='(chroot) \u: \w\$'       \
    PATH=/usr/bin:/usr/sbin       \
    SOURCES=/sources              \
    MAKEFLAGS=-j$(nproc)          \
    TESTSUITEFLAGS=-j$(nproc)     \
    /bin/bash --login -e /chroot.sh || exit 1

umount "${LFS:?}/dev/shm" || true
umount "$LFS/dev/pts"
umount "$LFS/"{sys,proc,run,dev}

msg "Exited LFS chroot" >&2

# Sanity check
if [[ ! -e "${LFS:?}/good" ]]; then
    die "Detected a failure in LFS chroot"
fi
rm -vf "${LFS:?}/good"

# Sanity checks
if [[ "$LFS" != "/mnt/lfstage" ]]; then 
    echo "\$LFS isn't properly set" >&2
    exit 33
fi

if ! lsblk | grep "${LFS:?}" &>/dev/null; then
    echo "Couldn't find '$LFS' in lslbk output!"
    return 1
fi

# Mass strip
msg "Mass stripping..." >&2
find "${LFS:?}" -type f -executable -exec file {} + |
    grep 'not stripped' |
    cut -d: -f1         |
    xargs strip -v --strip-unneeded
msg "Stripped!"

# Save
msg "Saving stagefile..."
cd "${LFS:?}"
XZ_OPT=-9e tar -cJpf "/var/tmp/lfstage/stages/lfstage@${TS:?}.tar.xz" .

cd
umount -R "${LFS:?}"
losetup -d "$(mount | grep "${LFS:?}" | cut -d' ' -f1)"
msg "Done!"
