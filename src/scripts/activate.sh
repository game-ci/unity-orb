#!/usr/bin/env bash

UNITY_EDITOR="$UNITY_PATH/Editor/Unity"
ENCODED_UNITY_LICENSE="${!PARAM_UNITY_LICENSE}"

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

# Can I assume the lib "base64" is available? Should I "command -v base64" first?
DECODED_UNITY_LICENSE=$(stdmsg "$ENCODED_UNITY_LICENSE" | base64 --decode)

# Saving decoded ULF to file and activating unity
TMP_UNITY_DIR=$(mktemp -d 'unity-orb.XXXXXX')
TMP_UNITY_LICENSE_FILE="$TMP_UNITY_DIR/license.ulf"
touch "$TMP_UNITY_LICENSE_FILE"
chmod 0600 "$TMP_UNITY_LICENSE_FILE"

stdmsg "Saving the decoded license in: ${TMP_UNITY_LICENSE_FILE}"
stdmsg "$DECODED_UNITY_LICENSE" > "$TMP_UNITY_LICENSE_FILE"

# Returning "true" after activation to bypass misleading exit code 1
"$UNITY_EDITOR" -batchmode -manualLicenseFile "$TMP_UNITY_LICENSE_FILE" -logfile "$TMP_UNITY_DIR/activation-log.txt" || true
if [[ "$PARAM_UNITY_VERBOSE" -eq 1 ]]; then cat "$TMP_UNITY_DIR/activation-log.txt"; fi

if grep "License file loaded" "$TMP_UNITY_DIR/activation-log.txt"; then
    stdmsg "Unity activated successfully."
else
    errmsg "Error activating Unity."
    errmsg "See more details by running with \"verbose\" set to true or try generating the license again."
    exit 1
fi