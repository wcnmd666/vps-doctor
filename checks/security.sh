#!/usr/bin/env bash

rd_sshd_value() {
  local key="$1" value="" etc_root="${RD_ETC_ROOT:-/etc}"
  if rd_command_exists sshd; then value="$(sshd -T 2>/dev/null | awk -v k="$key" '$1==k {print $2; exit}' || true)"; fi
  if [[ -z "$value" ]]; then
    value="$(grep -Ehi "^[[:space:]]*${key}[[:space:]]+" "$etc_root/ssh/sshd_config" "$etc_root"/ssh/sshd_config.d/*.conf 2>/dev/null | tail -n1 | awk '{print tolower($2)}' || true)"
  fi
  printf '%s' "$value"
}

check_security() {
  local firewall="" root_login password_auth failures=0 updates=""
  if rd_command_exists ufw && ufw status 2>/dev/null | grep -qi 'Status: active'; then firewall="ufw active"
  elif rd_command_exists firewall-cmd && firewall-cmd --state 2>/dev/null | grep -qi running; then firewall="firewalld running"
  elif rd_command_exists nft && nft list ruleset 2>/dev/null | grep -qE 'hook input|type filter'; then firewall="nftables rules detected"
  fi
  if [[ -n "$firewall" ]]; then
    rd_add_result "SEC-001" "Security" "pass" "info" "Host firewall" "A host firewall appears active." "$firewall" "" ""
  else
    rd_add_result "SEC-001" "Security" "warn" "high" "Host firewall" "No active UFW, firewalld, or nftables input policy was detected." "" "Confirm whether a cloud firewall protects the host before enabling local rules." ""
  fi

  root_login="$(rd_sshd_value permitrootlogin)"
  case "$root_login" in
    no) rd_add_result "SEC-002" "Security" "pass" "info" "SSH root login" "Direct SSH root login is disabled." "permitrootlogin=no" "" "" ;;
    prohibit-password|without-password) rd_add_result "SEC-002" "Security" "warn" "low" "SSH root login" "Root login is allowed with keys." "permitrootlogin=$root_login" "Prefer a named sudo user and disable direct root login after verifying access." "" ;;
    *) rd_add_result "SEC-002" "Security" "warn" "high" "SSH root login" "The effective root login policy is '${root_login:-unknown}'." "permitrootlogin=${root_login:-unknown}" "Verify a sudo account and key login before changing SSH policy." "" ;;
  esac

  password_auth="$(rd_sshd_value passwordauthentication)"
  if [[ "$password_auth" == "no" ]]; then
    rd_add_result "SEC-003" "Security" "pass" "info" "SSH password authentication" "SSH password authentication is disabled." "auth_policy=no" "" ""
  else
    rd_add_result "SEC-003" "Security" "warn" "high" "SSH password authentication" "SSH password authentication is '${password_auth:-unknown}'." "auth_policy=${password_auth:-unknown}" "Test key login in a second session before disabling passwords." ""
  fi

  if [[ "$RD_QUICK" == "1" ]] || ! rd_command_exists journalctl; then
    rd_add_result "SEC-004" "Security" "skip" "info" "SSH authentication failures" "Skipped in quick mode or journalctl unavailable." "" "" ""
  else
    failures="$(journalctl --since '24 hours ago' -u ssh -u sshd --no-pager 2>/dev/null | grep -Eci 'failed password|invalid user|authentication failure' || true)"
    if ((failures >= RD_AUTH_FAILURE_WARN)); then
      rd_add_result "SEC-004" "Security" "warn" "medium" "SSH authentication failures" "$failures failed SSH authentication entries were found in the last 24 hours." "failure_entries=$failures" "Use key authentication and consider rate limiting such as Fail2Ban." ""
    else
      rd_add_result "SEC-004" "Security" "pass" "info" "SSH authentication failures" "$failures failed SSH authentication entries were found in the last 24 hours." "failure_entries=$failures" "" ""
    fi
  fi

  if rd_command_exists systemctl; then updates="$(systemctl is-enabled unattended-upgrades.service 2>/dev/null || true)"; fi
  if [[ "$updates" == "enabled" || "$updates" == "static" ]]; then
    rd_add_result "SEC-005" "Security" "pass" "info" "Automatic security updates" "The unattended-upgrades service is available and enabled." "state=$updates" "" ""
  else
    rd_add_result "SEC-005" "Security" "warn" "medium" "Automatic security updates" "Automatic security updates do not appear enabled." "state=${updates:-unknown}" "Review and enable unattended-upgrades for supported Debian/Ubuntu systems." ""
  fi
}
