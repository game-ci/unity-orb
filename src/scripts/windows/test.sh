#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154,SC2016

trap_exit() {
  local exit_status="$?"

  if [ "$exit_status" -ne 0 ]; then
    printf '%s\n' 'The script did not complete successfully.'

    printf '%s\n' "Removing the container \"$CONTAINER_NAME\"."
    docker rm -f "$CONTAINER_NAME" &> /dev/null || true

    exit "$exit_status"
  fi
}
trap trap_exit EXIT

# Add necessary values in the environment variables.
docker exec "$CONTAINER_NAME" powershell "[System.Environment]::SetEnvironmentVariable('TEST_PLATFORM','$PARAM_TEST_PLATFORM', [System.EnvironmentVariableTarget]::Machine)"
docker exec "$CONTAINER_NAME" powershell "[System.Environment]::SetEnvironmentVariable('CUSTOM_PARAMS','$custom_parameters', [System.EnvironmentVariableTarget]::Machine)"

test_args=(
  '-batchmode'
  '-nographics'
  '-projectPath $Env:PROJECT_PATH'
  '-runTests'
  '-testPlatform $Env:TEST_PLATFORM'
  '-testResults "C:/test/results.xml"'
)

[ -n "$custom_parameters" ] && test_args+=( '$Env:CUSTOM_PARAMS.split()' )

# Run the tests. Remove old results so they can't be reported for this run.
rm -f "$base_dir/test/results.xml"
unity_exit_code=0
set -x
# $LASTEXITCODE stays empty when Unity can't be started: treat it as a failure.
docker exec "$CONTAINER_NAME" powershell "& 'C:\Program Files\Unity\Hub\Editor\*\Editor\Unity.exe' ${test_args[*]} -logfile | Out-Host; if (\$null -eq \$LASTEXITCODE) { exit 1 }; exit \$LASTEXITCODE" || unity_exit_code=$?
set +x

# Exit code 2 means some tests failed: parse and upload the results first. Anything else is a crash.
if [ "$unity_exit_code" -ne 0 ] && [ "$unity_exit_code" -ne 2 ]; then
  printf '%s\n' "Run failed. Exit code $unity_exit_code"
  exit "$unity_exit_code"
fi

# Install JDK to run Saxon.
docker exec "$CONTAINER_NAME" powershell 'choco upgrade jdk8 --no-progress -y'

# Download and extract Saxon-B.
docker exec "$CONTAINER_NAME" powershell 'Invoke-WebRequest -Uri "https://versaweb.dl.sourceforge.net/project/saxon/Saxon-B/9.1.0.8/saxonb9-1-0-8j.zip" -Method "GET" -OutFile "C:/test/saxonb.zip"'
docker exec "$CONTAINER_NAME" powershell "Expand-Archive -Force C:/test/saxonb.zip C:/test/saxonb"

# Copy the Saxon-B template to the container.
printf '%s\n' "$DEPENDENCY_NUNIT_TRANSFORM" > "$base_dir/test/nunit3-junit.xslt"

# Parse Unity's results xml to JUnit format.
docker exec "$CONTAINER_NAME" powershell 'java -jar C:/test/saxonb/saxon9.jar -s C:/test/results.xml -xsl C:/test/nunit3-junit.xslt > C:/test/junit-results.xml'

# Convert CRLF to LF otherwise CircleCI won't be able to read the results.
# https://stackoverflow.com/a/48919146
docker exec "$CONTAINER_NAME" powershell '((Get-Content C:/test/junit-results.xml) -join "`n") + "`n" | Set-Content -NoNewline -Encoding utf8 C:/test/junit-results-lf.xml'

# Move test results to project folder for upload.
# The Windows shell doesn't stop on errors, so fail explicitly when the results are missing.
mv "$base_dir"/test/junit-results-lf.xml "$unity_project_full_path"/"$PARAM_TEST_PLATFORM"-junit-results.xml || exit 1

if [ "$unity_exit_code" -eq 2 ]; then touch "$base_dir/.unity-tests-failed"; fi
