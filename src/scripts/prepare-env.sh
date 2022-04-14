#!/usr/bin/env bash

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_full_path="$base_dir/$PARAM_PROJECT_PATH"

download_before_script() {
  curl --silent --location \
    --request GET \
    --url "https://gitlab.com/game-ci/unity3d-gitlab-ci-example/-/raw/main/ci/before_script.sh" \
    --header 'Accept: application/vnd.github.v3+json' \
    --output "$base_dir/before_script.sh"
}

create_manual_activation_file() {
  xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' unity-editor \
    -batchmode \
    -nographics \
    -createManualActivationFile \
    -quit \
    -logfile /dev/null

  # Check if license file was created successfully.
  if ls Unity_v* &> /dev/null; then return 0; else return 1; fi
}

check_license_and_editor_version() {
  local -r unity_project_version="$(grep -oP '(?<=m_EditorVersion: )[^\n]*' $unity_project_full_path/ProjectSettings/ProjectVersion.txt)"
  local -r unity_license_version="$(grep -oP '<ClientProvidedVersion Value\="\K.*?(?="/>)' <<< "$decoded_unity_license")"
  local -r unity_editor_version="$(cat $UNITY_PATH/version)"

  printf '%s\n' "Editor Version: $unity_editor_version"
  printf '%s\n' "Project Version: $unity_project_version"
  printf '%s\n' "License Version: $unity_license_version"

  local -r unity_project_major_version="$(printf '%s\n' "$unity_project_version" | cut -d. -f 1)"
  local -r unity_license_major_version="$(printf '%s\n' "$unity_license_version" | cut -d. -f 1)"
  local -r unity_editor_major_version="$(printf '%s\n' "$unity_editor_version" | cut -d. -f 1)"

  if [ "$unity_license_major_version" -ne "$unity_editor_major_version" ]; then
    printf '%s\n' "The major version of your license ($unity_license_major_version) and Editor ($unity_editor_major_version) mismatch."
    printf '%s\n' "Make sure they are the same by changing your Editor version or generating a new license."

    if create_manual_activation_file; then
      printf '%s\n' "Should you require a new activation license file, rerun the job with SSH and you will find it at \"${base_dir}/$(ls Unity_v*)\""
    fi

    exit 1
  fi

  if [ "$unity_project_major_version" -ne "$unity_editor_major_version" ]; then
    printf '%s\n' "The major version of your project ($unity_project_major_version) and Editor ($unity_editor_major_version) mismatch."
    printf '%s\n' "This might cause unexpected behavior. Consider changing the Editor tag to match your project."
    printf '%s\n' "Available tags can be found at https://hub.docker.com/r/unityci/editor/tags and https://game.ci/docs/docker/versions."
  fi
}

if ! download_before_script; then
  printf '%s\n' "Failed to download \"before_script.sh\"."
  exit 1
fi

chmod +x "$base_dir/before_script.sh"

# Decode Unity license.
readonly encoded_unity_license="${!PARAM_UNITY_LICENSE_VAR_NAME}"
readonly decoded_unity_license=$(printf '%s\n' "$encoded_unity_license" | base64 --decode)

if [ -z "$decoded_unity_license" ]; then
  printf '%s\n' "Failed to decode the ULF in \"$PARAM_UNITY_LICENSE_VAR_NAME\"."
  printf '%s\n' "Make sure its value is correctly set in your context or project settings."

  if create_manual_activation_file; then
    printf '%s\n' "Should you require a new activation license file, rerun the job with SSH and you will find it at \"${base_dir}/$(ls Unity_v*)\""
  fi

  exit 1
else
  check_license_and_editor_version
fi

# Nomenclature required by the script.
readonly UNITY_LICENSE="$decoded_unity_license"

export UNITY_LICENSE

# Run the test script.
# shellcheck source=/dev/null
source "$base_dir/before_script.sh"
