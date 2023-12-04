#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_full_path="$base_dir/$PARAM_PROJECT_PATH"

# Import "utils.sh".
eval "$SCRIPT_UTILS"

# Detect host OS.
detect-os

# Expand environment name variable parameters.
readonly git_private_token="${!PARAM_GIT_PRIVATE_TOKEN}"

if [ "$PLATFORM" = "linux" ]; then eval "$SCRIPT_GIT_CREDENTIAL_LINUX";
elif [ "$PLATFORM" = "macos" ]; then eval "$SCRIPT_GIT_CREDENTIAL_MACOS";
elif [ "$PLATFORM" = "windows" ]; then eval "$SCRIPT_GIT_CREDENTIAL_WINDOWS";
fi
