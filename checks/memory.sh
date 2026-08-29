#!/usr/bin/env bash

check_memory() {
  local total=0 available=0 swap=0 pct=0 oom_count=0
  local proc_root="${RD_PROC_ROOT:-/proc}"
  if [[ -r "$proc_root/meminfo" ]]; then
    total="$(awk '/^MemTotal:/ {print $2}' "$proc_root/meminfo")"
    available="$(awk '/^MemAvailable:/ {print $2}' "$proc_root/meminfo")"
    swap="$(awk '/^SwapTotal:/ {print $2}' "$proc_root/meminfo")"
  fi
  [[ "$total" =~ ^[0-9]+$ && "$total" -gt 0 ]] && pct=$((available * 100 / total))
  if ((pct < RD_MEMORY_WARN)); then
    rd_add_result "MEM-001" "Memory" "warn" "high" "Available memory" "Only ${pct}% ($(rd_human_kib "$available")) of memory is readily available." "total_kib=$total available_kib=$available" "Inspect memory consumers with: ps aux --sort=-%mem | head" ""
  else
    rd_add_result "MEM-001" "Memory" "pass" "info" "Available memory" "${pct}% ($(rd_human_kib "$available")) of memory is available." "total_kib=$total available_kib=$available" "" ""
  fi

  if ((swap == 0)) && ((total < 4194304)); then
    rd_add_result "MEM-002" "Memory" "warn" "medium" "Swap availability" "No swap is configured on a server with less than 4 GiB RAM." "swap_kib=0" "A small swap file can reduce abrupt out-of-memory termination." "create-swap"
  else
    rd_add_result "MEM-002" "Memory" "pass" "info" "Swap availability" "Configured swap: $(rd_human_kib "$swap")." "swap_kib=$swap" "" ""
  fi

  if [[ "$RD_QUICK" == "1" ]] || ! rd_command_exists journalctl; then
    rd_add_result "MEM-003" "Memory" "skip" "info" "Recent out-of-memory events" "Skipped in quick mode or journalctl unavailable." "" "" ""
  else
    oom_count="$(journalctl --since '24 hours ago' -k --no-pager 2>/dev/null | grep -Eci 'out of memory|oom-killer|killed process' || true)"
    if ((oom_count > 0)); then
      rd_add_result "MEM-003" "Memory" "fail" "high" "Recent out-of-memory events" "Detected $oom_count kernel OOM-related log entries in the last 24 hours." "oom_entries=$oom_count" "Identify the killed process before adding memory or changing limits." ""
    else
      rd_add_result "MEM-003" "Memory" "pass" "info" "Recent out-of-memory events" "No kernel OOM events were found in the last 24 hours." "oom_entries=0" "" ""
    fi
  fi
}
