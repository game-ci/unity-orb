#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_full_path="$base_dir/$PARAM_PROJECT_PATH"
readonly gameci_sample_project_dir=$(mktemp -d)
readonly sample_project_compressed_file="sample_project.tar.gz"

download_sample_project() {
  curl --silent \
    --location "https://gitlab.com/game-ci/unity3d-gitlab-ci-example/-/archive/main/unity3d-gitlab-ci-example-main.tar.gz" \
    --output "$gameci_sample_project_dir/$sample_project_compressed_file"
}

if ! download_sample_project; then
  printf '%s\n' "Failed to download GameCI's sample project."
  printf '%s\n' "Please try again or open an issue."
  rm -rf "$gameci_sample_project_dir"
  exit 1
fi

# Extract sample project.
tar -xzf "$gameci_sample_project_dir/$sample_project_compressed_file" -C "$gameci_sample_project_dir" --strip-components 1

if [ "$PLATFORM" = "linux" ]; then
  printf '%s\n' "$SCRIPT_TEST_LINUX" > "$base_dir/test.sh"

elif [ "$PLATFORM" = "macos" ]; then
  printf '%s\n' "$SCRIPT_TEST_MACOS" > "$base_dir/test.sh"

elif [ "$PLATFORM" = "windows" ]; then
  printf '%s\n' "$SCRIPT_TEST_WINDOWS" > "$base_dir/test.sh"

else
  printf '%s\n' "Failed to detect OS."
  printf '%s\n' "Please try again or open an issue."
  exit 1
fi

chmod +x "$base_dir/test.sh"

# shellcheck source=/dev/null
source "$base_dir/test.sh"