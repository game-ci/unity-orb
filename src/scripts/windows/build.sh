#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

# Create the build folder
docker exec "$CONTAINER_NAME" powershell mkdir C:/build

# Add the build target and build name in the environment variables.
docker exec "$CONTAINER_NAME" powershell "[System.Environment]::SetEnvironmentVariable('BUILD_NAME','$PARAM_BUILD_NAME', [System.EnvironmentVariableTarget]::Machine)"
docker exec "$CONTAINER_NAME" powershell "[System.Environment]::SetEnvironmentVariable('BUILD_TARGET','$PARAM_BUILD_TARGET', [System.EnvironmentVariableTarget]::Machine)"

# Build the project
docker exec "$CONTAINER_NAME" powershell '& "C:\Program Files\Unity\Hub\Editor\*\Editor\Unity.exe" -batchmode -quit -nographics -projectPath $Env:PROJECT_PATH -buildTarget $Env:BUILD_TARGET -customBuildTarget $Env:BUILD_TARGET -customBuildName $Env:BUILD_NAME -customBuildPath "C:/build/" -buildVersion "1.0.0" -executeMethod BuildCommand.PerformBuild -logfile | Out-Host'

# Compress the build and Library folder.
docker exec "$CONTAINER_NAME" powershell 'tar -czf "C:/$Env:BUILD_NAME-$Env:BUILD_TARGET.tar.gz" -C "C:/build" .'
docker exec "$CONTAINER_NAME" powershell 'tar -czf "C:/library.tar.gz" -C "C:/unity_project/Library" .'

# Copy the build and Library directories to the host.
docker cp "$CONTAINER_NAME":"$PARAM_BUILD_NAME"-"$PARAM_BUILD_TARGET".tar.gz "$base_dir"/"$PARAM_BUILD_NAME"-"$PARAM_BUILD_TARGET".tar.gz
docker cp "$CONTAINER_NAME":library.tar.gz "$base_dir"/library.tar.gz

# Update Library folder to update the cache.
# rm -rf "$unity_project_full_path"/Library
tar -xzf "$base_dir"/library.tar.gz -C "$unity_project_full_path"

# Clean up the container.
docker rm -rf "$CONTAINER_NAME"