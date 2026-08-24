#!/usr/bin/env bash

check_system() {
  local os_id="unknown" os_name="Unknown Linux" load1="0" cpus=1 limit status summary sync_state
  if [[ -r /etc/os-release ]]; then
    os_id="$(grep -E '^ID=' /etc/os-release | head -n1 | cut -d= -f2- | tr -d '"' || true)"
    os_name="$(grep -E '^PRETTY_NAME=' /etc/os-release | head -n1 | cut -d= -f2- | tr -d '"' || true)"
  fi
  case "$os_id" in
    ubuntu|debian) rd_add_result "SYS-001" "System" "pass" "info" "Supported operating system" "$os_name is supported." "$os_id" "" "" ;;
    *) rd_add_result "SYS-001" "System" "warn" "low" "Operating system compatibility" "$os_name has not been validated by this release." "$os_id" "Use Ubuntu 20.04+ or Debian 11+ for tested behavior." "" ;;
  esac

  [[ -r /proc/loadavg ]] && load1="$(awk '{print $1}' /proc/loadavg)"
  rd_command_exists nproc && cpus="$(nproc 2>/dev/null || printf 1)"
  [[ "$cpus" =~ ^[0-9]+$ && "$cpus" -gt 0 ]] || cpus=1
  limit="$(awk -v c="$cpus" 'BEGIN { printf "%.2f", c*1.5 }')"
  status="$(awk -v l="$load1" -v x="$limit" 'BEGIN { print (l>x)?"warn":"pass" }')"
  summary="1-minute load is $load1 across $cpus CPU(s)."
  if [[ "$status" == "warn" ]]; then
    rd_add_result "SYS-002" "System" "warn" "medium" "CPU load pressure" "$summary" "load1=$load1 cpu=$cpus" "Inspect top CPU consumers with: ps aux --sort=-%cpu | head" ""
  else
    rd_add_result "SYS-002" "System" "pass" "info" "CPU load pressure" "$summary" "load1=$load1 cpu=$cpus" "" ""
  fi

  if rd_command_exists timedatectl; then
    sync_state="$(timedatectl show -p NTPSynchronized --value 2>/dev/null || true)"
    if [[ "$sync_state" == "yes" ]]; then
      rd_add_result "SYS-003" "System" "pass" "info" "Time synchronization" "The system clock reports synchronized." "NTPSynchronized=yes" "" ""
    else
      rd_add_result "SYS-003" "System" "warn" "low" "Time synchronization" "The system clock does not report active synchronization." "NTPSynchronized=${sync_state:-unknown}" "Enable an NTP service; incorrect time can break TLS and logs." "enable-timesync"
    fi
  else
    rd_add_result "SYS-003" "System" "skip" "info" "Time synchronization" "timedatectl is not available." "" "Confirm that an NTP client is running." ""
  fi
}
