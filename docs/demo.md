# Demo script

The public demo should use a disposable Ubuntu VM or container created for the recording. Never deliberately fill or break a production host.

## Suggested 30-second sequence

1. Start with a fixture where the root disk threshold is lowered in a temporary config, swap is absent, and a sample systemd unit is failed.
2. Run `sudo vps-doctor scan` and show the grade plus three actionable findings.
3. Run `sudo vps-doctor scan --format markdown --output report.md`.
4. Open the redacted report briefly.
5. Preview `sudo vps-doctor fix vacuum-journal --dry-run`.
6. End on: “Read-only by default. Evidence before action.”

Record the exact version and fixture setup in the release notes so viewers can reproduce the demonstration.
