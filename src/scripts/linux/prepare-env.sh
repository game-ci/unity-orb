#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

download_before_script() {
  curl --silent --location \
    --request GET \
    --url "https://gitlab.com/game-ci/unity3d-gitlab-ci-example/-/raw/main/ci/before_script.sh" \
    --header 'Accept: application/vnd.github.v3+json' \
    --output "$base_dir/before_script.sh"
}

create_manual_activation_file() {
  unity-editor \
    -batchmode \
    -nographics \
    -createManualActivationFile \
    -quit \
    -logfile /dev/null

  # Check if license file was created successfully.
  if ls Unity_v* &> /dev/null; then return 0; else return 1; fi
}

print_versions() {
  local unity_project_version
  local unity_license_version
  local unity_editor_version
  
  unity_project_version="$(cat "$unity_project_full_path"/ProjectSettings/ProjectVersion.txt | perl -nle 'print $& while m{(?<=m_EditorVersion: )[^\n]*}g')"
  unity_license_version="$(perl -nle 'print $& while m{<ClientProvidedVersion Value\="\K.*?(?="/>)}g' <<< "$unity_license")"
  unity_editor_version="$(cat $UNITY_PATH/version)"

  printf '%s\n' "Editor Version: $unity_editor_version"
  printf '%s\n' "Project Version: $unity_project_version"
  printf '%s\n\n' "License Version: $unity_license_version"
}

resolve_unity_license() {
  if [ -n "$unity_encoded_license" ]; then
    # Decode Personal Unity License File.
    unity_license=$(printf '%s\n' "$unity_encoded_license" | base64 --decode)

  elif [ -n "$unity_username" ] && [ -n "$unity_password" ] && [ -n "$unity_serial" ]; then
    # Generate Plus or Pro Unity License File.
    unity-editor \
      -logFile /dev/stdout \
      -batchmode \
      -nographics \
      -quit \
      -username "$unity_username" \
      -password "$unity_password" \
      -serial "$unity_serial"

    if [ -e "/root/.local/share/unity3d/Unity/Unity_lic.ulf" ]; then
      unity_license="$(cat /root/.local/share/unity3d/Unity/Unity_lic.ulf)"
    else
      printf '%s\n' "Failed to generate Unity license file."
      printf '%s\n' "Make sure you have entered the correct username, password and serial and try again."
      printf '%s\n' "If you are still having problems, please open an issue."

      exit 1
    fi

  else
    printf '%s\n' "If you own a Personal Unity License File (.ulf), please provide it as a base64 encoded string."  
    printf '%s\n' "If you own a Plus or Pro Unity license, please provide your username, password and serial."

    if create_manual_activation_file; then
      printf '%s\n' "Should you require a new Personal Activation License File (.alf), rerun the job with SSH and you will find it at \"${base_dir}/$(ls Unity_v*)\""
    fi

    exit 1
  fi
}

unity_license=""

resolve_unity_license
print_versions

# Download before_script.sh from GameCI.
if ! download_before_script; then
  printf '%s\n' "Failed to download \"before_script.sh\"."
  exit 1
fi

chmod +x "$base_dir/before_script.sh"

# Nomenclature required by the script.
readonly UNITY_LICENSE="$unity_license"

export UNITY_LICENSE

# Run the test script.
# shellcheck source=/dev/null
source "$base_dir/before_script.sh"