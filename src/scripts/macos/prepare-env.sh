#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

readonly unity_editors_path="/Applications/Unity/Hub/Editor"
readonly unity_editor_path="$unity_editors_path/$UNITY_EDITOR_VERSION/Unity.app/Contents/MacOS/Unity"

printf '%s\n' "export UNITY_EDITOR_PATH=$unity_editor_path" >> "$BASH_ENV"

# The Unity Hub's headless CLI is deprecated, and current Hub builds refuse to install Editors.
# Unity's standalone CLI (`unity`) replaces it.
check_and_install_unity_cli() {
  if ! command -v unity &> /dev/null; then
    printf '%s\n' "Could not find the Unity CLI. Installing it with brew..."

    if ! brew install --cask unity-cli || ! command -v unity &> /dev/null; then
      printf '%s\n' "Could not install the Unity CLI."
      printf '%s\n' "Please try again or open an issue."
      return 1
    fi

    printf '%s\n' "Unity CLI installed successfully."
  fi

  return 0
}

check_and_install_unity_editor() {
  if [ ! -f "$unity_editor_path" ]; then
    printf '%s\n' "Could not find the Unity Editor at \"$unity_editor_path\"."
    printf '%s\n' "Installing it with the Unity CLI..."

    if ! check_and_install_unity_cli; then
      printf '%s\n' "Could not install the Editor because the Unity CLI is not installed."
      return 1
    fi

    if ! command -v npm &> /dev/null; then
      printf '%s\n' "npm is required to fetch the Unity Editor changeset."
      printf '%s\n' "Please install it and try again."
      return 1
    fi

    changeset="$(npx unity-changeset "$UNITY_EDITOR_VERSION")"

    set -x
    if ! unity install-path --set "$unity_editors_path" --non-interactive \
      || ! unity install "$UNITY_EDITOR_VERSION" --changeset "$changeset" --module mac-il2cpp --child-modules \
        --architecture arm64 --accept-eula --non-interactive; then
      set +x
      printf '%s\n' "The Unity CLI could not install the Editor."
      return 1
    fi
    set +x

    if [ -f "$unity_editor_path" ]; then
      printf '%s\n' "Unity Editor installed successfully."
    else
      printf '%s\n' "Could not install the Unity Editor."
      printf '%s\n' "Please try again or open an issue."
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
    -logfile - \
    | mask-serial || return 1
  [ -f "$unity_license_file_path/Unity_lic.ulf" ]
}

printf '%s\n' "Activating Unity with email, password and serial."
if ! retry activate_unity; then
  printf '%s\n' "Failed to activate Unity. Please check your credentials or open an issue."
  exit 1
fi
