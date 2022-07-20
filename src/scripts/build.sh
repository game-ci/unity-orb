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

if [ "$PLATFORM" = "linux" ]; then
  printf '%s\n' "$SCRIPT_BUILD_LINUX" > "$base_dir/build.sh"

elif [ "$PLATFORM" = "macos" ]; then
  printf '%s\n' "$SCRIPT_BUILD_MACOS" > "$base_dir/build.sh"

elif [ "$PLATFORM" = "windows" ]; then
  printf '%s\n' "$SCRIPT_BUILD_WINDOWS" > "$base_dir/build.sh"

else
  printf '%s\n' "Failed to detect OS."
  printf '%s\n' "Please try again or open an issue."
  exit 1
fi

chmod +x "$base_dir/build.sh"

# shellcheck source=/dev/null
source "$base_dir/build.sh"