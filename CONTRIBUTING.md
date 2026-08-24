# Contributing

Thank you for helping VPS Doctor make server troubleshooting safer and easier to explain.

## Before opening an issue

1. Run the latest release.
2. Re-run with `--format json --output report.json`.
3. Review the report manually for private information.
4. Include the rule ID, operating system version, expected result, and actual result.

Never publish tokens, passwords, private keys, full IP addresses, or unreviewed logs.

## Development setup

The project requires Bash 4.4+. No package installation is needed for the core test suite.

```bash
bash -n bin/vps-doctor lib/*.sh checks/*.sh fixes/*.sh tests/*.sh
bash tests/run.sh
```

ShellCheck runs in CI. Before submitting a pull request, install it from your distribution and run:

```bash
shellcheck -x bin/vps-doctor install.sh uninstall.sh lib/*.sh checks/*.sh fixes/*.sh tests/*.sh
```

## Adding a diagnostic rule

A useful rule must be:

- read-only;
- deterministic enough to test;
- grounded in evidence available on the host;
- explicit about false-positive conditions;
- accompanied by a stable ID, severity, recommendation, and tests;
- safe when the required command, file, or permission is missing.

Do not add a rule merely to increase the score or feature count.

## Adding a repair action

Repair pull requests receive extra scrutiny. A repair must:

- be separate from scanning;
- require root only when necessary;
- support `--dry-run`;
- explain impact before confirmation;
- back up modified configuration when practical;
- use exact paths and avoid broad globs for deletion;
- fail closed when state is ambiguous;
- document interruption, rollback, and lockout risks.

Firewall, SSH access, filesystem deletion, database mutation, and automatic service restarts are not accepted without a narrowly scoped design proposal first.

## Pull requests

Keep changes focused. Update documentation and `CHANGELOG.md`, add or update tests, and explain how you validated the change. By contributing, you agree that your contribution is licensed under MIT.
