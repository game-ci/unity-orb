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

if ! create_manual_activation_file; then
  printf '%s\n' "Failed to create Unity license file."
  printf '%s\n' "Please try again or open an issue."
  exit 1
fi

mv Unity_v*.alf Unity.alf