#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

set -x
# Return license
"$UNITY_EDITOR_PATH" \
  -quit \
  -batchmode \
  -nographics \
  -returnlicense \
  -username "$unity_username" \
  -password "$unity_password" \
  -logfile /dev/stdout
set +x