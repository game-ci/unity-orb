#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_full_path="$base_dir/$PARAM_PROJECT_PATH"

# Expand environment name variable parameters.
readonly unity_username="${!PARAM_UNITY_USERNAME_VAR_NAME}"
readonly unity_password="${!PARAM_UNITY_PASSWORD_VAR_NAME}"
readonly unity_serial="${!PARAM_UNITY_SERIAL_VAR_NAME}"
readonly unity_encoded_license="${!PARAM_UNITY_LICENSE_VAR_NAME}"

if [ "$PLATFORM" = "linux" ]; then
  printf '%s\n' "$SCRIPT_PREPARE_ENV_LINUX" > "$base_dir/prepare-env.sh"

elif [ "$PLATFORM" = "macos" ]; then
  printf '%s\n' "Detected OS: macOS."
  printf '%s\n' "$SCRIPT_PREPARE_ENV_MACOS" > "$base_dir/prepare-env.sh"

elif [ "$PLATFORM" = "windows" ]; then
  printf '%s\n' "$SCRIPT_PREPARE_ENV_WINDOWS" > "$base_dir/prepare-env.sh"

else
  printf '%s\n' "Failed to detect OS."
  printf '%s\n' "Please try again or open an issue."
  exit 1
fi

chmod +x "$base_dir/prepare-env.sh"

# shellcheck source=/dev/null
source "$base_dir/prepare-env.sh"