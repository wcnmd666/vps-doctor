# Security policy

## Supported versions

| Version | Security fixes |
|---|---|
| Latest tagged release | Yes |
| `main` | Best effort |
| Older releases | No |

## Reporting a vulnerability

Please do not open a public issue for a vulnerability that could expose secrets, execute unintended commands, damage a host, bypass repair confirmation, or weaken report redaction.

Use GitHub's private vulnerability reporting feature for this repository. Include:

- affected version and operating system;
- exact preconditions;
- minimal reproduction steps;
- expected and observed behavior;
- impact and suggested mitigation, if known.

Do not include real credentials, production data, or access to a live system. You should receive an acknowledgment within seven days after the maintainer configures the public repository and private reporting channel.

## Trust model

- Scans are intended to be read-only.
- Repair actions are privileged and opt-in.
- Reports are locally generated and never uploaded by the project.
- Redaction reduces accidental disclosure but cannot guarantee that arbitrary command output is safe to publish.
- A health score is not a penetration test, compliance result, or guarantee of security.

## Installer guidance

Running remote content as root is a meaningful trust decision. Prefer a tagged release, verify published checksums, inspect `install.sh`, and install from a local checkout. The one-line installer exists for discoverability and disposable testing, not as a substitute for review.
