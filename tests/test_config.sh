#!/usr/bin/env bash

set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/testlib.sh"
source "$ROOT_DIR/lib/core.sh"

reset_thresholds() {
  RD_DOMAINS=""
  RD_DISK_WARN=85
  RD_DISK_FAIL=95
  RD_MEMORY_WARN=15
  RD_AUTH_FAILURE_WARN=100
}

temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT

cat >"$temp/valid.conf" <<'EOF'
DOMAINS="example.com"
DISK_WARN=80
DISK_FAIL=92
MEMORY_WARN=20
AUTH_FAILURE_WARN=75
EOF

reset_thresholds
rd_load_config "$temp/valid.conf"
assert_eq "80" "$RD_DISK_WARN" "valid disk warning threshold is applied"
assert_eq "92" "$RD_DISK_FAIL" "valid disk failure threshold is applied"
assert_eq "20" "$RD_MEMORY_WARN" "valid memory threshold is applied"
assert_eq "75" "$RD_AUTH_FAILURE_WARN" "valid auth threshold is applied"
assert_eq "example.com" "$RD_DOMAINS" "domain configuration remains supported"

cat >"$temp/invalid.conf" <<'EOF'
DISK_WARN=99
DISK_FAIL=90
MEMORY_WARN=0
AUTH_FAILURE_WARN=not-a-number
EOF

reset_thresholds
rd_load_config "$temp/invalid.conf" 2>"$temp/warnings.log"
assert_eq "85" "$RD_DISK_WARN" "reversed disk thresholds keep safe defaults"
assert_eq "95" "$RD_DISK_FAIL" "invalid disk failure threshold keeps safe default"
assert_eq "15" "$RD_MEMORY_WARN" "out-of-range memory threshold keeps safe default"
assert_eq "100" "$RD_AUTH_FAILURE_WARN" "invalid auth threshold keeps safe default"
assert_contains "$(cat "$temp/warnings.log")" "Ignoring invalid disk thresholds" "invalid disk thresholds produce a warning"
assert_contains "$(cat "$temp/warnings.log")" "Ignoring invalid MEMORY_WARN" "invalid memory threshold produces a warning"
assert_contains "$(cat "$temp/warnings.log")" "Ignoring invalid AUTH_FAILURE_WARN" "invalid auth threshold produces a warning"

cat >"$temp/boundary.conf" <<'EOF'
DISK_WARN=1
DISK_FAIL=100
MEMORY_WARN=100
AUTH_FAILURE_WARN=1
EOF

reset_thresholds
rd_load_config "$temp/boundary.conf"
assert_eq "1" "$RD_DISK_WARN" "lower percentage boundary is accepted"
assert_eq "100" "$RD_DISK_FAIL" "upper percentage boundary is accepted"
assert_eq "100" "$RD_MEMORY_WARN" "memory upper boundary is accepted"
assert_eq "1" "$RD_AUTH_FAILURE_WARN" "minimum positive auth threshold is accepted"

finish_tests
