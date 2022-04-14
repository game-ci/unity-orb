#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
readonly unity_project_full_path="$base_dir/$PARAM_PROJECT_PATH"
readonly gameci_sample_project_dir=$(mktemp -d)
readonly sample_project_compressed_file="sample_project.tar.gz"

trap_test_script_exit() {
  local -r exit_status="$?"

  if [ "$exit_status" -ne 0 ]; then
    printf '%s\n' 'The script did not complete successfully.'
    printf '%s\n' "The exit code was $exit_status"

    rm -rf "$gameci_sample_project_dir"
    exit "$exit_status"
  fi

  # Intall dependencies for the JUnit parser.
  apt-get update && apt-get install -y default-jre libsaxonb-java

  # Parse Unity's results xml to JUnit format.
  # Inject nunit3-junit.xslt as an env variable like the templates in the slack orb
  saxonb-xslt -s $UNITY_DIR/$TEST_PLATFORM-results.xml -xsl $CI_PROJECT_DIR/ci/nunit-transforms/nunit3-junit.xslt >$UNITY_DIR/$TEST_PLATFORM-junit-results.xml
  
  rm -rf "$gameci_sample_project_dir"
}

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

# Copy GameCI's test script to the base directory.
cp "$gameci_sample_project_dir/ci/test.sh" "$base_dir/test.sh"
chmod +x "$base_dir/test.sh"

# Name variables as required by the "test.sh" script.
readonly TEST_PLATFORM="$PARAM_TEST_PLATFORM"
readonly TEST_TYPE="$PARAM_TEST_TYPE"
readonly UNITY_DIR="$unity_project_full_path"
readonly CI_PROJECT_DIR="$gameci_sample_project_dir"
readonly CI_PROJECT_NAME="$CIRCLE_PROJECT_REPONAME"

# Trap "test.sh" exit otherwise it won't be possible to parse the results to JUnit format.
trap trap_test_script_exit EXIT

# Run the test script.
# shellcheck source=/dev/null
source "$base_dir/test.sh"