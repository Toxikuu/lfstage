#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR"/../envs/base.env
source "$SCRIPT_DIR"/../envs/prechroot.env
SOURCES="$LFS/sources"

groupadd lfs || true
useradd -s /bin/bash -g lfs -m -k /dev/null lfs || true

chown -vR lfs $LFS

echo 'Becoming the lfs user' >&2

sudo -i -u lfs bash << EOF
"$SCRIPT_DIR/aslfs.sh"
EOF

echo 'Finished doing stuff as the lfs user' >&2
