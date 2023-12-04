#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

trap_exit() {
    local exit_status="$?"
    
    if [ "$exit_status" -ne 0 ]; then
        printf '%s\n' 'The script did not complete successfully.'
        
        printf '%s\n' "Removing the container \"$CONTAINER_NAME\"."
        docker rm -f "$CONTAINER_NAME" &> /dev/null || true
        
        exit "$exit_status"
    fi
}
trap trap_exit EXIT

running_builds=$(docker ps --filter "Name=$CONTAINER_NAME" --format "{{.ID}}")
if [ -z "$running_builds" ]; then
    # The build failed before and it killed the host
    # Startup so we can return the license
    docker run -dit \
    --name "$CONTAINER_NAME" \
    --env PROJECT_PATH="C:/unity_project" \
    --env UNITY_USERNAME="$unity_username" \
    --env UNITY_PASSWORD="$unity_password" \
    --volume "C:/Program Files (x86)/Microsoft Visual Studio":"C:/Program Files (x86)/Microsoft Visual Studio" \
    --volume "C:/Program Files (x86)/Windows Kits":"C:/Program Files (x86)/Windows Kits" \
    --volume "C:/ProgramData/Microsoft/VisualStudio":"C:/ProgramData/Microsoft/VisualStudio" \
    "unityci/editor:windows-${GAMECI_EDITOR_VERSION}-${GAMECI_TARGET_PLATFORM}-2" \
    powershell 
fi

set -x
# Return license
docker exec "$CONTAINER_NAME" powershell '& "C:\Program Files\Unity\Hub\Editor\*\Editor\Unity.exe" -returnlicense -batchmode -quit -nographics -username $Env:UNITY_USERNAME -password $Env:UNITY_PASSWORD -logfile | Out-Host'
set +x

# Remove the container.
docker rm -f "$CONTAINER_NAME"