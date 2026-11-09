#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

check_and_install_saxonb() {
  if ! brew list saxon-b &> /dev/null; then
    printf '%s\n' "Saxon-B is required to parse Unity's XML results to the JUnit format."
    printf '%s\n' "Installing it with Brew."
    brew install saxon-b || return 1
  fi

  saxonb_jar="$(find "$(brew --prefix saxon-b)/" -name saxon9.jar | head -n 1)"
  [ -n "$saxonb_jar" ]
}

check_and_install_java() {
  if ! command -v java &> /dev/null; then
    printf '%s\n' "Java is required to parse Unity's XML results to JUnit."
    printf '%s\n' "Installing it with Brew."
    
    if brew install --cask temurin; then
      printf '%s\n' "Java installed successfully."
      return 0

    else
      printf '%s\n' "Something went wrong."
      printf '%s\n' "Please try again or open an issue."
      return 1

    fi
  fi
}

parse_xml_to_junit() {
  if ! check_and_install_java; then
    printf '%s\n' "Java wasn't found and couldn't be installed."
    printf '%s\n' "It won't be possible to parse Unity's XML results to JUnit."
    return 1
  fi

  if ! check_and_install_saxonb; then
    printf '%s\n' "Saxon-B wasn't found and couldn't be installed."
    printf '%s\n' "Impossible to parse Unity's XML results to JUnit."
    return 1
  fi

  printf '%s\n' "Parsing Unity's XML results to JUnit."
  printf '%s\n' "$DEPENDENCY_NUNIT_TRANSFORM" > "$base_dir/nunit3-junit.xslt"

  java -jar "$saxonb_jar" -s "$base_dir/results.xml" -xsl "$base_dir"/nunit3-junit.xslt > "$unity_project_full_path/$PARAM_TEST_PLATFORM-junit-results.xml"
  saxon_exit_code=$?

  if [ "$saxon_exit_code" -ne 0 ] || [ ! -f "$unity_project_full_path/$PARAM_TEST_PLATFORM-junit-results.xml" ]; then
    printf '%s\n' "Something went wrong."
    printf '%s\n' "Please try again or open an issue."
    return 1

  else
    printf '%s\n' "Unity's XML results parsed to JUnit successfully."
    return 0
  fi
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
