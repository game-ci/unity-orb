#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_full_path="$base_dir/$PARAM_PROJECT_PATH"

# Import "utils.sh".
eval "$SCRIPT_UTILS"

# Detect host OS.
detect-os

# Expand custom parameters, if any.
custom_parameters="$(eval echo "$PARAM_CUSTOM_PARAMETERS")" && readonly custom_parameters

if [ "$PLATFORM" = "linux" ]; then eval "$SCRIPT_TEST_LINUX";
elif [ "$PLATFORM" = "macos" ]; then eval "$SCRIPT_TEST_MACOS";
elif [ "$PLATFORM" = "windows" ]; then eval "$SCRIPT_TEST_WINDOWS";
fi
