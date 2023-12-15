#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_full_path="$base_dir/$PARAM_PROJECT_PATH"

# Import "utils.sh".
eval "$SCRIPT_UTILS"

# Detect host OS.
detect-os

# Expand environment name variable parameters.
readonly unity_username="${!PARAM_UNITY_USERNAME_VAR_NAME}"
readonly unity_password="${!PARAM_UNITY_PASSWORD_VAR_NAME}"
readonly unity_serial="${!PARAM_UNITY_SERIAL_VAR_NAME}"
readonly unity_encoded_license="${!PARAM_UNITY_LICENSE_VAR_NAME}"

if [ "$PLATFORM" = "linux" ]; then eval "$SCRIPT_PREPARE_ENV_LINUX";
elif [ "$PLATFORM" = "macos" ]; then eval "$SCRIPT_PREPARE_ENV_MACOS";
elif [ "$PLATFORM" = "windows" ]; then eval "$SCRIPT_PREPARE_ENV_WINDOWS";
fi
