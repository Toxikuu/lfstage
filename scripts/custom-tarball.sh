#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")

source "$SCRIPT_DIR"/../envs/base.env

TARBALL="$1"
[ -z "$TARBALL" ] && { echo 'No custom tarball specified!' >&2 ; exit 0 ; } # exit 0 to continue anyways

cd "$LFS"
tar xvf "$SCRIPT_DIR"/../custom/"$TARBALL"

echo 'Extracted custom tarball' >&2
