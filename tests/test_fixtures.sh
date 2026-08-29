#!/usr/bin/env bash

set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/testlib.sh"
source "$ROOT_DIR/lib/core.sh"
source "$ROOT_DIR/lib/results.sh"
source "$ROOT_DIR/checks/system.sh"
source "$ROOT_DIR/checks/storage.sh"
source "$ROOT_DIR/checks/memory.sh"

fixture_status() {
  local rule_id="$1" i
  for i in "${!RD_IDS[@]}"; do
    if [[ "${RD_IDS[$i]}" == "$rule_id" ]]; then
      printf '%s' "${RD_STATUSES[$i]}"
      return 0
    fi
  done
  return 1
}

make_mock_command() {
  local path="$1" body="$2"
  printf '#!/usr/bin/env bash\n%s\n' "$body" >"$path"
  chmod +x "$path"
}

run_system_fixture() {
  local os_id="$1" pretty="$2" load="$3" cpus="$4" temp mock_bin
  temp="$(mktemp -d)"; mock_bin="$temp/bin"; mkdir -p "$mock_bin" "$temp/etc" "$temp/proc"
  printf 'ID=%s\nPRETTY_NAME="%s"\n' "$os_id" "$pretty" >"$temp/etc/os-release"
  printf '%s 0.00 0.00 1/100 1\n' "$load" >"$temp/proc/loadavg"
  make_mock_command "$mock_bin/nproc" "printf '%s\\n' '$cpus'"
  make_mock_command "$mock_bin/timedatectl" "printf 'yes\\n'"
  rd_results_reset
  PATH="$mock_bin:$PATH" RD_ETC_ROOT="$temp/etc" RD_PROC_ROOT="$temp/proc" check_system
  rm -rf "$temp"
}

run_storage_fixture() {
  local disk_pct="$1" inode_pct="$2" temp mock_bin
  temp="$(mktemp -d)"; mock_bin="$temp/bin"; mkdir -p "$mock_bin"
  cat >"$mock_bin/df" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "-Pi" ]]; then
  printf 'Filesystem Inodes IUsed IFree IUse%% Mounted on\n/dev/mock 1000 $inode_pct $((1000-inode_pct)) ${inode_pct}%% /\n'
else
  printf 'Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/mock 100000 90000 10000 ${disk_pct}%% /\n'
fi
EOF
  chmod +x "$mock_bin/df"
  make_mock_command "$mock_bin/journalctl" "printf 'Archived and active journals take up 512.0M in the file system.\\n'"
  rd_results_reset
  PATH="$mock_bin:$PATH" check_storage
  rm -rf "$temp"
}

run_memory_fixture() {
  local total="$1" available="$2" swap="$3" temp
  temp="$(mktemp -d)"; mkdir -p "$temp/proc"
  cat >"$temp/proc/meminfo" <<EOF
MemTotal:       $total kB
MemAvailable:   $available kB
SwapTotal:      $swap kB
EOF
  rd_results_reset
  RD_PROC_ROOT="$temp/proc" RD_QUICK=1 check_memory
  rm -rf "$temp"
}

run_system_fixture ubuntu "Ubuntu 24.04 LTS" 0.20 2
assert_eq "pass" "$(fixture_status SYS-001)" "Ubuntu fixture is recognized as supported"
assert_eq "pass" "$(fixture_status SYS-002)" "healthy Ubuntu load passes"
assert_eq "pass" "$(fixture_status SYS-003)" "synchronized clock passes"

run_system_fixture debian "Debian GNU/Linux 12" 5.00 2
assert_eq "pass" "$(fixture_status SYS-001)" "Debian fixture is recognized as supported"
assert_eq "warn" "$(fixture_status SYS-002)" "high Debian load warns"

run_storage_fixture 50 20
assert_eq "pass" "$(fixture_status STO-001)" "healthy root filesystem passes"
assert_eq "pass" "$(fixture_status STO-002)" "healthy inode usage passes"

run_storage_fixture 90 95
assert_eq "warn" "$(fixture_status STO-001)" "high root filesystem usage warns"
assert_eq "warn" "$(fixture_status STO-002)" "high inode usage warns"

run_storage_fixture 97 20
assert_eq "fail" "$(fixture_status STO-001)" "critical root filesystem usage fails"

run_memory_fixture 8388608 4194304 1048576
assert_eq "pass" "$(fixture_status MEM-001)" "healthy memory availability passes"
assert_eq "pass" "$(fixture_status MEM-002)" "configured swap passes"
assert_eq "skip" "$(fixture_status MEM-003)" "quick fixture skips journal OOM scan"

run_memory_fixture 2097152 131072 0
assert_eq "warn" "$(fixture_status MEM-001)" "low available memory warns"
assert_eq "warn" "$(fixture_status MEM-002)" "small server without swap warns"

finish_tests
