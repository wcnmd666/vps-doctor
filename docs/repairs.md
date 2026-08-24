# Repair safety model

VPS Doctor never runs a repair because a score is low. Operators choose a named action separately.

## Common controls

```bash
sudo vps-doctor fix <action> --dry-run
sudo vps-doctor fix <action>
```

`--dry-run` prints the planned operation without changing the host. `--yes` is intended for reviewed automation and skips the prompt; it does not bypass validation.

## Actions

### `vacuum-journal`

Runs `journalctl --vacuum-time=14d`. Recent evidence remains, but older systemd journal entries are permanently removed. Export incident logs first when investigating an event.

### `clean-apt-cache`

Runs `apt-get clean`. It removes downloaded package archives, not installed packages. Packages may need to be downloaded again later.

### `create-swap --size 2G`

Accepts 1G through 8G, verifies free disk space, refuses an existing `/swapfile` or active swap, backs up `/etc/fstab`, creates and activates the file, and adds an exact fstab entry. It is not a substitute for enough RAM.

### `enable-timesync`

Enables and starts `systemd-timesyncd` only when its unit exists. Hosts intentionally using chrony or another time service should not run this action.

### `configure-docker-logs`

Creates `/etc/docker/daemon.json` only when no non-empty configuration exists. It configures `json-file` rotation at 10 MiB × 3. Docker is not restarted automatically. Existing containers may need recreation for defaults to apply.

## Intentionally manual

The project gives advice but does not automatically:

- enable or change firewall rules;
- change SSH ports or authentication policy;
- delete arbitrary large files or Docker volumes;
- restart production services;
- repair databases;
- renew or replace certificates.

These operations require context the scanner cannot safely infer.
