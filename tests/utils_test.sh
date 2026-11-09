#!/usr/bin/env bash
# Checks for src/scripts/utils.sh. Run: bash tests/utils_test.sh
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "$0")/../src/scripts/utils.sh"

fail() { printf 'FAIL: %s\n' "$1"; exit 1; }

serial="SC-ABCD-1234-EFGH-5678-IJKL"
developer_data="$(printf '\x01\x02\x03\x04%s' "$serial" | base64 | tr -d '\n')"
license="<?xml version=\"1.0\" encoding=\"UTF-8\"?><root><License id=\"Terms\">
    <DeveloperData Value=\"$developer_data\"/>
  </License></root>"

[ "$(extract-serial-from-license "$license")" = "$serial" ] || fail "raw license"
[ "$(extract-serial-from-license "$(printf '%s' "$license" | base64)")" = "$serial" ] || fail "base64 license"
[ "$(extract-serial-from-license "$(printf '%s' "$license" | base64 | fold -w 76 | sed 's/$/\r/')")" = "$serial" ] || fail "wrapped CRLF base64 license"
[ -z "$(extract-serial-from-license "<root/>" 2>/dev/null || true)" ] || fail "license without serial"

# mask-serial: hides Unity's partially masked serial.
export unity_serial="$serial"
[ "$(printf '%s\n' 'Serial number assigned to (masked): "SC-ABCD-1234-EFGH-5678-XXXX"' | mask-serial)" = 'Serial number assigned to (masked): "[masked]XXXX"' ] || fail "mask-serial"

# retry: succeeds on the 2nd attempt. Skip the backoff delay.
sleep() { :; }
attempts=0
flaky() { attempts=$((attempts + 1)); [ "$attempts" -ge 2 ]; }
retry flaky > /dev/null || fail "retry should succeed"
[ "$attempts" -eq 2 ] || fail "retry attempts: $attempts"
! retry false > /dev/null || fail "retry should give up"

printf '%s\n' "All checks passed."
