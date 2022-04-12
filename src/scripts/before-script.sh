#!/usr/bin/env bash

readonly base_dir="${CIRCLE_WORKING_DIRECTORY/\~/$HOME}"

download_before_script() {
  curl --silent --location \
    --request GET \
    --url "https://gitlab.com/game-ci/unity3d-gitlab-ci-example/-/raw/main/ci/before_script.sh" \
    --header 'Accept: application/vnd.github.v3+json' \
    --output "$base_dir/before_script.sh"
}

if ! download_before_script; then
  printf '%s\n' "Failed to download \"before_script.sh\"."
  exit 1
fi

chmod +x "$base_dir/before_script.sh"

# Decode Unity license.
readonly encoded_unity_license="${!PARAM_UNITY_LICENSE_VAR_NAME}"
readonly decoded_unity_license=$(printf '%s\n' "$encoded_unity_license" | base64 --decode)

# Nomenclature required by the script.
readonly UNITY_LICENSE="$decoded_unity_license"

export UNITY_LICENSE

# Run the test script.
# shellcheck source=/dev/null
source "$base_dir/before_script.sh"
