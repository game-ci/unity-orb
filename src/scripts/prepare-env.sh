#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_full_path="$base_dir/$PARAM_PROJECT_PATH"

# Import "utils.sh".
eval "$SCRIPT_UTILS"

# Detect host OS.
detect-os

# Expand environment name variable parameters.
readonly unity_email="${!PARAM_UNITY_EMAIL_VAR_NAME}"
readonly unity_password="${!PARAM_UNITY_PASSWORD_VAR_NAME}"
unity_serial="${!PARAM_UNITY_SERIAL_VAR_NAME}"
readonly unity_license="${!PARAM_UNITY_LICENSE_VAR_NAME}"

if [ -z "$unity_email" ] || [ -z "$unity_password" ]; then
  printf '%s\n' "Missing Unity email or password. Set the \"$PARAM_UNITY_EMAIL_VAR_NAME\" and \"$PARAM_UNITY_PASSWORD_VAR_NAME\" environment variables."
  printf '%s\n' "See the docs for more details: https://game.ci/docs/circleci/activation"
  exit 1
fi

# Personal licenses have no serial: extract it from the license file, like GameCI does.
if [ -z "$unity_serial" ] && [ -n "$unity_license" ]; then
  printf '%s\n' "No serial found in \"$PARAM_UNITY_SERIAL_VAR_NAME\". Extracting it from \"$PARAM_UNITY_LICENSE_VAR_NAME\"."
  unity_serial="$(extract-serial-from-license "$unity_license")" || unity_serial=""
fi

# Serials look like "XX-XXXX-XXXX-XXXX-XXXX-XXXX". Ignore stray whitespace from copy-pasting.
unity_serial="${unity_serial//[[:space:]]/}"
if [ "${#unity_serial}" -lt 8 ] || [[ "$unity_serial" == *[!A-Za-z0-9-]* ]]; then
  printf '%s\n' "No Unity serial found. Set \"$PARAM_UNITY_SERIAL_VAR_NAME\" or \"$PARAM_UNITY_LICENSE_VAR_NAME\" to a valid value."
  printf '%s\n' "See the docs for more details: https://game.ci/docs/circleci/activation"
  exit 1
fi
readonly unity_serial

if [ "$PLATFORM" = "linux" ]; then eval "$SCRIPT_PREPARE_ENV_LINUX";
elif [ "$PLATFORM" = "macos" ]; then eval "$SCRIPT_PREPARE_ENV_MACOS";
elif [ "$PLATFORM" = "windows" ]; then eval "$SCRIPT_PREPARE_ENV_WINDOWS";
fi
