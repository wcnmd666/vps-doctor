#!/usr/bin/env bash

set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/testlib.sh"
source "$ROOT_DIR/lib/core.sh"
source "$ROOT_DIR/lib/results.sh"

reset_config_state() {
  RD_DOMAINS=""
  RD_DISK_WARN=85
  RD_DISK_FAIL=95
  RD_MEMORY_WARN=15
  RD_AUTH_FAILURE_WARN=100
  RD_EXCLUSIONS=()
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

reset_config_state
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

reset_config_state
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

reset_config_state
rd_load_config "$temp/boundary.conf"
assert_eq "1" "$RD_DISK_WARN" "lower percentage boundary is accepted"
assert_eq "100" "$RD_DISK_FAIL" "upper percentage boundary is accepted"
assert_eq "100" "$RD_MEMORY_WARN" "memory upper boundary is accepted"
assert_eq "1" "$RD_AUTH_FAILURE_WARN" "minimum positive auth threshold is accepted"

cat >"$temp/exclusions.conf" <<'EOF'
EXCLUDE_RULES="WEB-002=No public domain on this host;STO-003=Ephemeral test VM;NOPE-999=Unknown rule;MEM-001="
EOF

reset_config_state
rd_load_config "$temp/exclusions.conf" 2>"$temp/exclusion-warnings.log"
assert_eq "No public domain on this host" "${RD_EXCLUSIONS[WEB-002]:-}" "known rule exclusion keeps its reason"
assert_eq "Ephemeral test VM" "${RD_EXCLUSIONS[STO-003]:-}" "multiple exclusions are parsed"
assert_eq "" "${RD_EXCLUSIONS[NOPE-999]:-}" "unknown rule exclusion is ignored"
assert_eq "" "${RD_EXCLUSIONS[MEM-001]:-}" "exclusion without reason is ignored"
assert_contains "$(cat "$temp/exclusion-warnings.log")" "Ignoring unknown rule exclusion" "unknown rule exclusion produces a warning"
assert_contains "$(cat "$temp/exclusion-warnings.log")" "without a reason" "missing exclusion reason produces a warning"

rd_results_reset
rd_add_result "WEB-002" "Web" "fail" "high" "Configured domain DNS and TLS expiry" "TLS expired" "secret evidence" "repair" "some-fix"
rd_finalize_score
assert_eq "skip" "${RD_STATUSES[0]}" "excluded rule is reported as skipped"
assert_contains "${RD_SUMMARIES[0]}" "No public domain on this host" "excluded result exposes the configured reason"
assert_eq "100" "$RD_SCORE" "excluded rule does not reduce health score"
assert_eq "" "${RD_EVIDENCE[0]}" "excluded rule does not retain original evidence"
assert_eq "" "${RD_FIXES[0]}" "excluded rule cannot expose a repair action"

finish_tests
