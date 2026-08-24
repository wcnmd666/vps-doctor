#!/usr/bin/env bash

check_web() {
  local detected=() service state domain remaining failures=0 checked=0 evidence=""
  for service in nginx apache2 caddy; do
    if rd_command_exists "$service" || [[ -e "/lib/systemd/system/$service.service" || -e "/usr/lib/systemd/system/$service.service" ]]; then
      detected+=("$service")
      state="$(systemctl is-active "$service" 2>/dev/null || true)"
      [[ "$state" == "active" ]] || ((failures+=1))
    fi
  done
  if ((${#detected[@]} == 0)); then
    rd_add_result "WEB-001" "Web" "skip" "info" "Web server state" "No Nginx, Apache, or Caddy installation was detected." "" "" ""
  elif ((failures > 0)); then
    rd_add_result "WEB-001" "Web" "fail" "high" "Web server state" "$failures detected web server service(s) are not active." "servers=${detected[*]}" "Inspect the service status and configuration test before restarting." ""
  else
    rd_add_result "WEB-001" "Web" "pass" "info" "Web server state" "Detected web server service(s) are active." "servers=${detected[*]}" "" ""
  fi

  if [[ "$RD_QUICK" == "1" || -z "$RD_DOMAINS" ]]; then
    rd_add_result "WEB-002" "Web" "skip" "info" "Domain and TLS checks" "No domains configured or quick mode enabled." "" "Set DOMAINS in config/vps-doctor.conf to enable checks." ""
    return
  fi
  if ! rd_command_exists openssl || ! rd_command_exists timeout; then
    rd_add_result "WEB-002" "Web" "skip" "info" "Domain and TLS checks" "openssl and timeout are required for TLS checks." "" "Install openssl and coreutils." ""
    return
  fi

  IFS=',' read -r -a domains <<<"$RD_DOMAINS"
  for domain in "${domains[@]}"; do
    domain="$(rd_trim "$domain")"; [[ -n "$domain" ]] || continue; ((checked+=1))
    if ! getent ahosts "$domain" >/dev/null 2>&1; then ((failures+=1)); evidence+="$domain: DNS failed; "; continue; fi
    if timeout 8 openssl s_client -servername "$domain" -connect "$domain:443" </dev/null 2>/dev/null | openssl x509 -checkend 1209600 -noout >/dev/null 2>&1; then
      remaining="ok>14d"
    else
      remaining="unreachable-or-expiring"; ((failures+=1))
    fi
    evidence+="$domain: $remaining; "
  done
  if ((checked == 0)); then
    rd_add_result "WEB-002" "Web" "skip" "info" "Domain and TLS checks" "The configured domain list is empty." "" "" ""
  elif ((failures > 0)); then
    rd_add_result "WEB-002" "Web" "warn" "high" "Domain and TLS checks" "$failures of $checked configured domain check(s) failed or expire within 14 days." "$evidence" "Verify DNS, port 443, and certificate renewal." ""
  else
    rd_add_result "WEB-002" "Web" "pass" "info" "Domain and TLS checks" "All $checked configured domains resolve and have certificates valid beyond 14 days." "$evidence" "" ""
  fi
}
