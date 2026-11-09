#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

parse_results_to_junit() {
  # Install xsltproc to convert Unity's results to JUnit. Retry: Ubuntu mirrors have outages.
  # shellcheck disable=SC2329 # Called through retry.
  install_xsltproc() { apt-get update && apt-get install -y --no-install-recommends xsltproc; }
  command -v xsltproc > /dev/null || retry install_xsltproc

  printf '%s\n' "$DEPENDENCY_NUNIT_TRANSFORM" > "$base_dir/nunit3-junit.xslt"
  xsltproc "$base_dir/nunit3-junit.xslt" "$unity_project_full_path/$PARAM_TEST_PLATFORM-results.xml" > "$unity_project_full_path/$PARAM_TEST_PLATFORM-junit-results.xml"
}

unity_exit_code=0
set -x
# shellcheck disable=SC2086 # $custom_parameters needs to be unquoted. Otherwise it will be treated as a single parameter.
${UNITY_EXECUTABLE:-xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' unity-editor} \
  -projectPath "$unity_project_full_path" \
  -runTests \
  -testPlatform "$PARAM_TEST_PLATFORM" \
  -testResults "$unity_project_full_path"/"$PARAM_TEST_PLATFORM"-results.xml \
  -logFile /dev/stdout \
  -batchmode \
  -nographics \
  -enableCodeCoverage \
  -coverageResultsPath "$unity_project_full_path"/"$PARAM_TEST_PLATFORM"-coverage \
  -coverageOptions "generateAdditionalMetrics;generateHtmlReport;generateHtmlReportHistory;generateBadgeReport;" \
  -debugCodeOptimization \
  $custom_parameters || unity_exit_code=$?
set +x

if [ "$unity_exit_code" -eq 0 ] || [ "$unity_exit_code" -eq 2 ]; then
  printf '%s\n' "Run succeeded. Exit code $unity_exit_code"
  parse_results_to_junit
  # Print the results to the console.
  cat "$unity_project_full_path/$PARAM_TEST_PLATFORM-junit-results.xml"
else
  printf '%s\n' "Run failed. Exit code $unity_exit_code"
fi

code_coverage_package="com.unity.testtools.codecoverage"
package_manifest_path="$unity_project_full_path/Packages/manifest.json"

if grep -q "$code_coverage_package" "$package_manifest_path"; then
  grep Linecoverage "$unity_project_full_path/$PARAM_TEST_PLATFORM-coverage/Report/Summary.xml" || true
else
  printf '\033[33m%s\033[0m\n' "Code Coverage package not found in $package_manifest_path. Install the \"Code Coverage\" package through Unity's Package Manager to enable coverage reports."
fi

# Exit code 2 means some tests failed: defer the failure so the results get uploaded first.
if [ "$unity_exit_code" -eq 2 ]; then touch "$base_dir/.unity-tests-failed"; exit 0; fi
exit "$unity_exit_code"
