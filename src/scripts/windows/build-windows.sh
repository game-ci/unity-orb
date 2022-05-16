#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

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
# shellcheck disable=SC2140
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

# Register the Windows SDK and VCC Tools.
docker exec "$container_name" powershell 'reg import C:\regkeys\winsdk.reg'
docker exec "$container_name" powershell 'regsvr32 C:\ProgramData\Microsoft\VisualStudio\Setup\x64\Microsoft.VisualStudio.Setup.Configuration.Native.dll'

# Create the build folder
docker exec "$container_name" powershell mkdir C:/build

# Run the scripts
docker exec "$container_name" powershell C:/steps/activate.ps1
docker exec "$container_name" powershell C:/steps/build.ps1
docker exec "$container_name" powershell 'tar -czf "C:/$Env:BUILD_NAME-$Env:BUILD_TARGET.tar.gz" -C "C:/build" .'

# Copy the build to the host
docker cp "$container_name":"$PARAM_BUILD_NAME"-"$PARAM_BUILD_TARGET".tar.gz "$base_dir"/"$PARAM_BUILD_NAME"-"$PARAM_BUILD_TARGET".tar.gz