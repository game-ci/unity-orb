#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"

# Import "utils.sh".
eval "$SCRIPT_UTILS"

# Detect host OS.
detect-os

# Expand environment name variable parameters.
readonly unity_username="${!PARAM_UNITY_USERNAME_VAR_NAME}"
readonly unity_password="${!PARAM_UNITY_PASSWORD_VAR_NAME}"

if [ "$PLATFORM" = "linux" ]; then
  printf '%s\n' "$SCRIPT_RETURN_LICENSE_LINUX" > "$base_dir/return-license.sh"

elif [ "$PLATFORM" = "macos" ]; then
  printf '%s\n' "$SCRIPT_RETURN_LICENSE_MACOS" > "$base_dir/return-license.sh"

elif [ "$PLATFORM" = "windows" ]; then
  printf '%s\n' "$SCRIPT_RETURN_LICENSE_WINDOWS" > "$base_dir/return-license.sh"

else
  printf '%s\n' "Failed to detect OS."
  printf '%s\n' "Please try again or open an issue."
  exit 1
fi

chmod +x "$base_dir/return-license.sh"

# shellcheck source=/dev/null
source "$base_dir/return-license.sh"