#!/usr/bin/env bash

rd_json_escape() {
  local s="$1"
  s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\n'/\\n}; s=${s//$'\r'/\\r}; s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

rd_html_escape() {
  printf '%s' "$1" | sed \
    -e 's/&/\&amp;/g' \
    -e 's/</\&lt;/g' \
    -e 's/>/\&gt;/g' \
    -e 's/"/\&quot;/g' \
    -e "s/'/\&#39;/g"
}

rd_save_report() {
  local tmp="$1" target="$2"
  mkdir -p "$(dirname "$target")"
  mv "$tmp" "$target"

  # mktemp creates mode 0600 files. When the scan is run through sudo,
  # return ownership to the invoking user so the report can be validated,
  # uploaded, or shared without weakening its private permissions.
  if [[ -n "${SUDO_UID:-}" && -n "${SUDO_GID:-}" ]]; then
    chown "${SUDO_UID}:${SUDO_GID}" "$target" 2>/dev/null || true
  fi
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
  if [[ "$target" == "-" ]]; then content="$(<"$tmp")"; printf '%s\n' "$content"; rm -f "$tmp"; else rd_save_report "$tmp" "$target"; fi
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
  if [[ "$target" == "-" ]]; then content="$(<"$tmp")"; printf '%s\n' "$content"; rm -f "$tmp"; else rd_save_report "$tmp" "$target"; fi
}

rd_report_html() {
  local target="${1:--}" tmp i content status category title summary evidence recommendation fix host
  tmp="$(mktemp)"
  host="$(rd_html_escape "$(rd_redact "$RD_HOSTNAME")")"
  {
    cat <<'EOF'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>VPS Doctor report</title>
<style>
:root{font-family:ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;line-height:1.5}body{max-width:980px;margin:0 auto;padding:32px 20px;background:#f7f8fa;color:#172033}.card,details{background:#fff;border:1px solid #dfe3e8;border-radius:12px;box-shadow:0 1px 2px rgba(0,0,0,.04)}header{margin-bottom:24px}.meta{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin:20px 0}.metric{padding:14px}.metric strong{display:block;font-size:1.35rem}.notice{padding:14px 16px;border-left:4px solid #64748b;margin:20px 0}.findings{display:grid;gap:12px}details{padding:0 16px}summary{cursor:pointer;padding:14px 0;font-weight:700}.badge{display:inline-block;border-radius:999px;padding:2px 8px;margin-right:8px;font-size:.78rem;border:1px solid currentColor}.pass{color:#16794b}.warn{color:#9a6700}.fail{color:#b42318}.skip,.info{color:#52606d}.body{padding:0 0 16px}.label{font-weight:700}code{white-space:pre-wrap;word-break:break-word}footer{margin-top:24px;color:#667085;font-size:.9rem}@media(prefers-color-scheme:dark){body{background:#0f1720;color:#e7edf3}.card,details{background:#151f2b;border-color:#2a3948}.notice{border-color:#94a3b8}footer{color:#a7b1bc}}
</style>
</head>
<body>
<header>
<h1>VPS Doctor report</h1>
<p>Read-only server health assessment</p>
</header>
EOF
    printf '<div class="notice card">Sensitive host, user, IP and secret-like values are redacted. Review this report before sharing it.</div>\n'
    printf '<section class="meta">\n'
    printf '<div class="metric card"><span>Health score</span><strong>%s/100 (%s)</strong></div>\n' "$RD_SCORE" "$(rd_score_grade)"
    printf '<div class="metric card"><span>Passed</span><strong>%s</strong></div>\n' "$RD_PASS_COUNT"
    printf '<div class="metric card"><span>Warnings</span><strong>%s</strong></div>\n' "$RD_WARN_COUNT"
    printf '<div class="metric card"><span>Failures</span><strong>%s</strong></div>\n' "$RD_FAIL_COUNT"
    printf '</section>\n'
    printf '<p><span class="label">Host:</span> %s<br><span class="label">Started:</span> %s</p>\n' "$host" "$(rd_html_escape "$RD_STARTED_AT")"
    printf '<h2>Findings</h2><section class="findings">\n'
    for i in "${!RD_IDS[@]}"; do
      status="${RD_STATUSES[$i]}"
      category="$(rd_html_escape "${RD_CATEGORIES[$i]}")"
      title="$(rd_html_escape "${RD_TITLES[$i]}")"
      summary="$(rd_html_escape "$(rd_redact "${RD_SUMMARIES[$i]}")")"
      evidence="$(rd_html_escape "$(rd_redact "${RD_EVIDENCE[$i]}")")"
      recommendation="$(rd_html_escape "${RD_RECOMMENDATIONS[$i]}")"
      fix="$(rd_html_escape "${RD_FIXES[$i]}")"
      printf '<details><summary><span class="badge %s">%s</span>%s · %s · %s</summary><div class="body">\n' \
        "$status" "$(rd_html_escape "${status^^}")" "$(rd_html_escape "${RD_IDS[$i]}")" "$category" "$title"
      printf '<p>%s</p>\n' "$summary"
      [[ -z "$evidence" ]] || printf '<p><span class="label">Evidence:</span> <code>%s</code></p>\n' "$evidence"
      [[ -z "$recommendation" ]] || printf '<p><span class="label">Recommendation:</span> %s</p>\n' "$recommendation"
      [[ -z "$fix" ]] || printf '<p><span class="label">Guarded fix:</span> <code>sudo vps-doctor fix %s</code></p>\n' "$fix"
      printf '</div></details>\n'
    done
    printf '</section>\n<footer>No telemetry or remote assets are used by this report. Generated by VPS Doctor %s.</footer>\n' "$(rd_html_escape "${VERSION:-unknown}")"
    printf '</body></html>\n'
  } >"$tmp"
  if [[ "$target" == "-" ]]; then content="$(<"$tmp")"; printf '%s\n' "$content"; rm -f "$tmp"; else rd_save_report "$tmp" "$target"; fi
}
