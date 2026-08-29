# Roadmap

The roadmap favors reliable evidence over feature count. Items graduate only after tests and documented safety boundaries exist.

## v0.1 — Diagnostic core

- [x] Read-only scan and explainable score
- [x] System, storage, memory, services, network, security, Docker, and web rules
- [x] JSON and Markdown evidence reports
- [x] Guarded repair framework and dry-run mode
- [x] CI, contributor guide, security policy, and bilingual README

## v0.2 — Reproducible incident evidence

- [x] Single-file offline HTML report with collapsible evidence
- [x] Configurable rule thresholds and rule exclusions with reasons
- [x] Fixture-driven Ubuntu/Debian integration scenarios across core rule categories
- [x] Verifiable release artifacts with SHA-256 guidance and GitHub build provenance
- [x] CI/release hardening with bounded jobs, concurrency controls, and immutable Action pins
- [x] Expanded report redaction and HTML containment

## v0.3 — Maintainer workflows and report evolution

- [ ] Before/after comparison for two scan reports
- [ ] GitHub Issue report template generated from a redacted scan
- [ ] SARIF output for stable infrastructure findings
- [ ] Plugin contract for community diagnostic rules
- [ ] Versioned report schema and compatibility test suite

## Later, only with evidence

- Remote fleet summaries without a resident agent
- Optional local or user-provided API explanation of already-redacted reports
- Additional distributions after volunteer maintainers can validate them

## Explicit non-goals

- Replacing monitoring, EDR, vulnerability scanners, or professional incident response
- Automatically changing firewall or SSH access policy
- Uploading telemetry or requiring an account
- Claiming a score is a compliance or security certification
