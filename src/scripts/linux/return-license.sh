#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

set -x
# Return license
xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' unity-editor \
  -quit \
  -batchmode \
  -nographics \
  -returnlicense \
  -username "$unity_username" \
  -password "$unity_password" \
  -logfile /dev/stdout
set +x