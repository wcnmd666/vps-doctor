#!/usr/bin/env bash

# Shared state is consumed by modules sourced by the entrypoint.
# shellcheck disable=SC2034

RD_COLOR="${RD_COLOR:-1}"
RD_QUICK="${RD_QUICK:-0}"
RD_STARTED_AT=""
RD_HOSTNAME=""
RD_CONFIG_FILE=""
RD_DOMAINS=""
RD_DISK_WARN="85"
RD_DISK_FAIL="95"
RD_MEMORY_WARN="15"
RD_AUTH_FAILURE_WARN="100"

if [[ ! -t 1 || "${NO_COLOR:-}" != "" ]]; then RD_COLOR=0; fi

rd_c() {
  local code="$1"; shift
  if [[ "$RD_COLOR" == "1" ]]; then printf '\033[%sm%s\033[0m' "$code" "$*"; else printf '%s' "$*"; fi
}

rd_info() { printf '%s %s\n' "$(rd_c '36' 'ℹ')" "$*" >&2; }
rd_warn() { printf '%s %s\n' "$(rd_c '33' '⚠')" "$*" >&2; }
rd_die() { printf '%s %s\n' "$(rd_c '31' '✖')" "$*" >&2; exit 1; }
rd_command_exists() { command -v "$1" >/dev/null 2>&1; }
rd_is_root() { [[ "${EUID:-$(id -u)}" -eq 0 ]]; }
rd_timestamp() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

rd_trim() {
  local value="$*"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

rd_config_value() {
  local file="$1" key="$2" line
  line="$(grep -E "^[[:space:]]*${key}[[:space:]]*=" "$file" 2>/dev/null | tail -n1 || true)"
  [[ -n "$line" ]] || return 1
  line="${line#*=}"
  line="${line%%#*}"
  line="$(rd_trim "$line")"
  line="${line%\"}"; line="${line#\"}"
  printf '%s' "$line"
}

rd_load_config() {
  local requested="${1:-}" candidate value
  for candidate in "$requested" "${VPS_DOCTOR_CONFIG:-}" "/etc/vps-doctor/config.conf" "$ROOT_DIR/config/vps-doctor.conf"; do
    [[ -n "$candidate" && -r "$candidate" ]] || continue
    RD_CONFIG_FILE="$candidate"
    value="$(rd_config_value "$candidate" DOMAINS || true)"; [[ -z "$value" ]] || RD_DOMAINS="$value"
    value="$(rd_config_value "$candidate" DISK_WARN || true)"; [[ "$value" =~ ^[0-9]+$ ]] && RD_DISK_WARN="$value"
    value="$(rd_config_value "$candidate" DISK_FAIL || true)"; [[ "$value" =~ ^[0-9]+$ ]] && RD_DISK_FAIL="$value"
    value="$(rd_config_value "$candidate" MEMORY_WARN || true)"; [[ "$value" =~ ^[0-9]+$ ]] && RD_MEMORY_WARN="$value"
    value="$(rd_config_value "$candidate" AUTH_FAILURE_WARN || true)"; [[ "$value" =~ ^[0-9]+$ ]] && RD_AUTH_FAILURE_WARN="$value"
    return 0
  done
}

rd_human_kib() {
  local kib="${1:-0}"
  awk -v kib="$kib" 'BEGIN {
    if (kib >= 1048576) printf "%.1f GiB", kib/1048576;
    else if (kib >= 1024) printf "%.1f MiB", kib/1024;
    else printf "%d KiB", kib;
  }'
}

rd_redact() {
  local text="$*" user host
  user="$(id -un 2>/dev/null || true)"; host="$(hostname 2>/dev/null || true)"
  [[ -z "$user" ]] || text="${text//$user/[user]}"
  [[ -z "$host" ]] || text="${text//$host/[host]}"
  printf '%s' "$text" | sed -E \
    -e 's/([0-9]{1,3}\.){3}[0-9]{1,3}/[ip]/g' \
    -e 's/([A-Za-z0-9_]*(TOKEN|KEY|SECRET|PASSWORD)[A-Za-z0-9_]*)=([^[:space:]]+)/\1=[redacted]/Ig' \
    | LC_ALL=C tr -d '\000-\010\013\014\016-\037'
}

rd_confirm() {
  local prompt="$1" answer
  if [[ "${RD_DRY_RUN:-0}" == "1" ]]; then return 0; fi
  if [[ "${RD_ASSUME_YES:-0}" == "1" ]]; then return 0; fi
  [[ -t 0 ]] || rd_die "Interactive confirmation required; pass --yes after reviewing the action"
  read -r -p "$prompt [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

rd_backup_file() {
  local file="$1" backup_dir="/var/backups/vps-doctor" stamp
  [[ -e "$file" ]] || return 0
  stamp="$(date '+%Y%m%d-%H%M%S')"
  mkdir -p "$backup_dir"
  cp -a -- "$file" "$backup_dir/$(basename "$file").$stamp"
  printf '%s' "$backup_dir/$(basename "$file").$stamp"
}
