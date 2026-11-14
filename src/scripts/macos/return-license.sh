#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

# Return license. No "set -x": the command contains the password.
"$UNITY_EDITOR_PATH" \
  -quit \
  -batchmode \
  -nographics \
  -returnlicense \
  -username "$unity_email" \
  -password "$unity_password" \
  -logfile - \
  | mask-serial
