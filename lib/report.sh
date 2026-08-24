#!/usr/bin/env bash

rd_json_escape() {
  local s="$1"
  s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\n'/\\n}; s=${s//$'\r'/\\r}; s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

rd_report_terminal() {
  local i last_category="" category score_color
  if ((RD_SCORE >= 75)); then score_color=32; elif ((RD_SCORE >= 50)); then score_color=33; else score_color=31; fi
  printf '\n%s\n' "$(rd_c '1;36' '╭────────────────────────────────────────────────────────────╮')"
  printf '%s\n' "$(rd_c '1;36' '│  VPS Doctor — Read-only server health assessment           │')"
  printf '%s\n\n' "$(rd_c '1;36' '╰────────────────────────────────────────────────────────────╯')"
  printf 'Host: %s   Started: %s\n' "$(rd_redact "$RD_HOSTNAME")" "$RD_STARTED_AT"
  printf 'Health score: %s/100  Grade: %s\n' "$(rd_c "$score_color" "$RD_SCORE")" "$(rd_score_grade)"
  printf 'Summary: %s pass · %s warning · %s failure · %s info\n' "$RD_PASS_COUNT" "$RD_WARN_COUNT" "$RD_FAIL_COUNT" "$RD_INFO_COUNT"

  for i in "${!RD_IDS[@]}"; do
    category="${RD_CATEGORIES[$i]}"
    if [[ "$category" != "$last_category" ]]; then printf '\n%s\n' "$(rd_c '1' "[$category]")"; last_category="$category"; fi
    printf '  %-4s %-8s %s — %s\n' "$(rd_status_icon "${RD_STATUSES[$i]}")" "${RD_IDS[$i]}" "${RD_TITLES[$i]}" "$(rd_redact "${RD_SUMMARIES[$i]}")"
    [[ -z "${RD_RECOMMENDATIONS[$i]}" ]] || printf '       ↳ %s\n' "${RD_RECOMMENDATIONS[$i]}"
    [[ -z "${RD_FIXES[$i]}" ]] || printf '       Fix: sudo vps-doctor fix %s\n' "${RD_FIXES[$i]}"
  done
  printf "\nNo changes were made. Run \`vps-doctor fixes\` to inspect guarded repair actions.\n"
}

rd_report_json() {
  local target="${1:--}" tmp i comma="" content
  tmp="$(mktemp)"
  {
    printf '{\n  "schema_version": "1.0",\n'
    printf '  "tool": {"name": "vps-doctor", "version": "%s"},\n' "${VERSION:-unknown}"
    printf '  "scan": {"started_at": "%s", "host": "%s", "read_only": true, "quick": %s},\n' \
      "$(rd_json_escape "$RD_STARTED_AT")" "$(rd_json_escape "$(rd_redact "$RD_HOSTNAME")")" "$([[ "$RD_QUICK" == 1 ]] && printf true || printf false)"
    printf '  "summary": {"score": %d, "grade": "%s", "pass": %d, "warn": %d, "fail": %d, "info": %d},\n' \
      "$RD_SCORE" "$(rd_score_grade)" "$RD_PASS_COUNT" "$RD_WARN_COUNT" "$RD_FAIL_COUNT" "$RD_INFO_COUNT"
    printf '  "findings": [\n'
    for i in "${!RD_IDS[@]}"; do
      printf '%s' "$comma"; comma=$',\n'
      printf '    {"id":"%s","category":"%s","status":"%s","severity":"%s","title":"%s","summary":"%s","evidence":"%s","recommendation":"%s","fix":"%s"}' \
        "$(rd_json_escape "${RD_IDS[$i]}")" "$(rd_json_escape "${RD_CATEGORIES[$i]}")" "$(rd_json_escape "${RD_STATUSES[$i]}")" \
        "$(rd_json_escape "${RD_SEVERITIES[$i]}")" "$(rd_json_escape "${RD_TITLES[$i]}")" "$(rd_json_escape "$(rd_redact "${RD_SUMMARIES[$i]}")")" \
        "$(rd_json_escape "$(rd_redact "${RD_EVIDENCE[$i]}")")" "$(rd_json_escape "${RD_RECOMMENDATIONS[$i]}")" "$(rd_json_escape "${RD_FIXES[$i]}")"
    done
    printf '\n  ]\n}\n'
  } >"$tmp"
  if [[ "$target" == "-" ]]; then content="$(<"$tmp")"; printf '%s\n' "$content"; rm -f "$tmp"; else mkdir -p "$(dirname "$target")"; mv "$tmp" "$target"; fi
}

rd_report_markdown() {
  local target="${1:--}" tmp i content
  tmp="$(mktemp)"
  {
    printf '# VPS Doctor report\n\n'
    printf '> Read-only scan. Sensitive host, user, IP and secret-like values are redacted.\n\n'
    printf '| Metric | Value |\n|---|---:|\n'
    printf '| Health score | **%s/100 (%s)** |\n' "$RD_SCORE" "$(rd_score_grade)"
    printf '| Passed | %s |\n| Warnings | %s |\n| Failures | %s |\n| Started | %s |\n\n' "$RD_PASS_COUNT" "$RD_WARN_COUNT" "$RD_FAIL_COUNT" "$RD_STARTED_AT"
    printf '## Findings\n\n'
    for i in "${!RD_IDS[@]}"; do
      printf '### %s · %s · %s\n\n' "${RD_IDS[$i]}" "${RD_STATUSES[$i]^^}" "${RD_TITLES[$i]}"
      printf '%s\n\n' "$(rd_redact "${RD_SUMMARIES[$i]}")"
      [[ -z "${RD_EVIDENCE[$i]}" ]] || printf -- "- Evidence: \`%s\`\n" "$(rd_redact "${RD_EVIDENCE[$i]}")"
      [[ -z "${RD_RECOMMENDATIONS[$i]}" ]] || printf -- '- Recommendation: %s\n' "${RD_RECOMMENDATIONS[$i]}"
      [[ -z "${RD_FIXES[$i]}" ]] || printf -- "- Guarded fix: \`sudo vps-doctor fix %s\`\n" "${RD_FIXES[$i]}"
      printf '\n'
    done
  } >"$tmp"
  if [[ "$target" == "-" ]]; then content="$(<"$tmp")"; printf '%s\n' "$content"; rm -f "$tmp"; else mkdir -p "$(dirname "$target")"; mv "$tmp" "$target"; fi
}
