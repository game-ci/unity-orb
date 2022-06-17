#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

readonly container_name="unity_container"

# Add the build target and build name in the environment variables.
docker exec "$container_name" powershell "[System.Environment]::SetEnvironmentVariable('TEST_PLATFORM','$PARAM_TEST_PLATFORM', [System.EnvironmentVariableTarget]::Machine)"

# Run the tests.
docker exec "$container_name" powershell '& "C:\Program Files\Unity\Hub\Editor\*\Editor\Unity.exe" -batchmode -nographics -projectPath $Env:PROJECT_PATH -runTests -testPlatform $Env:TEST_PLATFORM -testResults "C:/results.xml" -logfile | Out-Host'

# Install JDK to run Saxon.
docker exec "$container_name" powershell 'choco upgrade jdk8 --no-progress -y'

# Download and extract Saxon-B.
docker exec "$container_name" powershell 'Invoke-WebRequest -Uri "https://cfhcable.dl.sourceforge.net/project/saxon/Saxon-B/9.1.0.8/saxonb9-1-0-8j.zip" -Method "GET" -OutFile "C:/saxonb.zip"'
docker exec "$container_name" powershell "Expand-Archive -Force C:/saxonb.zip C:/saxonb"

# Copy the Saxon-B template to the container.
docker cp "$gameci_sample_project_dir"/ci/nunit-transforms/nunit3-junit.xslt "$container_name":C:/nunit3-junit.xslt

# Parse Unity's results xml to JUnit format.
docker exec "$container_name" powershell 'java -jar C:/saxonb/saxon9.jar -s C:/results.xml -xsl C:/nunit3-junit.xslt > C:/$Env:TEST_PLATFORM-junit-results.xml'

# Convert CRLF to LF otherwise CircleCI won't be able to read the results.
docker exec unity_container powershell '((Get-Content C:/playmode-junit-results.xml) -join "`n") + "`n" | Set-Content -NoNewline -Encoding utf8 C:/playmode-junit-results-lf.xml'

# Copy test results to the host.
docker cp "$container_name":"$PARAM_TEST_PLATFORM"-junit-results-lf.xml "$unity_project_full_path"/"$PARAM_TEST_PLATFORM"-junit-results.xml