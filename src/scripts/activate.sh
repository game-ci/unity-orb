#!/usr/bin/env bash

ENCODED_UNITY_LICENSE="${!PARAM_UNITY_LICENSE}"
TMP_UNITY_DIR=$(mktemp -d 'unity-orb.XXXXXX')
UNITY_ACTIVATION_LOG="$TMP_UNITY_DIR/activation.log"
UNITY_EDITOR="$UNITY_PATH/Editor/Unity"

stdmsg() {
    local IFS=' '
    printf '%s\n' "$*"
}

errmsg() {
    stdmsg "$*" 1>&2
}

trap_exit() {
  # It is critical that the first line capture the exit code. Nothing else can come before this.
  # The exit code recorded here comes from the command that caused the script to exit.
  local exit_status="$?"

  rm -rf "$TMP_UNITY_DIR"

  if [ "$exit_status" -ne 0 ]; then
    errmsg 'The script did not complete successfully.'
    errmsg 'The exit code was '"$exit_status"
  fi
}
trap trap_exit EXIT

if [[ -z "$ENCODED_UNITY_LICENSE" ]]; then
    errmsg "A Unity license file must be supplied. Check the \"license\" parameter."
    exit 1
fi

DECODED_UNITY_LICENSE=$(stdmsg "$ENCODED_UNITY_LICENSE" | base64 --decode)

# Writing the decoded license to a temporary file
TMP_UNITY_LICENSE_FILE="$TMP_UNITY_DIR/license.ulf"
touch "$TMP_UNITY_LICENSE_FILE"
chmod 0600 "$TMP_UNITY_LICENSE_FILE"

stdmsg "Writing the decoded license to \"${TMP_UNITY_LICENSE_FILE}\""
stdmsg "$DECODED_UNITY_LICENSE" > "$TMP_UNITY_LICENSE_FILE"

# The "true" is required post-command because it always return the exit code "1"
stdmsg "Activating Unity."
"$UNITY_EDITOR" \
 -batchmode \
 -logfile "$UNITY_ACTIVATION_LOG" \
 -manualLicenseFile "$TMP_UNITY_LICENSE_FILE" \
 || true

if [[ "$PARAM_VERBOSE" -eq 1 ]]; then cat "$UNITY_ACTIVATION_LOG"; fi

if grep "Next license update check is after" "$UNITY_ACTIVATION_LOG"; then
    stdmsg "Unity activated successfully."
else
    errmsg "Error activating Unity."
    errmsg "Run the job with \"verbose\" set to true for more details or try generating the license again."
    exit 1
fi