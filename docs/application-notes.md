# Codex for Open Source application notes

This file is an internal preparation aid, not a claim that the project already qualifies.

## Strong application story

VPS Doctor reduces the maintenance burden for small OSS and self-hosted projects by standardizing first-response evidence from Linux hosts. Maintainers can attach a redacted, versioned report instead of repeatedly asking users for disk, memory, service, network, Docker, and TLS diagnostics.

## Evidence required before applying

- Keep the repository public and actively maintained.
- Publish tagged releases rather than relying only on `main`.
- Record real external use: stars are helpful, but downloads, outside issues/PRs, downstream references, and reproducible case studies are stronger.
- Maintain an honest changelog, security policy, and response history.
- Document the maintainer's actual role and ongoing responsibilities.
- Never claim GitHub stars, downloads, users, or ecosystem impact that cannot be verified.

## Possible API-credit use, after the deterministic core is adopted

An optional maintainer workflow could summarize an already-redacted report, group related findings, draft a GitHub issue, or compare two incident reports. The deterministic evidence and human approval must remain authoritative; an AI explanation must never execute repairs automatically.

## Suggested 500-character answer structure

Use current verified numbers at application time:

```text
I am the primary maintainer of VPS Doctor, a read-only-first Linux incident
diagnostic CLI used to standardize support evidence for small OSS/self-hosted
deployments. It has [verified adoption], [verified releases/activity], and
[specific ecosystem use]. I review issues/PRs, maintain diagnostic rules,
validate Ubuntu/Debian behavior, publish releases, and handle security reports.
```

Rewrite this with real evidence; do not submit bracketed placeholders.
