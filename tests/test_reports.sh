#!/usr/bin/env bash

set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tests/testlib.sh
source "$ROOT_DIR/tests/testlib.sh"
# shellcheck source=lib/core.sh
source "$ROOT_DIR/lib/core.sh"
# shellcheck source=lib/results.sh
source "$ROOT_DIR/lib/results.sh"
# shellcheck source=lib/report.sh
source "$ROOT_DIR/lib/report.sh"

VERSION="test"
RD_COLOR=0
RD_STARTED_AT="2026-08-24T00:00:00Z"
RD_HOSTNAME="example-host"
RD_QUICK=1
rd_results_reset
rd_add_result "TST-001" "Test" "warn" "medium" "Example" "Host 192.0.2.1 has an issue" "TOKEN=abc123" "Review it" "example-fix"
rd_add_result "TST-002" "Test" "pass" "info" "<script>alert(1)</script>" "Unsafe <b>markup</b> & text" "<img src=x onerror=alert(1)>" "" ""
rd_finalize_score

json="$(rd_report_json -)"
assert_contains "$json" '"schema_version": "1.0"' "JSON includes schema version"
assert_contains "$json" '"score": 93' "JSON includes calculated score"
assert_contains "$json" '[ip]' "JSON redacts IP evidence"
assert_contains "$json" 'TOKEN=[redacted]' "JSON redacts secrets"
assert_not_contains "$json" '\n    {' "JSON uses real newlines between findings"

markdown="$(rd_report_markdown -)"
assert_contains "$markdown" '# VPS Doctor report' "Markdown includes title"
assert_contains "$markdown" 'TST-001' "Markdown includes rule ID"
assert_contains "$markdown" 'example-fix' "Markdown includes fix reference"

html="$(rd_report_html -)"
assert_contains "$html" '<!doctype html>' "HTML includes document declaration"
assert_contains "$html" 'TST-001' "HTML includes rule ID"
assert_contains "$html" 'example-fix' "HTML includes guarded fix reference"
assert_contains "$html" '&lt;script&gt;alert(1)&lt;/script&gt;' "HTML escapes finding titles"
assert_contains "$html" 'Unsafe &lt;b&gt;markup&lt;/b&gt; &amp; text' "HTML escapes finding summaries"
assert_contains "$html" '&lt;img src=x onerror=alert(1)&gt;' "HTML escapes evidence"
assert_not_contains "$html" '<script>alert(1)</script>' "HTML does not render injected script markup"
assert_not_contains "$html" 'src="http' "HTML loads no remote assets"

finish_tests
