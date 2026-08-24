# Privacy and report handling

VPS Doctor has no account, analytics, tracking pixel, remote report endpoint, or background process. The only default outbound test is a DNS resolution lookup; configured domain/TLS checks are opt-in and skipped by `--quick`.

Reports apply best-effort redaction to:

- the current username;
- the current hostname;
- IPv4-like strings;
- assignments whose names contain `TOKEN`, `KEY`, `SECRET`, or `PASSWORD`.

This does not cover every secret format, domain name, path, container name, customer identifier, IPv6 representation, application log, or data embedded in arbitrary command output.

Before attaching a report to an issue:

1. Open the complete report locally.
2. Search for usernames, IPs, domains, paths, tokens, email addresses, and customer data.
3. Remove evidence that is unnecessary for the issue.
4. Prefer the smallest relevant rule section over a full report.

Raw command output is not stored persistently by the scanner unless the operator chooses an output file.
