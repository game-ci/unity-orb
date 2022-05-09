#!/usr/bin/env bash

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_full_path="$base_dir/$PARAM_PROJECT_PATH"
readonly gameci_sample_project_dir=$(mktemp -d)
readonly sample_project_compressed_file="sample_project.tar.gz"

trap_build_script_exit() {
  local -r exit_status="$?"

  # The build script has a "set -x" on it. This will disable it for the rest of the run.
  set +x

  if [ "$exit_status" -ne 0 ]; then
    printf '%s\n' 'The script did not complete successfully.'
    printf '%s\n' "The exit code was $exit_status"

    rm -rf "$gameci_sample_project_dir"
    exit "$exit_status"
  fi

  if [ "$PARAM_COMPRESS" -eq 1 ]; then
    printf '%s\n' 'Compressing build artifacts...'

    # Compress artifacts to store them in the artifacts bucket.
    tar -czf "$base_dir/$PARAM_BUILD_NAME-$PARAM_BUILD_TARGET.tar.gz" -C "$unity_project_full_path/Builds/$PARAM_BUILD_TARGET" .
  fi

  # Clean up.
  rm -rf "$gameci_sample_project_dir"
}

download_sample_project() {
  curl --silent \
    --location "https://gitlab.com/game-ci/unity3d-gitlab-ci-example/-/archive/main/unity3d-gitlab-ci-example-main.tar.gz" \
    --output "$gameci_sample_project_dir/$sample_project_compressed_file"
}

copy_builder_to_project() {
  mkdir -p "$unity_project_full_path/Assets/Editor/"
  cp -r "$gameci_sample_project_dir/Assets/Scripts/Editor/." "$unity_project_full_path/Assets/Editor/"
}

if ! download_sample_project; then
  printf '%s\n' "Failed to download GameCI's sample project."
  printf '%s\n' "Please try again or open an issue."
  rm -rf "$gameci_sample_project_dir"
  exit 1
fi

# Extract sample project.
tar -xzf "$gameci_sample_project_dir/$sample_project_compressed_file" -C "$gameci_sample_project_dir" --strip-components 1

if ! copy_builder_to_project; then
  printf '%s\n' "Failed to copy builder from the sample project to your project."
  printf '%s\n' "Please try again or open an issue."
  rm -rf "$gameci_sample_project_dir"
  exit 1
fi

readonly platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

