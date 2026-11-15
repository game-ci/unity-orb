#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

readonly unity_editors_path="/Applications/Unity/Hub/Editor"
readonly unity_editor_path="$unity_editors_path/$UNITY_EDITOR_VERSION/Unity.app/Contents/MacOS/Unity"

# The Unity Hub's headless CLI is deprecated, and current Hub builds refuse to install Editors.
# Unity's standalone CLI (`unity`) replaces it. The binary is pinned and checked against
# SHA-256 values kept here, so a changed download is rejected rather than run next to the
# Unity credentials. To upgrade, update the version and both hashes from Unity's manifest:
# https://public-cdn.cloud.unity3d.com/hub/prod/cli/<version>/
readonly unity_cli_version="1.0.0"
readonly unity_cli_bin="${UNITY_CLI_HOME:-$HOME/.unity}/bin"
readonly unity_changeset_version="3.4.0"

{
  printf '%s\n' "export UNITY_EDITOR_PATH=$unity_editor_path"
  printf '%s\n' "export UNITY_CLI_PATH=\"$unity_cli_bin/unity\""
  printf '%s\n' "export PATH=\"$unity_cli_bin:\$PATH\""
} >> "$BASH_ENV"
export PATH="$unity_cli_bin:$PATH"

case "$(uname -m)" in
  arm64)
    readonly unity_architecture="arm64"
    readonly unity_cli_platform="darwin-arm64"
    readonly unity_cli_sha256="de6cb46c1ac1871d524965ed2ed5f14e1eb13b4fc25210a209a55c0b1154014f"
    ;;
  x86_64)
    readonly unity_architecture="x86_64"
    readonly unity_cli_platform="darwin-x64"
    readonly unity_cli_sha256="2ce9f3cbdc537e4468f178382749508eca7c611cf4b304cc23395c63321a7d96"
    ;;
  *)
    printf '%s\n' "Unsupported macOS architecture: $(uname -m)."
    exit 1
    ;;
esac

check_and_install_unity_cli() {
  if command -v unity &> /dev/null; then
    return 0
  fi

  printf '%s\n' "Could not find the Unity CLI. Installing version $unity_cli_version ($unity_cli_platform)..."

  local download
  download="$(mktemp)"

  if ! curl -fsSL --retry 3 -o "$download" "https://public-cdn.cloud.unity3d.com/hub/prod/cli/$unity_cli_version/unity-$unity_cli_platform"; then
    rm -f "$download"
    printf '%s\n' "Could not download the Unity CLI."
    return 1
  fi

  if [ "$(shasum -a 256 "$download" | cut -d ' ' -f 1)" != "$unity_cli_sha256" ]; then
    rm -f "$download"
    printf '%s\n' "The downloaded Unity CLI does not match its expected SHA-256; refusing to run it."
    return 1
  fi

  if ! mkdir -p "$unity_cli_bin" || ! install -m 755 "$download" "$unity_cli_bin/unity"; then
    rm -f "$download"
    printf '%s\n' "Could not install the Unity CLI to \"$unity_cli_bin\"."
    return 1
  fi
  rm -f "$download"

  if ! command -v unity &> /dev/null; then
    printf '%s\n' "Could not install the Unity CLI."
    printf '%s\n' "Please try again or open an issue."
    return 1
  fi

  printf '%s\n' "Unity CLI installed successfully."
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

    local changeset
    if ! changeset="$(npx --yes "unity-changeset@$unity_changeset_version" "$UNITY_EDITOR_VERSION")" || [ -z "$changeset" ]; then
      printf '%s\n' "Could not resolve the changeset for Unity $UNITY_EDITOR_VERSION."
      return 1
    fi

    # The CLI only accepts an existing install directory, and it must be writable by this user.
    if ! { mkdir -p "$unity_editors_path" 2> /dev/null && [ -w "$unity_editors_path" ]; }; then
      if ! sudo mkdir -p "$unity_editors_path" || ! sudo chown -R "$(id -u):$(id -g)" "$unity_editors_path"; then
        printf '%s\n' "Could not create a writable \"$unity_editors_path\"."
        return 1
      fi
    fi

    set -x
    if ! unity install-path --set "$unity_editors_path" --non-interactive \
      || ! unity install "$UNITY_EDITOR_VERSION" --changeset "$changeset" --module mac-il2cpp --child-modules \
        --architecture "$unity_architecture" --accept-eula --non-interactive; then
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
