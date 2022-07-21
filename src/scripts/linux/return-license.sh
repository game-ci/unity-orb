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
  -username "$unity_username" \
  -password "$unity_password" \
  -logfile /dev/stdout
set +x