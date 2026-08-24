#!/usr/bin/env bash

check_services() {
  local failed=0 names=""
  if rd_command_exists systemctl; then
    failed="$(systemctl --failed --no-legend --no-pager 2>/dev/null | grep -c . || true)"
    names="$(systemctl --failed --no-legend --no-pager 2>/dev/null | awk '{print $1}' | head -n5 | paste -sd, - || true)"
    if ((failed > 0)); then
      rd_add_result "SVC-001" "Services" "fail" "high" "Failed systemd services" "$failed systemd unit(s) are in a failed state." "$names" "Inspect each unit with: systemctl status <unit> and journalctl -u <unit>" ""
    else
      rd_add_result "SVC-001" "Services" "pass" "info" "Failed systemd services" "No failed systemd units were reported." "failed=0" "" ""
    fi
  else
    rd_add_result "SVC-001" "Services" "skip" "info" "Failed services" "systemctl is not available." "" "" ""
  fi

  if [[ -e /var/run/reboot-required ]]; then
    rd_add_result "SVC-002" "Services" "warn" "low" "Pending reboot" "The operating system reports that a reboot is required." "/var/run/reboot-required exists" "Schedule a controlled reboot after checking active workloads." ""
  else
    rd_add_result "SVC-002" "Services" "pass" "info" "Pending reboot" "No reboot-required marker was found." "" "" ""
  fi
}
