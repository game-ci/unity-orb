#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"

# Import "utils.sh".
eval "$SCRIPT_UTILS"

# Detect host OS.
detect-os

# Expand environment name variable parameters.
readonly unity_email="${!PARAM_UNITY_EMAIL_VAR_NAME}"
readonly unity_password="${!PARAM_UNITY_PASSWORD_VAR_NAME}"
readonly unity_serial="${!PARAM_UNITY_SERIAL_VAR_NAME}"

if [ "$PLATFORM" = "linux" ]; then eval "$SCRIPT_RETURN_LICENSE_LINUX";
elif [ "$PLATFORM" = "macos" ]; then eval "$SCRIPT_RETURN_LICENSE_MACOS";
elif [ "$PLATFORM" = "windows" ]; then eval "$SCRIPT_RETURN_LICENSE_WINDOWS";
fi
