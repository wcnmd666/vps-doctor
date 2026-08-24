# Architecture

VPS Doctor is deliberately a short-lived CLI rather than a daemon.

```text
bin/vps-doctor
    │
    ├── lib/core.sh       environment, configuration, redaction, safety helpers
    ├── lib/results.sh    normalized finding registry and score calculation
    ├── checks/*.sh       read-only evidence collectors
    ├── lib/report.sh     terminal, JSON, and Markdown renderers
    └── fixes/actions.sh  separately invoked, confirmed privileged actions
```

## Execution model

1. Load defaults and an optional configuration file.
2. Initialize an empty in-memory finding registry.
3. Run each check module even when another module cannot collect evidence.
4. Normalize findings into a fixed schema.
5. Calculate a bounded score from actionable warning/failure severities.
6. Render locally; no network upload is performed.

## Finding schema

Each finding contains:

```text
id, category, status, severity, title,
summary, evidence, recommendation, fix
```

Statuses are `pass`, `warn`, `fail`, `info`, or `skip`. Severity affects score only for `warn` and `fail`: critical −20, high −12, medium −7, low −3. The score is a prioritization aid, not a probability or certification.

## Safety boundary

Checks must not mutate host state. Fixes are not called from a scan and cannot be selected automatically from a score. Repair code requires explicit action names, root privileges, impact text, and confirmation unless the operator intentionally passes `--yes`.

## Portability

The code targets Bash 4.4 and standard tools present on Ubuntu/Debian. Optional capabilities are detected at runtime. Missing tools create `skip` findings instead of aborting the whole scan.
