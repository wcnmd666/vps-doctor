#!/usr/bin/env bash

# Parsed repair flags are consumed by helpers in sourced modules.
# shellcheck disable=SC2034

rd_list_fixes() {
  cat <<'EOF'
Guarded repair actions (all require root; none run during scan):

  vacuum-journal          Keep 14 days of systemd journals
  clean-apt-cache         Remove downloaded APT package archives
  create-swap             Create a swap file (default: 2G)
  enable-timesync         Enable systemd-timesyncd
  configure-docker-logs   Add bounded Docker JSON log defaults

Preview any action first:
  sudo vps-doctor fix <action> --dry-run
EOF
}

rd_fix_command() {
  if [[ "${RD_DRY_RUN:-0}" == "1" ]]; then printf 'DRY RUN: '; printf '%q ' "$@"; printf '\n'; return 0; fi
  "$@"
}

rd_run_fix() {
  local action="${1:-}"; shift || true
  RD_ASSUME_YES=0; RD_DRY_RUN=0; RD_SWAP_SIZE="2G"
  while (($#)); do
    case "$1" in
      --yes) RD_ASSUME_YES=1; shift ;;
      --dry-run) RD_DRY_RUN=1; shift ;;
      --size) RD_SWAP_SIZE="${2:-}"; shift 2 ;;
      -h|--help) rd_list_fixes; return 0 ;;
      *) rd_die "Unknown fix option: $1" ;;
    esac
  done
  [[ -n "$action" ]] || { rd_list_fixes; return 1; }
  [[ "$RD_DRY_RUN" == "1" ]] || rd_is_root || rd_die "Repair actions require root (try sudo)"

  case "$action" in
    vacuum-journal) rd_fix_vacuum_journal ;;
    clean-apt-cache) rd_fix_clean_apt_cache ;;
    create-swap) rd_fix_create_swap ;;
    enable-timesync) rd_fix_enable_timesync ;;
    configure-docker-logs) rd_fix_configure_docker_logs ;;
    *) rd_die "Unknown repair action: $action (try: vps-doctor fixes)" ;;
  esac
}

rd_fix_vacuum_journal() {
  rd_command_exists journalctl || rd_die "journalctl is not available"
  printf 'Action: remove systemd journal entries older than 14 days.\n'
  rd_confirm "Continue?" || { rd_warn "Cancelled"; return 1; }
  rd_fix_command journalctl --vacuum-time=14d
  rd_info "Journal vacuum completed."
}

rd_fix_clean_apt_cache() {
  rd_command_exists apt-get || rd_die "apt-get is not available"
  printf 'Action: remove downloaded package archives from the APT cache.\n'
  rd_confirm "Continue?" || { rd_warn "Cancelled"; return 1; }
  rd_fix_command apt-get clean
  rd_info "APT cache cleanup completed."
}

rd_fix_create_swap() {
  local size="$RD_SWAP_SIZE" size_gib available_kib backup=""
  [[ "$size" =~ ^([1-8])G$ ]] || rd_die "Swap size must be 1G through 8G"
  for command_name in swapon mkswap df chmod; do rd_command_exists "$command_name" || rd_die "$command_name is required"; done
  size_gib="${BASH_REMATCH[1]}"
  [[ ! -e /swapfile ]] || rd_die "/swapfile already exists; no change made"
  if swapon --show=NAME 2>/dev/null | grep -q .; then rd_die "Swap is already active; no change made"; fi
  available_kib="$(df -Pk / | awk 'NR==2 {print $4}')"
  ((available_kib > size_gib * 1048576 + 524288)) || rd_die "Not enough free disk space for ${size} swap plus safety margin"
  printf 'Action: create %s /swapfile, activate it, and add it to /etc/fstab.\n' "$size"
  rd_confirm "Continue?" || { rd_warn "Cancelled"; return 1; }
  if [[ "$RD_DRY_RUN" == "1" ]]; then
    rd_fix_command fallocate -l "$size" /swapfile
    rd_fix_command chmod 600 /swapfile
    rd_fix_command mkswap /swapfile
    rd_fix_command swapon /swapfile
    printf 'DRY RUN: append "/swapfile none swap sw 0 0" to /etc/fstab\n'
    return 0
  fi
  backup="$(rd_backup_file /etc/fstab)"
  if ! fallocate -l "$size" /swapfile 2>/dev/null; then dd if=/dev/zero of=/swapfile bs=1M count=$((size_gib * 1024)) status=progress; fi
  chmod 600 /swapfile
  if ! mkswap /swapfile >/dev/null || ! swapon /swapfile; then rm -f /swapfile; rd_die "Could not activate swap; created file was removed"; fi
  if ! grep -qE '^/swapfile[[:space:]]' /etc/fstab; then printf '/swapfile none swap sw 0 0\n' >>/etc/fstab; fi
  rd_info "Swap enabled. fstab backup: ${backup:-not required}"
}

rd_fix_enable_timesync() {
  rd_command_exists systemctl || rd_die "systemctl is not available"
  systemctl cat systemd-timesyncd.service >/dev/null 2>&1 || rd_die "systemd-timesyncd is not installed"
  printf 'Action: enable and start systemd-timesyncd.\n'
  rd_confirm "Continue?" || { rd_warn "Cancelled"; return 1; }
  rd_fix_command systemctl enable --now systemd-timesyncd.service
  rd_info "Time synchronization service enabled."
}

rd_fix_configure_docker_logs() {
  local file="/etc/docker/daemon.json" backup=""
  rd_command_exists docker || rd_die "Docker is not installed"
  if [[ -s "$file" ]]; then
    rd_die "$file already contains settings. VPS Doctor refuses to merge JSON automatically; see docs/repairs.md"
  fi
  printf 'Action: create Docker defaults with 10 MiB × 3 JSON log rotation.\n'
  printf 'Docker is NOT restarted automatically to avoid workload interruption.\n'
  rd_confirm "Continue?" || { rd_warn "Cancelled"; return 1; }
  if [[ "$RD_DRY_RUN" == "1" ]]; then
    printf 'DRY RUN: write bounded json-file logging configuration to %s\n' "$file"
    return 0
  fi
  mkdir -p /etc/docker
  backup="$(rd_backup_file "$file")"
  printf '%s\n' '{' '  "log-driver": "json-file",' '  "log-opts": {' '    "max-size": "10m",' '    "max-file": "3"' '  }' '}' >"$file"
  docker info >/dev/null 2>&1 || rd_warn "Docker daemon is not currently reachable"
  rd_info "Configuration written. Backup: ${backup:-not required}"
  rd_warn "Review $file, then restart Docker during a maintenance window. Existing containers may need recreation."
}
