#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

create_manual_activation_file() {
  unity-editor \
    -batchmode \
    -nographics \
    -createManualActivationFile \
    -quit \
    -logfile /dev/null

  # Check if license file was created successfully.
  if ls Unity_v*.alf &> /dev/null; then return 0; else return 1; fi
}

resolve_unity_license() {
  if [ -n "$unity_encoded_license" ]; then
    # Decode Personal Unity License File.
    unity_license=$(printf '%s\n' "$unity_encoded_license" | base64 --decode)

  elif [ -n "$unity_username" ] && [ -n "$unity_password" ] && [ -n "$unity_serial" ]; then
    # Generate Plus or Pro Unity License File.
    unity-editor \
      -logFile /dev/stdout \
      -batchmode \
      -nographics \
      -quit \
      -username "$unity_username" \
      -password "$unity_password" \
      -serial "$unity_serial"

    if [ -e "/root/.local/share/unity3d/Unity/Unity_lic.ulf" ]; then
      unity_license="$(cat /root/.local/share/unity3d/Unity/Unity_lic.ulf)"
    else
      printf '%s\n' "Failed to generate Unity license file."
      printf '%s\n' "Make sure you have entered the correct username, password and serial and try again."
      printf '%s\n' "If you are still having problems, please open an issue."
      printf '%s\n' "See the docs for more details: https://game.ci/docs/circleci/activation#professional-license"

      return 1
    fi

  else
    printf '%s\n' "If you own a Personal Unity License File (.ulf), please provide it as a base64 encoded string."  
    printf '%s\n' "If you own a Plus or Pro Unity license, please provide your username, password and serial."
    printf '%s\n' "See the docs for more details: https://game.ci/docs/circleci/activation"

    if create_manual_activation_file; then
      printf '%s\n' "Should you require a new Personal Activation License File (.alf), rerun the job with SSH and you will find it at \"${base_dir}/$(ls Unity_v*)\""
    fi

    return 1
  fi
}

# Check if serial or encoded license was provided.
# If the latter, extract the serial from the license.
if ! resolve_unity_license; then
  printf '%s\n' "Failed to find the serial or parse it from the Unity license."
  printf '%s\n' "Please try again or open an issue."
  exit 1
fi

# We need to set the build target for a keystore to be created
# Nomenclature required by the script.

echo "1846362 BUILD TARGET"
readonly BUILD_TARGET="$PARAM_BUILD_TARGET"
export BUILD_TARGET
echo $BUILD_TARGET

echo "9999 ANDROID_APP_BUNDLE is "
echo $ANDROID_APP_BUNDLE

readonly UNITY_LICENSE="$unity_license"
export UNITY_LICENSE

set -e
set -x
mkdir -p /root/.cache/unity3d
mkdir -p /root/.local/share/unity3d/Unity/
set +x

unity_license_destination=/root/.local/share/unity3d/Unity/Unity_lic.ulf
android_keystore_destination=keystore.keystore

echo "here 1"
upper_case_build_target=${BUILD_TARGET^^};

echo "here 2"

if [ "$upper_case_build_target" = "ANDROID" ]; then
    if [ -n "$ANDROID_KEYSTORE_BASE64" ]; then
        echo "ANDROID_KEYSTORE_BASE64 env found, decoding content into ${android_keystore_destination}"
        echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > ${android_keystore_destination}
    else
        echo "ANDROID_KEYSTORE_BASE64 env var not found, building with Unity's default debug keystore"
    fi
fi

echo "here 3"

if [ -n "$UNITY_LICENSE" ]; then
    echo "Writing 'UNITY_LICENSE' to license file ${unity_license_destination}"
    echo "${UNITY_LICENSE}" | tr -d '\r' > ${unity_license_destination}
else
    echo "'UNITY_LICENSE' env var not found"
fi

echo "done"
