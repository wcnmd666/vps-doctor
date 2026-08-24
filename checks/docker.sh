#!/usr/bin/env bash

check_docker() {
  local bad=0 names="" large=0 evidence=""
  if ! rd_command_exists docker; then
    rd_add_result "CTR-001" "Containers" "skip" "info" "Docker daemon" "Docker is not installed; container checks are not applicable." "" "" ""
    rd_add_result "CTR-002" "Containers" "skip" "info" "Container health" "Docker is not installed." "" "" ""
    rd_add_result "CTR-003" "Containers" "skip" "info" "Docker JSON logs" "Docker is not installed." "" "" ""
    return
  fi

  if docker info >/dev/null 2>&1; then
    rd_add_result "CTR-001" "Containers" "pass" "info" "Docker daemon" "The Docker daemon is reachable." "docker info succeeded" "" ""
  else
    rd_add_result "CTR-001" "Containers" "fail" "high" "Docker daemon" "Docker is installed but the daemon is not reachable." "docker info failed" "Check systemctl status docker and socket permissions." ""
    rd_add_result "CTR-002" "Containers" "skip" "info" "Container health" "Skipped because the Docker daemon is unavailable." "" "" ""
    rd_add_result "CTR-003" "Containers" "skip" "info" "Docker JSON logs" "Skipped because the Docker daemon is unavailable." "" "" ""
    return
  fi

  names="$(docker ps --format '{{.Names}} {{.Status}}' 2>/dev/null | grep -Ei 'unhealthy|restarting' | head -n8 || true)"
  [[ -z "$names" ]] || bad="$(grep -c . <<<"$names")"
  if ((bad > 0)); then
    rd_add_result "CTR-002" "Containers" "fail" "high" "Container health" "$bad running container(s) are unhealthy or restarting." "$names" "Inspect with: docker logs --tail 100 <container>" ""
  else
    rd_add_result "CTR-002" "Containers" "pass" "info" "Container health" "No unhealthy or restarting containers were detected." "" "" ""
  fi

  if rd_is_root && [[ -d /var/lib/docker/containers ]]; then
    evidence="$(find /var/lib/docker/containers -type f -name '*-json.log' -size +100M -printf '%s %p\n' 2>/dev/null | sort -nr | head -n5 || true)"
    [[ -z "$evidence" ]] || large="$(grep -c . <<<"$evidence")"
    if ((large > 0)); then
      rd_add_result "CTR-003" "Containers" "warn" "high" "Docker JSON logs" "$large Docker log file(s) exceed 100 MiB." "$evidence" "Configure Docker log rotation; do not delete active log files blindly." "configure-docker-logs"
    else
      rd_add_result "CTR-003" "Containers" "pass" "info" "Docker JSON logs" "No Docker JSON log file exceeds 100 MiB." "" "" ""
    fi
  else
    rd_add_result "CTR-003" "Containers" "skip" "info" "Docker JSON logs" "Root access is required to inspect Docker log file sizes." "" "Run the scan with sudo for this read-only check." ""
  fi
}
