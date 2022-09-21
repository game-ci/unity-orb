#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2048,SC2154,SC2086

readonly build_path="$unity_project_full_path/Builds/$PARAM_BUILD_TARGET"
mkdir -p "$build_path"

set -x
# Build the project
"$UNITY_EDITOR_PATH" \
  -quit \
  -batchmode \
  -nographics \
  -projectPath "$unity_project_full_path" \
  -buildTarget "$PARAM_BUILD_TARGET" \
  -customBuildTarget "$PARAM_BUILD_TARGET" \
  -customBuildPath "$build_path/$PARAM_BUILD_NAME" \
  -executeMethod "$build_method" \
  -buildVersion "1.0.0" \
  -logfile /dev/stdout \
  $PARAM_CUSTOM_PARAMETERS # Needs to be unquoted. Otherwise it will be treated as a single parameter.
set +x

if [ "$PARAM_COMPRESS" -eq 1 ]; then
  printf '%s\n' 'Compressing build artifacts...'

  # Compress artifacts to store them in the artifacts bucket.
  tar -czf "$base_dir/$PARAM_BUILD_TARGET.tar.gz" -C "$build_path" .
fi