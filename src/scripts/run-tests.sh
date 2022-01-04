xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' /opt/unity/Editor/Unity \
 -batchmode \
 -projectPath ${pwd}/src \
 -runTests \
 -testPlatform PlayMode \
 -testResults ./results.xml \
 -logFile /dev/stdout

UNITY_EXIT_CODE=$?

echo "Unity exited with: $UNITY_EXIT_CODE"
cat src/results.xml