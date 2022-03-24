#!/usr/bin/env bash

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_path="${base_dir}/${PARAM_PROJECT_PATH}"
readonly custom_build_path="${base_dir}/${PARAM_BUILD_ARTIFACT_PATH}/${PARAM_BUILD_ARTIFACT_FILENAME}"
readonly jq_path="/usr/local/bin/jq"

printf '%s\n' "Project Path: \"$unity_project_path\"."
printf '%s\n' "Build Name: \"$PARAM_BUILD_NAME\"."
printf '%s\n' "Build Target: \"$PARAM_BUILD_TARGET\"."
printf '%s\n' "Artifact Path: \"$PARAM_BUILD_ARTIFACT_PATH/$PARAM_BUILD_ARTIFACT_FILENAME\"."

download_builder() {
  local unity_builder_tag_list
  local unity_builder_version
  local unity_builder_download_url

  unity_builder_tag_list=$(curl --location --request GET \
    --url https://api.github.com/repos/game-ci/unity-builder/tags \
    --header 'Accept: application/vnd.github.v3+json' | jq -r '.[].name' | grep -v '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -Vr)
  unity_builder_version=$(echo "$unity_builder_tag_list" | head -n 1)
  unity_builder_download_url="https://github.com/game-ci/unity-builder/archive/refs/tags/${unity_builder_version}.tar.gz"

  curl --location "$unity_builder_download_url" --output "$unity_builder_temp_dir/$unity_builder_compressed_file"
}

set_builder() {
  local unity_builder_temp_dir
  local unity_builder_compressed_file

  unity_builder_temp_dir=$(mktemp -d)
  unity_builder_compressed_file="unity-builder.tar.gz"

  if ! download_builder; then
    printf '%s\n' "Failed to download builder."
    exit 1
  fi

  mkdir -p "$unity_project_path/Assets/Editor/"
  tar -xzf "$unity_builder_temp_dir/$unity_builder_compressed_file" -C "$unity_builder_temp_dir" --strip-components 1
  cp -r "$unity_builder_temp_dir/dist/default-build-script/Assets/Editor" "$unity_project_path/Assets/Editor/"
}

install_jq() {
  local jq_version

  if uname -a | grep Darwin 1> /dev/null 2> /dev/null; then
    jq_version=jq-osx-amd64
  else
    jq_version=jq-linux32
  fi

  curl --location https://github.com/stedolan/jq/releases/download/jq-1.6/"${jq_version}" --output "$jq_path"
  chmod +x "$jq_path"
}

# Check if jq is installed
if ! type jq 1> /dev/null 2> /dev/null; then
  printf '%s\n' "The \"jq\" library was not found."
  printf '%s\n' "Since it is is required to run this script, it will be downloaded."

  if ! install_jq; then
    printf '%s\n' "Failed to install \"jq\"."
    exit 1
  fi
fi

# Use GameCI's Unity Builder to build the project 
if [ "$PARAM_EXECUTE_METHOD" == "UnityBuilderAction.Builder.BuildProject" ]; then
  printf '%s\n' "Using GameCI's build method."
  printf '%s\n' "You can check the source code at: https://github.com/game-ci/unity-builder/blob/main/dist/default-build-script/Assets/Editor/UnityBuilderAction/Builder.cs"

  if ! set_builder; then
    printf '%s\n' "Failed to set Unity Builder."
    exit 1
  fi
  
  if [ ! -e "$unity_project_path/Assets/Editor/Editor/UnityBuilderAction/Builder.cs" ]; then
    printf '%s\n' "Something went wrong while setting the Unity Builder."
    printf '%s\n' "Please try again or open an issue on GitHub."
    exit 1
  fi
fi