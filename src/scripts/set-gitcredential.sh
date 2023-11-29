#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_full_path="$base_dir/$PARAM_PROJECT_PATH"

# Import "utils.sh".
eval "$SCRIPT_UTILS"

# Detect host OS.
detect-os

# Expand environment name variable parameters.
readonly git_private_token="${!PARAM_GIT_PRIVATE_TOKEN}"
readonly CONTAINER_NAME="${CIRCLE_PROJECT_REPONAME}-${CIRCLE_BUILD_NUM}"

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


if [ -z "${git_private_token}" ]
then
    echo "GIT_PRIVATE_TOKEN unset skipping"
else
    echo "GIT_PRIVATE_TOKEN is set configuring git credentials"
    
    docker exec "$CONTAINER_NAME" "git config --global credential.helper store"
    docker exec "$CONTAINER_NAME" "git config --global --replace-all url.\"https://token:$git_private_token@github.com/\".insteadOf ssh://git@github.com/"
    docker exec "$CONTAINER_NAME" "git config --global --add url.\"https://token:$git_private_token@github.com/\".insteadOf git@github.com"
    docker exec "$CONTAINER_NAME" "git config --global --add url.\"https://token:$git_private_token@github.com/\".insteadOf \"https://github.com/\""
    
    docker exec "$CONTAINER_NAME" "git config --global url.\"https://ssh:$git_private_token@github.com/\".insteadOf \"ssh://git@github.com/\""
    docker exec "$CONTAINER_NAME" "git config --global url.\"https://git:$git_private_token@github.com/\".insteadOf \"git@github.com:\""
    
fi

echo "---------- git config --list -------------"
docker exec "$CONTAINER_NAME" "git config --list"

echo "---------- git config --list --show-origin -------------"
docker exec "$CONTAINER_NAME" "git config --list --show-origin"