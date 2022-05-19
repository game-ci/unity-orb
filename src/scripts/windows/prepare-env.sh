#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

# Install the Windows 10 SDK.
choco upgrade windows-sdk-10.1 visualstudio2022-workload-vctools --no-progress -y

# Extract the Windows SDK registry key.
mkdir -p "$base_dir/regkeys"
powershell "reg export HKLM\\SOFTWARE\\WOW6432Node\\Microsoft\\\"Microsoft SDKs\"\\Windows\\v10.0 $base_dir/regkeys/winsdk.reg /y"

readonly container_name="unity_container"

# delete any existing containers
if docker ps -a | grep -wq "$container_name"; then
  docker rm -f "$container_name"
fi

set -x

# run the container and prevent it from exiting
# shellcheck disable=SC2140
docker run -dit \
  --name "$container_name" \
  --env PROJECT_PATH="C:/unity_project" \
  --env UNITY_USERNAME="$unity_username" \
  --env UNITY_PASSWORD="$unity_password" \
  --env UNITY_SERIAL="$unity_serial" \
  --volume "$unity_project_full_path":C:/unity_project \
  --volume "$base_dir"/regkeys:"C:/regkeys" \
  --volume "C:/Program Files (x86)/Microsoft Visual Studio":"C:/Program Files (x86)/Microsoft Visual Studio" \
  --volume "C:/Program Files (x86)/Windows Kits":"C:/Program Files (x86)/Windows Kits" \
  --volume "C:/ProgramData/Microsoft/VisualStudio":"C:/ProgramData/Microsoft/VisualStudio" \
  "unityci/editor:windows-${GAMECI_EDITOR_VERSION}-${GAMECI_TARGET_PLATFORM}-1" \
  powershell

set +x

# Register the Windows SDK and VCC Tools.
docker exec "$container_name" powershell 'reg import C:\regkeys\winsdk.reg'
docker exec "$container_name" powershell 'regsvr32 C:\ProgramData\Microsoft\VisualStudio\Setup\x64\Microsoft.VisualStudio.Setup.Configuration.Native.dll'

# Activate Unity
docker exec "$container_name" powershell '& "C:\Program Files\Unity\Hub\Editor\*\Editor\Unity.exe" -batchmode -quit -nographics -username $Env:UNITY_USERNAME -password $Env:UNITY_PASSWORD -serial $Env:UNITY_SERIAL -logfile | Out-Host'