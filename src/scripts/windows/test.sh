#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

trap_exit() {
  local exit_status="$?"

  if [ "$exit_status" -ne 0 ]; then
    printf '%s\n' 'The script did not complete successfully.'

    printf '%s\n' "Removing the container \"$CONTAINER_NAME\"."
    docker rm -f "$CONTAINER_NAME" &> /dev/null || true
  fi
}
trap trap_exit EXIT

# Add the build target and build name in the environment variables.
docker exec "$CONTAINER_NAME" powershell "[System.Environment]::SetEnvironmentVariable('TEST_PLATFORM','$PARAM_TEST_PLATFORM', [System.EnvironmentVariableTarget]::Machine)"

# Run the tests.
docker exec "$CONTAINER_NAME" powershell '& "C:\Program Files\Unity\Hub\Editor\*\Editor\Unity.exe" -batchmode -nographics -projectPath $Env:PROJECT_PATH -runTests -testPlatform $Env:TEST_PLATFORM -testResults "C:/results.xml" -logfile | Out-Host'

# Install JDK to run Saxon.
docker exec "$CONTAINER_NAME" powershell 'choco upgrade jdk8 --no-progress -y'

# Download and extract Saxon-B.
docker exec "$CONTAINER_NAME" powershell 'Invoke-WebRequest -Uri "https://cfhcable.dl.sourceforge.net/project/saxon/Saxon-B/9.1.0.8/saxonb9-1-0-8j.zip" -Method "GET" -OutFile "C:/saxonb.zip"'
docker exec "$CONTAINER_NAME" powershell "Expand-Archive -Force C:/saxonb.zip C:/saxonb"

# Copy the Saxon-B template to the container.
docker cp "$gameci_sample_project_dir"/ci/nunit-transforms/nunit3-junit.xslt "$CONTAINER_NAME":C:/nunit3-junit.xslt

# Parse Unity's results xml to JUnit format.
docker exec "$CONTAINER_NAME" powershell 'java -jar C:/saxonb/saxon9.jar -s C:/results.xml -xsl C:/nunit3-junit.xslt > C:/$Env:TEST_PLATFORM-junit-results.xml'

# Convert CRLF to LF otherwise CircleCI won't be able to read the results.
# https://stackoverflow.com/a/48919146
docker exec "$CONTAINER_NAME" powershell '((Get-Content C:/playmode-junit-results.xml) -join "`n") + "`n" | Set-Content -NoNewline -Encoding utf8 C:/playmode-junit-results-lf.xml'

# Copy test results to the host.
docker cp "$CONTAINER_NAME":"$PARAM_TEST_PLATFORM"-junit-results-lf.xml "$unity_project_full_path"/"$PARAM_TEST_PLATFORM"-junit-results.xml

# Remove the container.
docker rm -f "$CONTAINER_NAME"