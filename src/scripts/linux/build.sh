#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2048,SC2154,SC2086

readonly build_path="$unity_project_full_path/Builds/$PARAM_BUILD_TARGET"
mkdir -p "$build_path"

set -x
${UNITY_EXECUTABLE:-xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' unity-editor} \
  -projectPath "$unity_project_full_path" \
  -quit \
  -batchmode \
  -nographics \
  -buildTarget "$PARAM_BUILD_TARGET" \
  -customBuildTarget "$PARAM_BUILD_TARGET" \
  -customBuildName "$PARAM_BUILD_NAME" \
  -customBuildPath "$build_path" \
  -executeMethod "$build_method" \
  -logFile /dev/stdout \
  $custom_parameters # Needs to be unquoted. Otherwise it will be treated as a single parameter.
set +x

if [ "$PARAM_COMPRESS" -eq 1 ]; then
  printf '%s\n' 'Compressing build artifacts...'

  # Compress artifacts to store them in the artifacts bucket.
  tar -czf "$base_dir/$PARAM_BUILD_TARGET.tar.gz" -C "$build_path" .
fi