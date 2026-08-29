#!/usr/bin/env bash

set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tests/testlib.sh
source "$ROOT_DIR/tests/testlib.sh"
# shellcheck source=lib/core.sh
source "$ROOT_DIR/lib/core.sh"
# shellcheck source=lib/results.sh
source "$ROOT_DIR/lib/results.sh"
# shellcheck source=checks/system.sh
source "$ROOT_DIR/checks/system.sh"
# shellcheck source=checks/storage.sh
source "$ROOT_DIR/checks/storage.sh"
# shellcheck source=checks/memory.sh
source "$ROOT_DIR/checks/memory.sh"
# shellcheck source=checks/services.sh
source "$ROOT_DIR/checks/services.sh"
# shellcheck source=checks/network.sh
source "$ROOT_DIR/checks/network.sh"
# shellcheck source=checks/security.sh
source "$ROOT_DIR/checks/security.sh"

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

run_services_fixture() {
  local failed="$1" reboot_required="$2" temp mock_bin
  temp="$(mktemp -d)"; mock_bin="$temp/bin"; mkdir -p "$mock_bin" "$temp/var/run"
  if [[ "$failed" == "1" ]]; then
    make_mock_command "$mock_bin/systemctl" "if [[ \"\${1:-}\" == \"--failed\" ]]; then printf 'broken.service loaded failed failed Broken\\n'; fi"
  else
    make_mock_command "$mock_bin/systemctl" "exit 0"
  fi
  [[ "$reboot_required" == "1" ]] && : >"$temp/var/run/reboot-required"
  rd_results_reset
  PATH="$mock_bin:$PATH" RD_VAR_ROOT="$temp/var" check_services
  rm -rf "$temp"
}

run_network_fixture() {
  local route="$1" dns="$2" temp mock_bin
  temp="$(mktemp -d)"; mock_bin="$temp/bin"; mkdir -p "$mock_bin"
  if [[ "$route" == "1" ]]; then
    make_mock_command "$mock_bin/ip" "if [[ \"\${1:-}\" == \"route\" ]]; then printf 'default via 192.0.2.1 dev eth0\\n'; fi"
  else
    make_mock_command "$mock_bin/ip" "exit 0"
  fi
  if [[ "$dns" == "1" ]]; then make_mock_command "$mock_bin/getent" "exit 0"; else make_mock_command "$mock_bin/getent" "exit 2"; fi
  make_mock_command "$mock_bin/ss" "printf 'LISTEN 0 128 0.0.0.0:22 0.0.0.0:*\\nLISTEN 0 128 0.0.0.0:443 0.0.0.0:*\\n'"
  rd_results_reset
  RD_QUICK=0 PATH="$mock_bin:$PATH" check_network
  rm -rf "$temp"
}

run_security_fixture() {
  local hardened="$1" failures="$2" temp mock_bin
  temp="$(mktemp -d)"; mock_bin="$temp/bin"; mkdir -p "$mock_bin" "$temp/etc/ssh/sshd_config.d"
  if [[ "$hardened" == "1" ]]; then
    make_mock_command "$mock_bin/ufw" "printf 'Status: active\\n'"
    make_mock_command "$mock_bin/sshd" "printf 'permitrootlogin no\\npasswordauthentication no\\n'"
    make_mock_command "$mock_bin/systemctl" "if [[ \"\${1:-}\" == \"is-enabled\" ]]; then printf 'enabled\\n'; fi"
  else
    make_mock_command "$mock_bin/ufw" "printf 'Status: inactive\\n'"
    make_mock_command "$mock_bin/sshd" "printf 'permitrootlogin yes\\npasswordauthentication yes\\n'"
    make_mock_command "$mock_bin/systemctl" "if [[ \"\${1:-}\" == \"is-enabled\" ]]; then printf 'disabled\\n'; fi"
  fi
  if ((failures > 0)); then
    make_mock_command "$mock_bin/journalctl" "for ((i=0;i<$failures;i++)); do printf 'Failed password for invalid user test\\n'; done"
  else
    make_mock_command "$mock_bin/journalctl" "exit 0"
  fi
  rd_results_reset
  RD_QUICK=0 RD_AUTH_FAILURE_WARN=3 PATH="$mock_bin:$PATH" RD_ETC_ROOT="$temp/etc" check_security
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

run_services_fixture 0 0
assert_eq "pass" "$(fixture_status SVC-001)" "healthy service fixture has no failed units"
assert_eq "pass" "$(fixture_status SVC-002)" "healthy service fixture has no reboot marker"
run_services_fixture 1 1
assert_eq "fail" "$(fixture_status SVC-001)" "failed service fixture is detected"
assert_eq "warn" "$(fixture_status SVC-002)" "pending reboot fixture is detected"

run_network_fixture 1 1
assert_eq "pass" "$(fixture_status NET-001)" "default route fixture passes"
assert_eq "pass" "$(fixture_status NET-002)" "DNS success fixture passes"
assert_eq "info" "$(fixture_status NET-003)" "listening port fixture is informational"
run_network_fixture 0 0
assert_eq "fail" "$(fixture_status NET-001)" "missing default route fixture fails"
assert_eq "warn" "$(fixture_status NET-002)" "DNS failure fixture warns"

run_security_fixture 1 0
assert_eq "pass" "$(fixture_status SEC-001)" "active firewall fixture passes"
assert_eq "pass" "$(fixture_status SEC-002)" "disabled root SSH login passes"
assert_eq "pass" "$(fixture_status SEC-003)" "disabled SSH password auth passes"
assert_eq "pass" "$(fixture_status SEC-004)" "quiet authentication log passes"
assert_eq "pass" "$(fixture_status SEC-005)" "enabled unattended upgrades pass"
run_security_fixture 0 4
assert_eq "warn" "$(fixture_status SEC-001)" "inactive firewall fixture warns"
assert_eq "warn" "$(fixture_status SEC-002)" "permissive root SSH policy warns"
assert_eq "warn" "$(fixture_status SEC-003)" "SSH password auth fixture warns"
assert_eq "warn" "$(fixture_status SEC-004)" "authentication failure threshold warns"
assert_eq "warn" "$(fixture_status SEC-005)" "disabled unattended upgrades warn"

finish_tests
