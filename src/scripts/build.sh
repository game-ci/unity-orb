#!/usr/bin/env bash

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_full_path="$base_dir/$PARAM_PROJECT_PATH"
readonly build_full_path="$base_dir/$PARAM_BUILD_ARTIFACT_PATH"
readonly build_artifact_full_path="$build_full_path/$PARAM_BUILD_ARTIFACT_FILENAME"
readonly jq_path="/usr/local/bin/jq"
readonly unity_build_log="$base_dir/build.log"

printf '%s\n' "Project Path: \"$unity_project_full_path\"."
printf '%s\n' "Build Name: \"$PARAM_BUILD_NAME\"."
printf '%s\n' "Build Target: \"$PARAM_BUILD_TARGET\"."
printf '%s\n' "Artifact Path: \"$build_artifact_full_path\"."

# Extract this to a standalone command that needs to be run from the job.
download_builder() {
  local unity_builder_tag_list
  local unity_builder_version
  local unity_builder_download_url

  unity_builder_tag_list=$(\
    curl --silent --location --request GET \
      --url https://api.github.com/repos/game-ci/unity-builder/tags \
      --header 'Accept: application/vnd.github.v3+json' \
      | jq -r '.[].name' \
      | grep -v '^v[0-9]+\.[0-9]+\.[0-9]+$' \
      | sort -Vr \
  )
  
  unity_builder_version=$(echo "$unity_builder_tag_list" | head -n 1)
  unity_builder_download_url="https://github.com/game-ci/unity-builder/archive/refs/tags/${unity_builder_version}.tar.gz"

  curl --silent --location "$unity_builder_download_url" --output "$unity_builder_temp_dir/$unity_builder_compressed_file"
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

  mkdir -p "$unity_project_full_path/Assets/Editor/"
  tar -xzf "$unity_builder_temp_dir/$unity_builder_compressed_file" -C "$unity_builder_temp_dir" --strip-components 1
  cp -r "$unity_builder_temp_dir/dist/default-build-script/Assets/Editor" "$unity_project_full_path/Assets/Editor/"

  rm -rf "$unity_builder_temp_dir"
}

install_jq() {
  local jq_version

  if uname -a | grep Darwin 1> /dev/null 2> /dev/null; then
    jq_version=jq-osx-amd64
  else
    jq_version=jq-linux32
  fi

  curl --silent --location https://github.com/stedolan/jq/releases/download/jq-1.6/"${jq_version}" --output "$jq_path"
  chmod +x "$jq_path"
}

# Check if jq is installed
if ! type jq 1> /dev/null 2> /dev/null; then
  printf '%s\n' "The \"jq\" library was not found."
  printf '%s\n' "Since it is is required to run this script, it will be downloaded."

  if ! install_jq; then
    printf '%s\n' "Failed to install \"jq\"."
    exit 1
  else
    printf '%s\n' "jq was installed at: $(which jq)."
  fi
fi

# Use GameCI's Unity Builder to build the project 
if [ "$PARAM_BUILD_METHOD" == "UnityBuilderAction.Builder.BuildProject" ]; then
  printf '%s\n' "Using GameCI's build method."
  printf '%s\n' "You can check what it does at: https://github.com/game-ci/unity-builder/blob/main/dist/default-build-script/Assets/Editor/UnityBuilderAction/Builder.cs"

  if ! set_builder; then
    printf '%s\n' "Failed to set Unity Builder."
    exit 1
  fi
  
  if [ ! -e "$unity_project_full_path/Assets/Editor/Editor/UnityBuilderAction/Builder.cs" ]; then
    printf '%s\n' "Something went wrong while setting the Unity Builder."
    printf '%s\n' "Please try again or open an issue on GitHub."
    exit 1
  fi

else
  printf '%s\n' "Using the provided build method: \"$PARAM_EXECUTE_METHOD\""
fi

# Create build path
if ! mkdir -p "$build_full_path"; then
  printf '%s\n' "Failed to create the build's directory."
  exit 1
fi

printf '%s\n' "Building the project."

unity-editor \
  -logfile "$unity_build_log" \
  -quit \
  -customBuildName "$PARAM_BUILD_NAME" \
  -projectPath "$unity_project_full_path" \
  -buildTarget "$PARAM_BUILD_TARGET" \
  -customBuildPath "$build_artifact_full_path" \
  -executeMethod "$PARAM_BUILD_METHOD" \
  -buildVersion "$PARAM_BUILD_VERSION" \
  ${CUSTOM_PARAMETERS:+"$PARAM_CUSTOM_PARAMETERS"}

if [ "$PARAM_VERBOSE" -eq 1 ]; then 
  cat "$unity_build_log";
fi

# Display results
if grep --quiet "Build succeeded!" "$unity_build_log"; then
  printf '%s\n' "Build succeeded."
  printf '%s\n' "Contents of the build path ($build_full_path):"
  ls -alh "$build_full_path"
else
  printf '%s\n' "Build failed, with exit code $build_exit_code";
fi

# Clean up
if ! rm "$unity_build_log"; then
  printf '%s\n' "Failed to remove the build log."
fi