#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2329 # Variables and the docker stub are used by the sourced script.
# Checks exit code handling in src/scripts/windows/test.sh with a fake docker. Run: bash tests/windows_test_test.sh
set -uo pipefail

script="$(cd "$(dirname "$0")/.." && pwd)/src/scripts/windows/test.sh"
fail() { printf 'FAIL: %s\n' "$1"; exit 1; }

# Runs the script with Unity exiting with $1. $2=1 makes the result conversion produce nothing.
# Prints the script's exit code and whether the failed tests marker exists.
run() {
  local dir
  dir="$(mktemp -d)"
  mkdir -p "$dir/test" "$dir/project"
  (
    export UNITY_RC="$1" NO_RESULTS="${2:-0}" base_dir="$dir"
    docker() {
      case "$*" in
        *Unity.exe*) return "$UNITY_RC" ;;
        *junit-results-lf.xml*) [ "$NO_RESULTS" = 1 ] || touch "$base_dir/test/junit-results-lf.xml" ;;
      esac
      return 0
    }
    CONTAINER_NAME=test unity_project_full_path="$dir/project" PARAM_TEST_PLATFORM=editmode \
      custom_parameters="" DEPENDENCY_NUNIT_TRANSFORM="" PARAM_PROJECT_PATH=project
    # shellcheck disable=SC1090
    source "$script"
  ) > /dev/null 2>&1
  printf '%s %s\n' "$?" "$([ -f "$dir/.unity-tests-failed" ] && echo marker || echo none)"
  rm -rf "$dir"
}

[ "$(run 0)" = "0 none" ] || fail "tests pass: $(run 0)"
[ "$(run 2)" = "0 marker" ] || fail "tests fail: $(run 2)"
[ "$(run 3)" = "3 none" ] || fail "Unity crash: $(run 3)"
[ "$(run 0 1)" = "1 none" ] || fail "missing results: $(run 0 1)"

printf '%s\n' "All checks passed."
