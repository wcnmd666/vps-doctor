#!/usr/bin/env bash

set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tests/testlib.sh
source "$ROOT_DIR/tests/testlib.sh"
# shellcheck source=lib/core.sh
source "$ROOT_DIR/lib/core.sh"
# shellcheck source=lib/results.sh
source "$ROOT_DIR/lib/results.sh"

RD_COLOR=0

assert_eq "1.0 GiB" "$(rd_human_kib 1048576)" "formats GiB values"
assert_eq "2.0 MiB" "$(rd_human_kib 2048)" "formats MiB values"
assert_contains "$(rd_redact 'API_SECRET=hunter2')" "API_SECRET=[redacted]" "redacts secret assignments"
assert_contains "$(rd_redact 'peer 203.0.113.42 failed')" "peer [ip] failed" "redacts IPv4-like values"
assert_contains "$(rd_redact 'peer 2001:0db8:0000:0000:0000:ff00:0042:8329 failed')" "peer [ipv6] failed" "redacts full IPv6 literals"
assert_contains "$(rd_redact 'listen [2001:db8::1]:443')" "listen [ipv6]:443" "redacts bracketed IPv6 literals"
assert_contains "$(rd_redact 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.payload.signature')" "Authorization: Bearer [redacted]" "redacts bearer authorization headers"
assert_contains "$(rd_redact 'Bearer abcdefghijklmnop')" "Bearer [redacted]" "redacts standalone bearer tokens"

rd_results_reset
rd_add_result X-001 Test pass info Pass "pass" "" "" ""
rd_add_result X-002 Test warn medium Warn "warn" "" "" ""
rd_add_result X-003 Test fail high Fail "fail" "" "" ""
rd_finalize_score
assert_eq "81" "$RD_SCORE" "calculates severity-weighted score"
assert_eq "1" "$RD_PASS_COUNT" "counts passed rules"
assert_eq "1" "$RD_WARN_COUNT" "counts warnings"
assert_eq "1" "$RD_FAIL_COUNT" "counts failures"
assert_eq "B" "$(rd_score_grade)" "maps score to grade"

finish_tests
