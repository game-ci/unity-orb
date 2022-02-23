#!/usr/bin/env bash

PROJECT_PATH="$CIRCLE_WORKING_DIRECTORY/src"
TEST_RESULTS="$CIRCLE_WORKING_DIRECTORY/results.xml"
TMP_UNITY_DIR=$(mktemp -d 'unity-orb.XXXXXX')
UNITY_EDITOR="$UNITY_PATH/Editor/Unity"
UNITY_LOG_FILE="$TMP_UNITY_DIR/runTests.log"

stdmsg() {
    local IFS=' '
    printf '%s\n' "$*"
}

errmsg() {
    stdmsg "$*" 1>&2
}

xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' "$UNITY_EDITOR" \
 -batchmode \
 -projectPath "$PROJECT_PATH" \
 -runTests \
 -testPlatform "$PARAM_UNITY_TEST_PLATFORM" \
 -testResults "$TEST_RESULTS" \
 -logFile "$UNITY_LOG_FILE"

UNITY_EXIT_CODE=$?
stdmsg "Unity exited with: $UNITY_EXIT_CODE"

if [[ "$PARAM_VERBOSE" -eq 1 ]]; then
    stdmsg "Unity's \"runTests\" output:"
    cat "$UNITY_LOG_FILE"

    stdmsg "Test results:"
    cat "$TEST_RESULTS"
fi