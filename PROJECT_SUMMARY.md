# VPS Doctor — project summary

## One-line pitch

VPS Doctor turns common Linux server failure signals into one explainable health score, actionable evidence, and guarded repairs—without installing an agent or changing the host during a scan.

## Problem

Small open-source projects and self-hosted services are often maintained on inexpensive VPS instances by people who are not full-time system administrators. When disk, memory, networking, SSH, Docker, or reverse-proxy failures occur, maintainers spend time collecting inconsistent command output before they can even begin diagnosis.

## Current solution

- 24 stable diagnostic rules in eight operational categories
- Read-only scanning with graceful handling of missing tools and permissions
- Severity-weighted, explainable 0–100 health score
- Terminal, JSON, and Markdown output with best-effort privacy redaction
- Five separately invoked repairs with validation, dry-run, confirmation, and conservative refusal behavior
- Optional domain DNS and TLS expiry checks
- Bash 4.4+ support focused on Ubuntu and Debian
- Automated syntax, unit, lint, smoke, and release workflows

## Differentiation

VPS Doctor is not another monitoring dashboard or vulnerability scanner. It is a short-lived incident evidence collector for the first 10 minutes of troubleshooting. Its design priorities are:

1. explanation before action;
2. no daemon, account, database, or telemetry;
3. useful partial results on minimal hosts;
4. reports that maintainers can safely review and share;
5. refusal to automate changes that could lock out SSH or interrupt workloads.

## Sustainable scope

The project is intentionally modular. Community contributors can add one rule with fixtures and documentation without understanding every other category. Stable rule IDs and a versioned JSON schema create room for integrations without turning the CLI into a hosted platform.

## Evidence to collect after launch

- unique tagged-release downloads;
- package or installer executions when measurable without telemetry;
- external repositories linking to VPS Doctor reports;
- confirmed incidents where a rule shortened diagnosis;
- outside contributors, issues, fixes, and distribution validation;
- release cadence and response time to reports.

Do not manufacture adoption metrics. The project's public value should be demonstrated with reproducible cases and independent users.
