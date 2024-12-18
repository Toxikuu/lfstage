#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR"/../envs/base.env
[ -z "$DISK" ]   && exit 1
[ -z "$LFS"  ]   && exit 1

### FORMAT DISK
echo "Detected disk '$DISK'"
echo "Determining partition names..."
if echo "$DISK" | grep -q "nvme"; then
  EFIPART="${DISK}p1"
  ROOTPART="${DISK}p2"
elif echo "$DISK" | grep -q "sda"; then
  EFIPART="${DISK}1"
  ROOTPART="${DISK}2"
else
  echo "Unsupported disk '$DISK'" >&2
  exit 1
fi

echo "Checking if partitions are mounted..."
for d in "$DISK"*[0-9]*; do
  if mount | grep -q "$d"; then
    echo "Unmounting $d..."
    umount "$d"
  fi
done
echo "Unmounted any mounted partitions"

echo "Formatting disk '$DISK'..."
wipefs --all "$DISK"
sfdisk "$DISK" << EOF
label: gpt
, 256M, U, *
, +, L
EOF

mkfs.vfat -F32  "$EFIPART"
mkfs.ext4 -v    "$ROOTPART"

echo "Formatted disk '$DISK'"


### CREATE LIMITED FILE HIERARCHY
mkdir -pv $LFS
mount -v -t ext4 $ROOTPART $LFS

rm -rvf $LFS/*

mkdir -v $LFS/sources

mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac

mkdir -pv $LFS/usr/lib32
ln -sv usr/lib32 $LFS/lib32

mkdir -pv $LFS/tools


### GET SOURCES
"$SCRIPT_DIR"/getsources.sh
