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
      printf '%s\n' "Unsupported OS: \"$platform\"."
      exit 1
      ;;
  esac

  export readonly PLATFORM
}