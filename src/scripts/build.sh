#!/usr/bin/env bash

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_full_path="$base_dir/$PARAM_PROJECT_PATH"

# Import "utils.sh".
eval "$SCRIPT_UTILS"

# Detect host OS.
detect-os

# Copy builder to project directory.
mkdir -p "$unity_project_full_path/Assets/Editor/"
printf '%s\n' "$DEPENDENCY_UNITY_BUILDER" > "$unity_project_full_path/Assets/Editor/BuildCommand.cs"

if [ "$PLATFORM" = "linux" ]; then eval "$SCRIPT_BUILD_LINUX";
elif [ "$PLATFORM" = "macos" ]; then eval "$SCRIPT_BUILD_MACOS";
elif [ "$PLATFORM" = "windows" ]; then eval "$SCRIPT_BUILD_WINDOWS";
fi
