#!/bin/false
# shellcheck shell=bash
# shellcheck disable=SC2154

detect-os() {
  local detected_platform

  detected_platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

  case "$detected_platform" in
    linux*)
      printf '%s\n' "Detected OS: Linux."
      PLATFORM=linux
      ;;
    darwin*)
      printf '%s\n' "Detected OS: macOS."
      PLATFORM=macos
      ;;
    msys*|cygwin*)
      printf '%s\n' "Detected OS: Windows."
      PLATFORM=windows
      ;;
    *)
      printf '%s\n' "Unsupported OS: \"$detected_platform\"."
      exit 1
      ;;
  esac

  export PLATFORM
}

# Print the serial stored in a Unity license file (.ulf), given its raw or base64-encoded content.
# The serial is base64-encoded in the "DeveloperData" field, prefixed with 4 garbage bytes.
# Same logic as GameCI's unity-builder.
extract-serial-from-license() {
  local license="$1"

  case "$license" in
    *DeveloperData*) ;;
    *) license="$(printf '%s' "$license" | tr -d '[:space:]' | base64 --decode)" || return 1 ;;
  esac

  printf '%s\n' "$license" \
    | sed -n 's/.*<DeveloperData Value="\([^"]*\)".*/\1/p' \
    | base64 --decode \
    | tail -c +5
}

# Run a command up to 5 times with exponential backoff (15s, 30s, 60s, 120s).
# Unity's login servers rate-limit parallel activations of the same account.
retry() {
  local attempt=1
  local delay=15

  until "$@"; do
    if [ "$attempt" -ge 5 ]; then return 1; fi
    printf '%s\n' "Attempt $attempt failed. Retrying in ${delay}s..."
    sleep "$delay"
    attempt=$((attempt + 1))
    delay=$((delay * 2))
  done
}

# Hide serials in Unity's output. Unity prints them with only the last 4 characters replaced by
# "XXXX", which CircleCI's secret masking doesn't catch.
mask-serial() {
  sed -E 's/[A-Z0-9]{2}(-[A-Z0-9]{4}){5}/[masked]/g'
}
