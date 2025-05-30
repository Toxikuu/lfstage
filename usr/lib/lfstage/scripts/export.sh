#!/bin/bash
set -euo pipefail
# Export the profile definition to a tarball
#
# shellcheck disable=2164

OUT="$(</tmp/lfstage/export)"

# Tarball up the profile
XZ_OPT=-9e tar cJpf "$OUT" -C "/var/lib/lfstage/profiles" "$LFSTAGE_PROFILE"
