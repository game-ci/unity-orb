#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

readonly container_name="unity_container"

# Create the build folder
docker exec "$container_name" powershell mkdir C:/build

# Add the build target and build name in the environment variables.
docker exec "$container_name" powershell "[System.Environment]::SetEnvironmentVariable('BUILD_NAME','$PARAM_BUILD_NAME', [System.EnvironmentVariableTarget]::Machine)"
docker exec "$container_name" powershell "[System.Environment]::SetEnvironmentVariable('BUILD_TARGET','$PARAM_BUILD_TARGET', [System.EnvironmentVariableTarget]::Machine)"

# Build the project
docker exec "$container_name" powershell '& "C:\Program Files\Unity\Hub\Editor\*\Editor\Unity.exe" -batchmode -quit -nographics -projectPath $Env:PROJECT_PATH -buildTarget $Env:BUILD_TARGET -customBuildTarget $Env:BUILD_TARGET -customBuildName $Env:BUILD_NAME -customBuildPath "C:/build/" -buildVersion "1.0.0" -executeMethod BuildCommand.PerformBuild -logfile | Out-Host'

# Compress the build and Library folder.
docker exec "$container_name" powershell 'tar -czf "C:/$Env:BUILD_NAME-$Env:BUILD_TARGET.tar.gz" -C "C:/build" .'
docker exec "$container_name" powershell 'tar -czf "C:/library.tar.gz" -C "C:/unity_project/Library" .'

# Copy the build and Library directories to the host.
docker cp "$container_name":"$PARAM_BUILD_NAME"-"$PARAM_BUILD_TARGET".tar.gz "$base_dir"/"$PARAM_BUILD_NAME"-"$PARAM_BUILD_TARGET".tar.gz
docker cp "$container_name":library.tar.gz "$base_dir"/library.tar.gz

# Update Library folder to update the cache.
# rm -rf "$unity_project_full_path"/Library
tar -xzf "$base_dir"/library.tar.gz -C "$unity_project_full_path"

# Clean up the container.
docker rm -f "$container_name"