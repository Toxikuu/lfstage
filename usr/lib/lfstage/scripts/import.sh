#!/bin/bash
set -euo pipefail
# Import the profile definition from a tarball
#
# shellcheck disable=2164

cd "/var/lib/lfstage/profiles"
IN="$(</tmp/lfstage/import)"

if [[ "$IN" = *"://"*.t*z* ]]; then
    curl -fL -# -C - --retry 3 -O "$IN"
elif [[ "$IN" = *"://"* ]]; then
    DIR="${IN%.git}"
    DIR="${DIR##*/}"
    DIR="${DIR%-lfstage}"
    rm -rf "$DIR"
    git clone --depth=1 "$IN" "$DIR"
    exit 0
fi

# Extract the tarball
tar xpf "$IN"
