#!/usr/bin/env bash

check_network() {
  local route="" dns_ok=0 ports="" port_count=0
  if ! rd_command_exists ip; then
    rd_add_result "NET-001" "Network" "skip" "info" "Default route" "The ip utility is not available." "" "Install iproute2 to inspect routing." ""
  else
    route="$(ip route show default 2>/dev/null | head -n1 || true)"
  fi
  if [[ -n "$route" ]]; then
    rd_add_result "NET-001" "Network" "pass" "info" "Default route" "A default network route is configured." "$route" "" ""
  elif rd_command_exists ip; then
    rd_add_result "NET-001" "Network" "fail" "critical" "Default route" "No default network route was detected." "" "Check the provider network configuration before changing local routes." ""
  fi

  if [[ "$RD_QUICK" == "1" ]]; then
    rd_add_result "NET-002" "Network" "skip" "info" "DNS resolution" "Skipped in quick mode." "" "" ""
  else
    if rd_command_exists getent && getent ahosts github.com >/dev/null 2>&1; then dns_ok=1; fi
    if ((dns_ok)); then
      rd_add_result "NET-002" "Network" "pass" "info" "DNS resolution" "Public DNS resolution succeeded." "github.com resolved" "" ""
    else
      rd_add_result "NET-002" "Network" "warn" "high" "DNS resolution" "The server could not resolve a public test hostname." "github.com unresolved" "Check /etc/resolv.conf and provider DNS settings." ""
    fi
  fi

  if rd_command_exists ss; then
    ports="$(ss -lntH 2>/dev/null | awk '{print $4}' | sed -E 's/.*:([0-9]+)$/\1/' | sort -nu | paste -sd, - || true)"
    [[ -z "$ports" ]] || port_count="$(awk -F, '{print NF}' <<<"$ports")"
    rd_add_result "NET-003" "Network" "info" "info" "Listening TCP ports" "$port_count unique TCP port(s) are listening." "ports=$ports" "Confirm that every public port is intentional and protected." ""
  else
    rd_add_result "NET-003" "Network" "skip" "info" "Listening TCP ports" "The ss utility is not available." "" "Install iproute2 to inspect listening sockets." ""
  fi
}
