#!/usr/bin/env bash

set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
status=0

for test_file in "$ROOT_DIR"/tests/test_*.sh; do
  printf '\n==> %s\n' "$(basename "$test_file")"
  bash "$test_file" || status=1
done

exit "$status"
