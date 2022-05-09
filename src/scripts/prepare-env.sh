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
  local -r unity_license_version="$(grep -oP '<ClientProvidedVersion Value\="\K.*?(?="/>)' <<< "$unity_license")"
  local -r unity_editor_version="$(cat $UNITY_PATH/version)"

  printf '%s\n' "Editor Version: $unity_editor_version"
  printf '%s\n' "Project Version: $unity_project_version"
  printf '%s\n\n' "License Version: $unity_license_version"

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

resolve_unity_license() {
  if [ -n "$unity_encoded_license" ]; then
    # Decode Personal Unity License File.
    unity_license=$(printf '%s\n' "$unity_encoded_license" | base64 --decode)

  elif [ -n "$unity_username" ] && [ -n "$unity_password" ] && [ -n "$unity_serial" ]; then
    # Generate Plus or Pro Unity License File.
    xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' unity-editor \
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

readonly platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

case "$platform" in
  linux*)
    printf '%s\n' "Detected OS: Linux."
    
    # Expand environment name variable parameters.
    readonly unity_username="${!PARAM_UNITY_USERNAME_VAR_NAME}"
    readonly unity_password="${!PARAM_UNITY_PASSWORD_VAR_NAME}"
    readonly unity_serial="${!PARAM_UNITY_SERIAL_VAR_NAME}"
    readonly unity_encoded_license="${!PARAM_UNITY_LICENSE_VAR_NAME}"

    unity_license=""

    resolve_unity_license
    check_license_and_editor_version

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
    ;;
  darwin*)
    printf '%s\n' "Detected OS: macOS."
    ;;
  msys*|cygwin*)
    printf '%s\n' "Detected OS: Windows."
    ;;
  *)
    echo "Unsupported OS: \"$platform\"."
    exit 1
    ;;
esac