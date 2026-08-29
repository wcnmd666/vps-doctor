# Privacy and report handling

VPS Doctor has no account, analytics, tracking pixel, remote report endpoint, or background process. The only default outbound test is a DNS resolution lookup; configured domain/TLS checks are opt-in and skipped by `--quick`.

Reports apply best-effort redaction to:

- the current username;
- the current hostname;
- IPv4-like strings;
- full and bracketed IPv6 literals covered by the built-in patterns;
- assignments whose names contain `TOKEN`, `KEY`, `SECRET`, or `PASSWORD`;
- common `Authorization: Bearer ...`, `Authorization: Basic ...`, and standalone bearer-token forms.

Standalone HTML reports also use a deny-by-default Content Security Policy and load no remote scripts, fonts, images, frames, or network resources.

Redaction is defense in depth, not a guarantee. It does not cover every secret format, domain name, path, container name, customer identifier, abbreviated IPv6 representation, application log, or data embedded in arbitrary command output.

Before attaching a report to an issue:

1. Open the complete report locally.
2. Search for usernames, IPs, domains, paths, tokens, email addresses, and customer data.
3. Remove evidence that is unnecessary for the issue.
4. Prefer the smallest relevant rule section over a full report.

Raw command output is not stored persistently by the scanner unless the operator chooses an output file.
