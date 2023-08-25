#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

parse_results_to_junit() {
  # Intall dependencies for the JUnit parser.
  apt-get update && apt-get install -y default-jre libsaxonb-java

  # Parse Unity's results xml to JUnit format.
  printf '%s\n' "$DEPENDENCY_NUNIT_TRANSFORM" >"$base_dir/nunit3-junit.xslt"
  saxonb-xslt -s "$unity_project_full_path/$PARAM_TEST_PLATFORM-results.xml" -xsl "$base_dir/nunit3-junit.xslt" >"$unity_project_full_path/$PARAM_TEST_PLATFORM-junit-results.xml"
}

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
  $custom_parameters
unity_exit_code=$?
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

# Check if the Code Coverage package is installed and move the coverage results to the root of the project.
if grep -q "$code_coverage_package" "$package_manifest_path"; then
  grep "$unity_project_full_path"/"$PARAM_TEST_PLATFORM"-coverage/Report/Summary.xml Linecoverage
  mv "$unity_project_full_path"/"$PARAM_TEST_PLATFORM"-coverage/"$CIRCLE_PROJECT_REPONAME"-opencov/*Mode/TestCoverageResults_*.xml "$unity_project_full_path"/"$PARAM_TEST_PLATFORM"-coverage/coverage.xml
  rm -r "$unity_project_full_path"/"$PARAM_TEST_PLATFORM"-coverage/"$CIRCLE_PROJECT_REPONAME"-opencov/
else
  {
    echo -e "\033[33mCode Coverage package not found in $package_manifest_path. Please install the package \"Code Coverage\" through Unity's Package Manager to enable coverage reports.\033[0m"
  } 2>/dev/null
fi

exit "$unity_exit_code"
