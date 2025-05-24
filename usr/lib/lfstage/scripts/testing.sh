#!/bin/bash
# Script used for testing LFStage's exec() function

set -o | grep -E '^(errexit|nounset|pipefail)'
ls

echo "that's all"
