#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

create_manual_activation_file() {
  xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' unity-editor \
    -batchmode \
    -nographics \
    -createManualActivationFile \
    -quit \
    -logfile /dev/null

  # Check if license file was created successfully.
  if ls Unity_v*.alf &> /dev/null; then return 0; else return 1; fi
}

resolve_unity_serial() {
  if [ -n "$unity_username" ] && [ -n "$unity_password" ]; then
    # Serial provided.
    if [ -n "$unity_serial" ]; then
      printf '%s\n' "Detected Unity serial."
      readonly resolved_unity_serial="$unity_serial"

    # License provided.
    elif [ -n "$unity_encoded_license" ]; then
      printf '%s\n' "No serial detected. Extracting it from the encoded license."
      
      if ! extract_serial_from_license; then
        printf '%s\n' "Failed to parse the serial from the Unity license."
        printf '%s\n' "Please try again or open an issue."
        return 1
      
      else
        readonly resolved_unity_serial="$decoded_unity_serial"
      fi

    # Nothing provided.
    else
      printf '%s\n' "If you own a Personal Unity License File (.ulf), please provide it as a base64 encoded string."  
      printf '%s\n' "If you own a Plus or Pro Unity license, please provide your serial."

      if create_manual_activation_file; then
        printf '%s\n' "Should you require a new Personal Activation License File (.alf), rerun the job with SSH and you will find it at \"${base_dir}/$(ls Unity_v*)\""
      fi

      return 1
    fi
  
  # No username or password provided.
  else
    printf '%s\n' "Please provide your Unity's username and password."
    return 1
  fi

  return 0
}

extract_serial_from_license() {
  local unity_license
  local developer_data
  local encoded_serial

  unity_license="$(base64 --decode <<< "$unity_encoded_license")"
  developer_data="$(perl -nle 'print $& while m{<DeveloperData Value\="\K.*?(?="/>)}g' <<< "$unity_license")"
  encoded_serial="$(cut -c 5- <<< "$developer_data")"
  
  readonly decoded_unity_serial="$(base64 --decode <<< "$encoded_serial")"

  if [ -n "$decoded_unity_serial" ]; then return 0; else return 1; fi
}

# Check if serial or encoded license was provided.
# If the latter, extract the serial from the license.
if ! resolve_unity_serial; then
  printf '%s\n' "Failed to find the serial or parse it from the Unity license."
  printf '%s\n' "Please try again or open an issue."
  exit 1
fi

# Activate the Unity Editor.
set -x
xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' unity-editor \
  -batchmode \
  -quit \
  -nographics \
  -username "$unity_username" \
  -password "$unity_password" \
  -serial "$resolved_unity_serial" \
  -logfile /dev/stdout
set +x