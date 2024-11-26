#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

set -x
# Return license
unity-editor \
  -quit \
  -batchmode \
  -nographics \
  -returnlicense \
  -username "$unity_email" \
  -password "$unity_password" \
  -serial "$unity_serial" \
  -logfile /dev/stdout
set +x
