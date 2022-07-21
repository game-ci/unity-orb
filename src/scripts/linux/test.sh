#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

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
  printf '%s\n' "$DEPENDENCY_NUNIT_TRANSFORM" > "$base_dir/nunit3-junit.xslt"
  saxonb-xslt -s "$UNITY_DIR/$TEST_PLATFORM-results.xml" -xsl "$base_dir/nunit3-junit.xslt" > "$UNITY_DIR/$TEST_PLATFORM-junit-results.xml"
  
  cat "$UNITY_DIR/$TEST_PLATFORM-junit-results.xml"

  # Clean up.
  rm -rf "$gameci_sample_project_dir"
}

# Download test script.
curl --silent --location \
  --request GET \
  --url "https://gitlab.com/game-ci/unity3d-gitlab-ci-example/-/raw/main/ci/test.sh" \
  --header 'Accept: application/vnd.github.v3+json' \
  --output "$base_dir/test.sh"

chmod +x "$base_dir/test.sh"

# Name variables as required by the "test.sh" script.
readonly TEST_PLATFORM="$PARAM_TEST_PLATFORM"
readonly TESTING_TYPE="JUNIT"
readonly UNITY_DIR="$unity_project_full_path"
readonly CI_PROJECT_DIR="$gameci_sample_project_dir"
readonly CI_PROJECT_NAME="$CIRCLE_PROJECT_REPONAME"

export TEST_PLATFORM
export TESTING_TYPE
export UNITY_DIR
export CI_PROJECT_DIR
export CI_PROJECT_NAME

# Trap "test.sh" exit otherwise it won't be possible to parse the results to JUnit format.
trap trap_test_script_exit EXIT

# Run the test script.
# shellcheck source=/dev/null
source "$base_dir/test.sh"