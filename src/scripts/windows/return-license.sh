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

set -x
# Return license
docker exec "$CONTAINER_NAME" powershell '& "C:\Program Files\Unity\Hub\Editor\*\Editor\Unity.exe" -returnlicense -batchmode -quit -nographics -username $Env:UNITY_EMAIL -password $Env:UNITY_PASSWORD -logfile | Out-Host'
set +x

# Remove the container.
docker rm -f "$CONTAINER_NAME"
