#!/bin/bash

set -e

[ -z "$DISK" ]   && exit 1

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
