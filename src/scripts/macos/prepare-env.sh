#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

readonly unity_hub_path="/Applications/Unity Hub.app/Contents/MacOS/Unity Hub"
readonly unity_editor_path="/Applications/Unity/Hub/Editor/$UNITY_EDITOR_VERSION/Unity.app/Contents/MacOS/Unity"

printf '%s\n' "export UNITY_HUB_PATH=\"$unity_hub_path\"" >> "$BASH_ENV"
printf '%s\n' "export UNITY_EDITOR_PATH=$unity_editor_path" >> "$BASH_ENV"

check_and_install_rosetta() {
  if ! /usr/bin/pgrep oahd &> /dev/null; then
    echo "Rosetta 2 is not installed. Installing it now..."
    if softwareupdate --install-rosetta --agree-to-license; then
      echo "Rosetta 2 installed successfully."
    else
      echo "Failed to install Rosetta 2."
      exit 1
    fi
  else
    echo "Rosetta 2 is already installed."
  fi
}

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
      arch -x86_64 "$unity_hub_path" -- --headless install --version "$UNITY_EDITOR_VERSION" --changeset "$changeset" --module mac-il2cpp --childModules -a arm64
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

resolve_unity_serial() {
  if [ -n "$unity_username" ] && [ -n "$unity_password" ]; then
    # Serial provided.
    if [ -n "$unity_serial" ]; then
      printf '%s\n' "Detected Unity serial."
      readonly resolved_unity_serial="$unity_serial"

    # License provided.
    elif [ -n "$unity_encoded_license" ]; then
      printf '%s\n' "No serial detected. Extracting it from the encoded license."

      if ! extract_serial_from_license; then
        printf '%s\n' "Failed to parse the serial from the Unity license."
        printf '%s\n' "Please try again or open an issue."
        printf '%s\n' "See the docs for more details: https://game.ci/docs/circleci/activation#personal-license"
        return 1

      else
        readonly resolved_unity_serial="$decoded_unity_serial"
      fi

    # Nothing provided.
    else
      printf '%s\n' "No serial or encoded license found."
      printf '%s\n' "Please run the script again with a serial or encoded license file."
      printf '%s\n' "See the docs for more details: https://game.ci/docs/circleci/activation"
      return 1
    fi
  fi

  return 0
}

extract_serial_from_license() {
  # Fix locale setting in PERL.
  # https://stackoverflow.com/a/7413863
  export LC_CTYPE=en_US.UTF-8
  export LC_ALL=en_US.UTF-8

  local unity_license
  local developer_data
  local encoded_serial

  unity_license="$(base64 --decode <<< "$unity_encoded_license")"
  developer_data="$(perl -nle 'print $& while m{<DeveloperData Value\="\K.*?(?="/>)}g' <<< "$unity_license")"
  encoded_serial="$(cut -c 5- <<< "$developer_data")"

  decoded_unity_serial="$(base64 --decode <<< "$encoded_serial")"
  readonly decoded_unity_serial

  if [ -n "$decoded_unity_serial" ]; then return 0; else return 1; fi
}

# Check and install Rosetta 2 if not already installed.
check_and_install_rosetta

# Install the Editor if not already installed.
if ! check_and_install_unity_editor; then
  printf '%s\n' "Something went wrong."
  printf '%s\n' "Please try again or open an issue."
  exit 1
fi

# Check if serial or encoded license was provided.
# If the latter, extract the serial from the license.
if ! resolve_unity_serial; then
  printf '%s\n' "Failed to find the serial or parse it from the Unity license."
  printf '%s\n' "Please try again or open an issue."
  exit 1
fi

# If it doesn't exist, create folder for the Unity License File.
readonly unity_license_file_path="/Library/Application Support/Unity"
sudo mkdir -p "$unity_license_file_path"
sudo chmod -R 777 "$unity_license_file_path"

# Activate the Unity Editor.
set -x
"$unity_editor_path" \
  -batchmode \
  -quit \
  -nographics \
  -username "$unity_username" \
  -password "$unity_password" \
  -serial "$resolved_unity_serial" \
  -logfile /dev/stdout
set +x
