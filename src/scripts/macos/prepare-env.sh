#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

readonly unity_hub_path="/Applications/Unity Hub.app/Contents/MacOS/Unity Hub"
readonly unity_editor_path="/Applications/Unity/Hub/Editor/$UNITY_EDITOR_VERSION/Unity.app/Contents/MacOS/Unity"

printf '%s\n' "export UNITY_HUB_PATH=\"$unity_hub_path\"" >> "$BASH_ENV"
printf '%s\n' "export UNITY_EDITOR_PATH=$unity_editor_path" >> "$BASH_ENV"

check_and_install_unity_hub() {
  if [ ! -f "$unity_hub_path" ]; then
    printf '%s\n' "Could not find Unity Hub at \"$unity_hub_path\"."
    printf '%s\n' "Installing it with brew..."

    brew install --cask unity-hub

    if [ -f "$unity_hub_path" ]; then
      printf '%s\n' "Unity Hub installed successfully."

    else
      printf '%s\n' "Could not install the Unity Hub."
      printf '%s\n' "Please try again or open an issue."
      return 1
    fi
  fi

  return 0
}

check_and_install_unity_editor() {
  if [ ! -f "$unity_editor_path" ]; then
    printf '%s\n' "Could not find the Unity Editor at \"$unity_editor_path\"."
    printf '%s\n' "Installing it with the Unity Hub..."

    if check_and_install_unity_hub; then

      if ! command -v npm &> /dev/null; then
        printf '%s\n' "npm is required to fetch the Unity Editor changeset."
        printf '%s\n' "Please install it and try again."
        return 1
      fi

      changeset="$(npx unity-changeset "$UNITY_EDITOR_VERSION")"

      set -x
      "$unity_hub_path" -- --headless install --version "$UNITY_EDITOR_VERSION" --changeset "$changeset" --module mac-il2cpp --childModules --architecture arm64
      set +x

      if [ -f "$unity_editor_path" ]; then
        printf '%s\n' "Unity Editor installed successfully."

      else
        printf '%s\n' "Could not install the Unity Editor."
        printf '%s\n' "Please try again or open an issue."
        return 1
      fi
    else
      printf '%s\n' "Could not install the Editor because Unity Hub is not installed."
      return 1
    fi
  fi

  return 0
}

# Older editors (e.g. 2022.3) run x86_64 helpers like the Package Manager server, which need Rosetta 2.
arch -x86_64 /usr/bin/true 2> /dev/null || softwareupdate --install-rosetta --agree-to-license

# Install the Editor if not already installed.
if ! check_and_install_unity_editor; then
  printf '%s\n' "Something went wrong."
  printf '%s\n' "Please try again or open an issue."
  exit 1
fi

# If it doesn't exist, create folder for the Unity License File.
readonly unity_license_file_path="/Library/Application Support/Unity"
sudo mkdir -p "$unity_license_file_path"
sudo chmod -R 777 "$unity_license_file_path"

activate_unity() {
  "$unity_editor_path" \
    -batchmode \
    -quit \
    -nographics \
    -username "$unity_email" \
    -password "$unity_password" \
    -serial "$unity_serial" \
    -logfile /dev/stdout \
    | mask-serial || return 1
  [ -f "$unity_license_file_path/Unity_lic.ulf" ]
}

printf '%s\n' "Activating Unity with email, password and serial."
if ! retry activate_unity; then
  printf '%s\n' "Failed to activate Unity. Please check your credentials or open an issue."
  exit 1
fi
