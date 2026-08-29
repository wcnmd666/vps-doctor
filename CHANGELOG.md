# Changelog

All notable changes follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and semantic versioning.

## [Unreleased]

## [0.2.0] - 2026-08-29

### Added

- Standalone offline HTML incident reports with escaped finding content and no remote assets
- Configurable diagnostic thresholds with fail-safe validation
- Auditable rule exclusions that require stable rule IDs and reasons and remain visible as skipped findings
- Deterministic Ubuntu/Debian fixtures covering system, storage, memory, services, networking, and security behavior
- Release checksum verification guidance and GitHub build-provenance attestations for release archives

### Changed

- Release publishing is rerun-safe when a GitHub Release already exists
- CI now uses bounded job timeouts, duplicate-run concurrency controls, and immutable commit pins for GitHub Actions
- Release packaging verifies checksums and archive readability before publication
- Production installation guidance now prefers tagged, verified local artifacts over piping mutable remote content to root

### Security

- Expanded report redaction for IPv6 and common Authorization/Bearer credential forms
- Added a deny-by-default Content Security Policy to standalone HTML reports
- Strengthened test isolation with injectable fixture roots that default to the original production paths

## [0.1.0] - 2026-08-24

### Added

- 24 read-only diagnostic rules across eight categories
- Explainable 0–100 health score and stable rule identifiers
- Terminal, redacted JSON, and Markdown reports
- Five independent guarded repair actions with dry-run support
- Ubuntu/Debian configuration, installer, tests, and CI workflow
- English and Simplified Chinese documentation
