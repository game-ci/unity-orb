#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

trap_exit() {
  local exit_status="$?"

  if [ "$exit_status" -ne 0 ]; then
    printf '%s\n' 'The script did not complete successfully.'

    printf '%s\n' "Removing the container \"$container_name\"."
    docker rm -f "$container_name" &> /dev/null || true

    exit "$exit_status"
  fi
}
trap trap_exit EXIT

# Start Docker. Recent CircleCI Windows images don't start it by default.
docker info &> /dev/null || powershell 'Start-Service docker'

# Install the Windows 10 SDK.
choco upgrade windows-sdk-10.1 visualstudio2022-workload-vctools --no-progress -y

# Extract the Windows SDK registry key.
mkdir -p "$base_dir/regkeys"
powershell "reg export HKLM\\SOFTWARE\\WOW6432Node\\Microsoft\\\"Microsoft SDKs\"\\Windows\\v10.0 $base_dir/regkeys/winsdk.reg /y"

readonly container_name="${CIRCLE_PROJECT_REPONAME}-${CIRCLE_BUILD_NUM}"
printf '%s\n' "export CONTAINER_NAME=$container_name" >> "$BASH_ENV"

# Delete any existing containers.
if docker ps -a | grep -wq "$container_name"; then
  docker rm -f "$container_name"
fi

# Create folders to store artifacts.
mkdir -p "$base_dir/build" || { printf '%s\n' "Unable to create the build directory"; exit 1; }
mkdir -p "$base_dir/test" || { printf '%s\n' "Unable to create the test directory"; exit 1; }

set -x

# Run the container and prevent it from exiting.
# shellcheck disable=SC2140
docker run -dit \
  --name "$container_name" \
  --env PROJECT_PATH="C:/unity_project" \
  --env UNITY_EMAIL="$unity_email" \
  --env UNITY_PASSWORD="$unity_password" \
  --env UNITY_SERIAL="$unity_serial" \
  --volume "$unity_project_full_path":C:/unity_project \
  --volume "$base_dir"/regkeys:"C:/regkeys" \
  --volume "$base_dir"/build:"C:/build" \
  --volume "$base_dir"/test:"C:/test" \
  --volume "C:/Program Files (x86)/Microsoft Visual Studio":"C:/Program Files (x86)/Microsoft Visual Studio" \
  --volume "C:/Program Files (x86)/Windows Kits":"C:/Program Files (x86)/Windows Kits" \
  --volume "C:/ProgramData/Microsoft/VisualStudio":"C:/ProgramData/Microsoft/VisualStudio" \
  "unityci/editor:windows-${GAMECI_EDITOR_VERSION}-${GAMECI_TARGET_PLATFORM}-3" \
  powershell

set +x

# Register the Windows SDK and VCC Tools.
docker exec "$container_name" powershell 'reg import C:\regkeys\winsdk.reg'
docker exec "$container_name" powershell 'regsvr32 /s C:\ProgramData\Microsoft\VisualStudio\Setup\x64\Microsoft.VisualStudio.Setup.Configuration.Native.dll'

# Activate Unity
docker exec "$container_name" powershell '& "C:\Program Files\Unity\Hub\Editor\*\Editor\Unity.exe" -batchmode -quit -nographics -username $Env:UNITY_EMAIL -password $Env:UNITY_PASSWORD -serial $Env:UNITY_SERIAL -logfile | Out-Host'
