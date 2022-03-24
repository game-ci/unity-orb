#!/usr/bin/env bash

BASE_DIR="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"
TEST_RESULTS="$BASE_DIR/results.xml"
TMP_UNITY_DIR=$(mktemp -d 'unity-orb.XXXXXX')
UNITY_EDITOR="$UNITY_PATH/Editor/Unity"
UNITY_TEST_LOG="$TMP_UNITY_DIR/runTests.log"

stdmsg() {
    local IFS=' '
    printf '%s\n' "$*"
}

errmsg() {
    stdmsg "$*" 1>&2
}

trap_exit() {
  # It is critical that the first line capture the exit code. Nothing else can come before this.
  # The exit code recorded here comes from the command that caused the script to exit.
  local exit_status="$?"

  rm -rf "$TMP_UNITY_DIR"

  if [ "$exit_status" -ne 0 ]; then
    errmsg 'The script did not complete successfully.'
    errmsg 'The exit code was '"$exit_status"
  fi
}
trap trap_exit EXIT

xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' "$UNITY_EDITOR" \
 -batchmode \
 -logFile "$UNITY_TEST_LOG" \
 -projectPath "$BASE_DIR/src" \
 -runTests \
 -testPlatform "$PARAM_UNITY_TEST_PLATFORM" \
 -testResults "$TEST_RESULTS"

UNITY_EXIT_CODE=$?

if   [ "$UNITY_EXIT_CODE" -eq 0 ]; then stdmsg "Run succeeded, no failures occurred.";
elif [ "$UNITY_EXIT_CODE" -eq 2 ]; then stdmsg "Run succeeded, some tests failed.";
elif [ "$UNITY_EXIT_CODE" -eq 3 ]; then errmsg "Run failure (other failure).";
else errmsg "Unexpected exit code $UNITY_EXIT_CODE"; fi

if [ "$PARAM_VERBOSE" -eq 1 ]; then cat "$UNITY_TEST_LOG"; fi

stdmsg "Test results:"
cat "$TEST_RESULTS"

exit $UNITY_TEST_EXIT_CODE