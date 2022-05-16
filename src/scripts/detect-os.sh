#!/usr/bin/env bash

readonly platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

case "$platform" in
  linux*)
    printf '%s\n' "Detected OS: Linux."
    printf '%s\n' "export PLATFORM=linux" >> "$BASH_ENV"
    ;;
  darwin*)
    printf '%s\n' "Detected OS: macOS."
    printf '%s\n' "export PLATFORM=macos" >> "$BASH_ENV"
    ;;
  msys*|cygwin*)
    printf '%s\n' "Detected OS: Windows."
    printf '%s\n' "export PLATFORM=windows" >> "$BASH_ENV"
    ;;
  *)
    echo "Unsupported OS: \"$platform\"."
    exit 1
    ;;
esac