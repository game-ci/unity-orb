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

# Returning "true" after activation to bypass misleading exit code 1
"$UNITY_EDITOR" -batchmode -manualLicenseFile "$TMP_UNITY_LICENSE_FILE" -logfile "$UNITY_ACTIVATION_LOG" || true
if [[ "$PARAM_VERBOSE" -eq 1 ]]; then cat "$UNITY_ACTIVATION_LOG"; fi

if grep "License file loaded" "$UNITY_ACTIVATION_LOG" && grep "Next license update check is after" "$UNITY_ACTIVATION_LOG"; then
    stdmsg "Unity activated successfully."
else
    errmsg "Error activating Unity."
    errmsg "Run the job with \"verbose\" set to true for more details or try generating the license again."
    exit 1
fi