case "$platform" in
  linux*)
    printf '%s\n' "Detected OS: Linux."

    # Copy GameCI's build script to the base directory.
    cp "$gameci_sample_project_dir/ci/build.sh" "$base_dir/build.sh"
    chmod +x "$base_dir/build.sh"

    # Clean up.
    rm -rf "$gameci_sample_project_dir"

    # Name variables as required by the "build.sh" script.
    readonly BUILD_NAME="$PARAM_BUILD_NAME"
    readonly BUILD_TARGET="$PARAM_BUILD_TARGET"
    readonly UNITY_DIR="$unity_project_full_path"

    export BUILD_NAME
    export BUILD_TARGET
    export UNITY_DIR

    # Trap "build.sh" exit otherwise it won't be possible to zip the artifacts.
    trap trap_build_script_exit EXIT

    # Run the build script.
    # shellcheck source=/dev/null
    source "$base_dir/build.sh"
    ;;
  darwin*)
    printf '%s\n' "Detected OS: macOS."
    ;;
  msys*|cygwin*)
    printf '%s\n' "Detected OS: Windows."

    # Install the Windows 10 SDK.
    choco upgrade windows-sdk-10.1 visualstudio2022-workload-vctools --no-progress -y
    mkdir -p "$base_dir/regkeys"

    powershell "reg export HKLM\\SOFTWARE\\WOW6432Node\\Microsoft\\\"Microsoft SDKs\"\\Windows\\v10.0 $base_dir/regkeys/winsdk.reg /y"

    readonly unity_username="${!PARAM_UNITY_USERNAME_VAR_NAME}"
    readonly unity_password="${!PARAM_UNITY_PASSWORD_VAR_NAME}"
    readonly unity_serial="${!PARAM_UNITY_SERIAL_VAR_NAME}"

    mkdir "$base_dir"/steps

    printf '%s\n' '& "C:\Program Files\Unity\Hub\Editor\2021.3.2f1\Editor\Unity.exe" -batchmode -quit -nographics -username $Env:UNITY_USERNAME -password $Env:UNITY_PASSWORD -serial $Env:UNITY_SERIAL -logfile | Out-Host' > "$base_dir"/steps/activate.ps1
    printf '%s\n' '& "C:\Program Files\Unity\Hub\Editor\2021.3.2f1\Editor\Unity.exe" -batchmode -quit -nographics -projectPath $Env:PROJECT_PATH -buildTarget $Env:BUILD_TARGET -customBuildTarget $Env:BUILD_TARGET -customBuildName $Env:BUILD_NAME -customBuildPath "C:/build/" -buildVersion "1.0.0" -executeMethod BuildCommand.PerformBuild -logfile | Out-Host' > "$base_dir"/steps/build.ps1

    readonly container_name="unity_container"

    # delete any existing containers
    if docker ps -a | grep -wq "$container_name"; then
      docker rm -f "$container_name"
    fi

    mv "$gameci_sample_project_dir" "$base_dir"/sample_project

    set -x

    # run the container and prevent it from exiting
    docker run -dit \
      --name "$container_name" \
      --env BUILD_NAME="$PARAM_BUILD_NAME" \
      --env BUILD_TARGET="$PARAM_BUILD_TARGET" \
      --env PROJECT_PATH="C:/unity_project" \
      --env UNITY_USERNAME="$unity_username" \
      --env UNITY_PASSWORD="$unity_password" \
      --env UNITY_SERIAL="$unity_serial" \
      --volume "$unity_project_full_path":C:/unity_project \
      --volume "$base_dir"/steps:C:/steps \
      --volume "$base_dir"/sample_project:C:/sample_project \
      --volume "$base_dir"/regkeys:"C:/regkeys" \
      --volume "C:/Program Files (x86)/Microsoft Visual Studio":"C:/Program Files (x86)/Microsoft Visual Studio" \
      --volume "C:/Program Files (x86)/Windows Kits":"C:/Program Files (x86)/Windows Kits" \
      --volume "C:/ProgramData/Microsoft/VisualStudio":"C:/ProgramData/Microsoft/VisualStudio" \
      unityci/editor:windows-2021.3.2f1-windows-il2cpp-1.0.1 \
      powershell

    set +x

    # Do registry stuff
    docker exec "$container_name" powershell 'reg import C:\regkeys\winsdk.reg'
    docker exec "$container_name" powershell 'regsvr32 C:\ProgramData\Microsoft\VisualStudio\Setup\x64\Microsoft.VisualStudio.Setup.Configuration.Native.dll'
    
    # create build folder
    docker exec "$container_name" powershell mkdir C:/build

    # run the scripts
    docker exec "$container_name" powershell C:/steps/activate.ps1
    docker exec "$container_name" powershell C:/steps/build.ps1
    docker exec "$container_name" powershell 'tar -czf "C:/$Env:BUILD_NAME-$Env:BUILD_TARGET.tar.gz" -C "C:/build" .'
    docker exec "$container_name" powershell ls C:/build
    docker exec "$container_name" powershell ls C:

    docker cp "$container_name":"$PARAM_BUILD_NAME"-"$PARAM_BUILD_TARGET".tar.gz "$base_dir"/"$PARAM_BUILD_NAME"-"$PARAM_BUILD_TARGET".tar.gz
    ;;
  *)
    echo "Unsupported OS: \"$platform\"."
    exit 1
    ;;
esac