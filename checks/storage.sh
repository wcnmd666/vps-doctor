#!/usr/bin/env bash

check_storage() {
  local line used avail pct ipct journal=""
  line="$(df -Pk / 2>/dev/null | awk 'NR==2 {print $3" "$4" "$5}' || true)"
  read -r used avail pct <<<"$line"
  pct="${pct%%%}"; used="${used:-0}"; avail="${avail:-0}"; pct="${pct:-0}"
  if ((pct >= RD_DISK_FAIL)); then
    rd_add_result "STO-001" "Storage" "fail" "critical" "Root filesystem usage" "Root disk is ${pct}% full with $(rd_human_kib "$avail") available." "used_kib=$used available_kib=$avail" "Free space immediately; full disks can corrupt services and databases." "vacuum-journal"
  elif ((pct >= RD_DISK_WARN)); then
    rd_add_result "STO-001" "Storage" "warn" "high" "Root filesystem usage" "Root disk is ${pct}% full with $(rd_human_kib "$avail") available." "used_kib=$used available_kib=$avail" "Find large directories with: sudo du -xhd1 / | sort -h" "vacuum-journal"
  else
    rd_add_result "STO-001" "Storage" "pass" "info" "Root filesystem usage" "Root disk is ${pct}% full with $(rd_human_kib "$avail") available." "used_kib=$used available_kib=$avail" "" ""
  fi

  ipct="$(df -Pi / 2>/dev/null | awk 'NR==2 {gsub("%", "", $5); print $5}' || printf 0)"
  [[ "$ipct" =~ ^[0-9]+$ ]] || ipct=0
  if ((ipct >= 90)); then
    rd_add_result "STO-002" "Storage" "warn" "high" "Filesystem inode usage" "Root filesystem inode usage is ${ipct}%." "inode_percent=$ipct" "Find directories containing very large numbers of small files." ""
  else
    rd_add_result "STO-002" "Storage" "pass" "info" "Filesystem inode usage" "Root filesystem inode usage is ${ipct}%." "inode_percent=$ipct" "" ""
  fi

  if rd_command_exists journalctl; then
    journal="$(journalctl --disk-usage 2>/dev/null | tail -n1 || true)"
    if [[ "$journal" =~ ([0-9]+([.][0-9]+)?)G ]]; then
      rd_add_result "STO-003" "Storage" "warn" "medium" "System journal size" "${journal:-Journal size could not be read.}" "$journal" "Vacuum old journals while retaining recent incident evidence." "vacuum-journal"
    else
      rd_add_result "STO-003" "Storage" "pass" "info" "System journal size" "${journal:-Journal size could not be read.}" "$journal" "" ""
    fi
  else
    rd_add_result "STO-003" "Storage" "skip" "info" "System journal size" "journalctl is not available." "" "" ""
  fi
}
