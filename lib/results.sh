#!/usr/bin/env bash

declare -ag RD_IDS=() RD_CATEGORIES=() RD_STATUSES=() RD_SEVERITIES=()
declare -ag RD_TITLES=() RD_SUMMARIES=() RD_EVIDENCE=() RD_RECOMMENDATIONS=() RD_FIXES=()
declare -Ag RD_EXCLUSIONS=()
RD_SCORE=100
RD_PASS_COUNT=0
RD_WARN_COUNT=0
RD_FAIL_COUNT=0
RD_INFO_COUNT=0

rd_results_reset() {
  RD_IDS=(); RD_CATEGORIES=(); RD_STATUSES=(); RD_SEVERITIES=()
  RD_TITLES=(); RD_SUMMARIES=(); RD_EVIDENCE=(); RD_RECOMMENDATIONS=(); RD_FIXES=()
  RD_SCORE=100; RD_PASS_COUNT=0; RD_WARN_COUNT=0; RD_FAIL_COUNT=0; RD_INFO_COUNT=0
}

rd_known_rule_id() {
  case "$1" in
    SYS-001|SYS-002|SYS-003|STO-001|STO-002|STO-003|MEM-001|MEM-002|MEM-003|SVC-001|SVC-002|NET-001|NET-002|NET-003|SEC-001|SEC-002|SEC-003|SEC-004|SEC-005|CTR-001|CTR-002|CTR-003|WEB-001|WEB-002) return 0 ;;
    *) return 1 ;;
  esac
}

rd_add_result() {
  local id="$1" category="$2" status="$3" severity="$4" title="$5"
  local summary="$6" evidence="${7:-}" recommendation="${8:-}" fix="${9:-}"

  if [[ -n "${RD_EXCLUSIONS[$id]:-}" ]]; then
    status="skip"
    severity="info"
    summary="Excluded by configuration: ${RD_EXCLUSIONS[$id]}"
    evidence=""
    recommendation=""
    fix=""
  fi

  RD_IDS+=("$id"); RD_CATEGORIES+=("$category"); RD_STATUSES+=("$status"); RD_SEVERITIES+=("$severity")
  RD_TITLES+=("$title"); RD_SUMMARIES+=("$summary"); RD_EVIDENCE+=("$evidence")
  RD_RECOMMENDATIONS+=("$recommendation"); RD_FIXES+=("$fix")
}

rd_penalty() {
  case "$1" in critical) printf 20 ;; high) printf 12 ;; medium) printf 7 ;; low) printf 3 ;; *) printf 0 ;; esac
}

rd_finalize_score() {
  local i penalty=0 status severity
  for i in "${!RD_IDS[@]}"; do
    status="${RD_STATUSES[$i]}"; severity="${RD_SEVERITIES[$i]}"
    case "$status" in
      pass) ((RD_PASS_COUNT+=1)) ;;
      warn) ((RD_WARN_COUNT+=1)); ((penalty+=$(rd_penalty "$severity"))) ;;
      fail) ((RD_FAIL_COUNT+=1)); ((penalty+=$(rd_penalty "$severity"))) ;;
      *) ((RD_INFO_COUNT+=1)) ;;
    esac
  done
  RD_SCORE=$((100 - penalty))
  ((RD_SCORE < 0)) && RD_SCORE=0
}

rd_status_icon() {
  case "$1" in pass) rd_c '32' 'PASS' ;; warn) rd_c '33' 'WARN' ;; fail) rd_c '31' 'FAIL' ;; skip) rd_c '90' 'SKIP' ;; *) rd_c '36' 'INFO' ;; esac
}

rd_score_grade() {
  if ((RD_SCORE >= 90)); then printf A; elif ((RD_SCORE >= 75)); then printf B; elif ((RD_SCORE >= 60)); then printf C; elif ((RD_SCORE >= 40)); then printf D; else printf F; fi
}

rd_list_rules() {
  cat <<'EOF'
SYS-001  Supported operating system
SYS-002  CPU load pressure
SYS-003  Time synchronization
STO-001  Root filesystem usage
STO-002  Root filesystem inode usage
STO-003  System journal size
MEM-001  Available memory
MEM-002  Swap availability
MEM-003  Recent out-of-memory events
SVC-001  Failed systemd services
SVC-002  Reboot required
NET-001  Default route
NET-002  DNS resolution
NET-003  Public listening ports
SEC-001  Firewall state
SEC-002  SSH root login policy
SEC-003  SSH password authentication
SEC-004  Recent SSH authentication failures
SEC-005  Automatic security updates
CTR-001  Docker daemon state
CTR-002  Unhealthy or restarting containers
CTR-003  Oversized Docker JSON logs
WEB-001  Web server state
WEB-002  Configured domain DNS and TLS expiry
EOF
}
