# Repository instructions

## Goal

Keep VPS Doctor read-only by default, explainable, privacy-conscious, and safe for inexperienced operators.

## Required verification

For every code change run:

```bash
bash -n bin/vps-doctor install.sh uninstall.sh lib/*.sh checks/*.sh fixes/*.sh tests/*.sh scripts/*.sh
bash tests/run.sh
shellcheck -x bin/vps-doctor install.sh uninstall.sh lib/*.sh checks/*.sh fixes/*.sh tests/*.sh scripts/*.sh
```

## Boundaries

- Checks must never modify host state.
- Never run a repair from a scan or score automatically.
- New repairs require dry-run, explicit confirmation, exact targets, failure-safe behavior, and documentation.
- Treat command output as untrusted data; quote expansions and redact report evidence.
- Missing tools and insufficient permissions should create `skip` findings instead of aborting unrelated checks.
- Keep stable rule IDs and the JSON schema backward compatible within a major version.
- Update tests, rule catalog, changelog, and both READMEs when user-facing behavior changes.
