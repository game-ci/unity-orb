#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

readonly unity_license_file="$HOME/.local/share/unity3d/Unity/Unity_lic.ulf"
mkdir -p "$HOME/.cache/unity3d" "$(dirname "$unity_license_file")"

# Success is checked with the license file, not Unity's exit code.
activate_unity() {
  unity-editor \
    -logFile /dev/stdout \
    -batchmode \
    -nographics \
    -quit \
    -username "$unity_email" \
    -password "$unity_password" \
    -serial "$unity_serial" \
    | mask-serial
  [ -f "$unity_license_file" ]
}

printf '%s\n' "Activating Unity with email, password and serial."
if ! retry activate_unity; then
  printf '%s\n' "Failed to activate Unity. Please check your credentials or open an issue."
  exit 1
fi
printf '%s\n' "Unity activated successfully."
