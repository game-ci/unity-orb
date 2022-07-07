#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

readonly unity_hub_path="/Applications/Unity Hub.app/Contents/MacOS/Unity Hub"
readonly unity_editor_path="/Applications/Unity/Hub/Editor/$UNITY_EDITOR_VERSION/Unity.app/Contents/MacOS/Unity"

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
      "$unity_hub_path" -- --headless install --version "$UNITY_EDITOR_VERSION" --changeset "$changeset" --module mac-il2cpp --childModules
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

if ! check_and_install_unity_editor; then
  printf '%s\n' "Something went wrong."
  printf '%s\n' "Please try again or open an issue."
  exit 1
fi
