#!/usr/bin/env bash

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_full_path="$base_dir/$PARAM_PROJECT_PATH"
readonly gameci_sample_project_dir=$(mktemp -d)
readonly sample_project_compressed_file="sample_project.tar.gz"

trap_build_script_exit() {
  local -r exit_status="$?"

  # The build script has a "set -x" on it. This will disable it for the rest of the run.
  set +x

  if [ "$exit_status" -ne 0 ]; then
    printf '%s\n' 'The script did not complete successfully.'
    printf '%s\n' "The exit code was $exit_status"

    rm -rf "$gameci_sample_project_dir"
    exit "$exit_status"
  fi

  if [ "$PARAM_COMPRESS" -eq 1 ]; then
    printf '%s\n' 'Compressing build artifacts...'

    # Compress artifacts to store them in the artifacts bucket.
    tar -czf "$base_dir/$PARAM_BUILD_NAME-$PARAM_BUILD_TARGET.tar.gz" -C "$unity_project_full_path/Builds/$PARAM_BUILD_TARGET" .
  fi

  # Clean up.
  rm -rf "$gameci_sample_project_dir"
}

download_sample_project() {
  curl --silent \
    --location "https://gitlab.com/game-ci/unity3d-gitlab-ci-example/-/archive/main/unity3d-gitlab-ci-example-main.tar.gz" \
    --output "$gameci_sample_project_dir/$sample_project_compressed_file"
}

copy_builder_to_project() {
  mkdir -p "$unity_project_full_path/Assets/Editor/"
  cp -r "$gameci_sample_project_dir/Assets/Scripts/Editor/." "$unity_project_full_path/Assets/Editor/"
}

if ! download_sample_project; then
  printf '%s\n' "Failed to download GameCI's sample project."
  printf '%s\n' "Please try again or open an issue."
  rm -rf "$gameci_sample_project_dir"
  exit 1
fi

# Extract sample project.
tar -xzf "$gameci_sample_project_dir/$sample_project_compressed_file" -C "$gameci_sample_project_dir" --strip-components 1

if ! copy_builder_to_project; then
  printf '%s\n' "Failed to copy builder from the sample project to your project."
  printf '%s\n' "Please try again or open an issue."
  rm -rf "$gameci_sample_project_dir"
  exit 1
fi

readonly platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

case "$platform" in
  linux*)
    printf '%s\n' "Detected OS: Linux."

    # Copy GameCI's build script to the base directory.
    cp "$gameci_sample_project_dir/ci/build.sh" "$base_dir/build.sh"
    chmod +x "$base_dir/build.sh"

    # Clean up.
    rm -rf "$gameci_sample_project_dir"

    # Name variables as required by the "build.sh" script.
    readonly BUILD_NAME="$PARAM_BUILD_NAME"
    readonly BUILD_TARGET="$PARAM_BUILD_TARGET"
    readonly UNITY_DIR="$unity_project_full_path"

    export BUILD_NAME
    export BUILD_TARGET
    export UNITY_DIR

    # Trap "build.sh" exit otherwise it won't be possible to zip the artifacts.
    trap trap_build_script_exit EXIT

    # Run the build script.
    # shellcheck source=/dev/null
    source "$base_dir/build.sh"
    ;;
  darwin*)
    printf '%s\n' "Detected OS: macOS."
    ;;
  msys*|cygwin*)
    printf '%s\n' "Detected OS: Windows."
    $SCRIPT_BUILD_WINDOWS
    ;;
  *)
    echo "Unsupported OS: \"$platform\"."
    exit 1
    ;;
esac