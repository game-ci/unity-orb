#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

# xsltproc ships with macOS.
parse_xml_to_junit() {
  printf '%s\n' "$DEPENDENCY_NUNIT_TRANSFORM" > "$base_dir/nunit3-junit.xslt"
  xsltproc "$base_dir/nunit3-junit.xslt" "$base_dir/results.xml" > "$unity_project_full_path/$PARAM_TEST_PLATFORM-junit-results.xml"
}

unity_exit_code=0
set -x
# Run the tests.
# shellcheck disable=SC2086 # $custom_parameters needs to be unquoted. Otherwise it will be treated as a single parameter.
"$UNITY_EDITOR_PATH" \
  -batchmode \
  -nographics \
  -projectPath "$unity_project_full_path" \
  -runTests \
  -testPlatform "$PARAM_TEST_PLATFORM" \
  -testResults "$base_dir/results.xml" \
  -logfile /dev/stdout \
  $custom_parameters || unity_exit_code=$?
set +x

if [ "$unity_exit_code" -eq 0 ]; then
  printf '%s\n' "Run succeeded, no failures occurred.";
  if ! parse_xml_to_junit; then exit 1; fi

elif [ "$unity_exit_code" -eq 2 ]; then
  printf '%s\n' "Run succeeded, some tests failed.";
  if ! parse_xml_to_junit; then exit 1; fi
  # Defer the failure so the results get uploaded first.
  touch "$base_dir/.unity-tests-failed"

elif [ "$unity_exit_code" -eq 3 ]; then
  printf '%s\n' "Run failure (other failure).";
  exit 1
else
  printf '%s\n' "Unexpected exit code $unity_exit_code.";
  exit 1
fi
