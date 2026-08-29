<div align="center">
  <img src="docs/assets/logo.svg" width="110" alt="VPS Doctor logo">
  <h1>VPS Doctor</h1>
  <p><strong>Diagnose common Linux server failures in one command — then fix them safely.</strong></p>
  <p>
    <a href="README.zh-CN.md">简体中文</a> ·
    <a href="docs/rules.md">Diagnostic rules</a> ·
    <a href="docs/repairs.md">Repair safety</a> ·
    <a href="docs/release-verification.md">Release verification</a> ·
    <a href="ROADMAP.md">Roadmap</a>
  </p>
  <p>
    <img alt="CI" src="https://img.shields.io/github/actions/workflow/status/wcnmd666/vps-doctor/ci.yml?branch=main&label=tests">
    <img alt="License" src="https://img.shields.io/badge/license-MIT-22c55e">
    <img alt="Bash" src="https://img.shields.io/badge/bash-4.4%2B-0f172a">
    <img alt="platform" src="https://img.shields.io/badge/platform-Ubuntu%20%7C%20Debian-7c3aed">
  </p>
</div>

![VPS Doctor terminal demo](docs/assets/terminal-demo.svg)

VPS Doctor is a read-only-first diagnostic CLI for small VPS, homelab, and self-hosted Linux servers. It turns scattered system signals into an explainable health score, actionable findings, and privacy-redacted reports that can be attached to support requests or GitHub issues.

## Why

When a server becomes slow or a site stops responding, beginners are often asked to run a dozen unrelated commands. VPS Doctor checks the common failure chain in one pass:

`disk → memory → services → network → SSH → firewall → Docker → web/TLS`

It does not install an agent, open a port, upload telemetry, or change the host during a scan.

## Quick start

From a cloned repository:

```bash
sudo bash ./install.sh
sudo vps-doctor scan
```

For disposable testing, the installer can also be fetched directly:

```bash
curl -fsSL https://raw.githubusercontent.com/wcnmd666/vps-doctor/main/install.sh | sudo bash
```

For production use, download a tagged release, verify its checksum, inspect the installer, and install from the verified local checkout. See [release verification](docs/release-verification.md). Piping mutable remote content directly to root is convenient for demos but is not the recommended trust path.

## What it checks

- CPU load, memory pressure, swap, disk space, and inode exhaustion
- Recent kernel out-of-memory events and failed systemd units
- Default route, public DNS resolution, and listening TCP ports
- Host firewall, SSH policy, login failures, and unattended security updates
- Docker daemon, unhealthy/restarting containers, and oversized JSON logs
- Nginx, Apache, or Caddy state plus optional DNS/TLS checks for configured domains

Every result has a stable rule ID, severity, evidence, recommendation, and optional guarded repair action. See the complete [rule catalog](docs/rules.md).

## Reports and CI

```bash
# Human-friendly terminal view
sudo vps-doctor scan

# Redacted machine-readable evidence
sudo vps-doctor scan --format json --output report.json

# Shareable Markdown support report
sudo vps-doctor scan --format markdown --output report.md

# Standalone offline HTML incident report
sudo vps-doctor scan --format html --output report.html

# Monitoring/automation gate
sudo vps-doctor scan --quick --fail-under 75
```

HTML reports are self-contained and load no third-party scripts, fonts, trackers, or other remote assets. System-derived text is escaped before it is embedded in the page.

Exit code `0` means the scan completed and met the optional threshold, `1` means usage/runtime failure, and `2` means the score was below `--fail-under`.

## Guarded repairs

Scans are always read-only. Repairs are separate, require root, explain their effect, and require confirmation:

```bash
sudo vps-doctor fixes
sudo vps-doctor fix vacuum-journal --dry-run
sudo vps-doctor fix vacuum-journal
```

VPS Doctor intentionally refuses risky guesses. For example, it will not auto-merge an existing Docker daemon configuration, enable a firewall that could lock out SSH, or rewrite SSH policy without a verified second session. Read the [repair safety model](docs/repairs.md).

## Privacy

There is no telemetry. Terminal, JSON, Markdown, and HTML reports redact the current username, hostname, IPv4-like values, and common secret assignments. Redaction is defense in depth, not a guarantee; always review a report before publishing it. Details are in [docs/privacy.md](docs/privacy.md).

## Supported systems

| System | Status |
|---|---|
| Ubuntu 20.04, 22.04, 24.04 | Tested target |
| Debian 11, 12, 13 | Tested target |
| Other systemd Linux | Best effort, warns as unvalidated |
| Containers without systemd | Partial scan |

Requires Bash 4.4 or newer. Individual checks degrade gracefully when optional commands are missing.

## Project status

`v0.1.0` is an initial public preview. Reports and findings are diagnostic evidence, not a security certification. Please test fixes on disposable infrastructure and report false positives with a redacted JSON report.

## Contributing and security

Small, evidence-backed diagnostic rules are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Please report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

MIT licensed. Built for operators who want an explanation before a command changes their server.
