# Release verification

VPS Doctor may be installed with root privileges, so release artifacts should be verified before installation on production systems.

## Recommended trust path

1. Download the tagged release archive and `SHA256SUMS` from the same GitHub Release.
2. Verify the archive checksum locally.
3. Inspect the installer and package contents before running anything as root.
4. Install from the verified local checkout.

Example:

```bash
sha256sum --check SHA256SUMS

tar -xzf vps-doctor-<version>.tar.gz
cd vps-doctor-<version>
less install.sh
sudo bash ./install.sh
```

`sha256sum --check` should report `OK` for the archive you downloaded. Do not continue if the checksum is missing, does not match, or came from a different release.

## Why not pipe directly to root?

A command such as:

```bash
curl -fsSL https://raw.githubusercontent.com/wcnmd666/vps-doctor/main/install.sh | sudo bash
```

is convenient for disposable testing, but it executes mutable remote content with elevated privileges before you can inspect or verify the exact package. It is not the recommended production trust path.

## Release automation

Tagged releases are packaged by the repository's release workflow. The archive and `SHA256SUMS` are generated from the same checked-out tag. Release publication is designed to be safe to rerun: if the GitHub Release already exists, the workflow replaces the generated artifacts instead of trying to create a duplicate release.

Checksums protect against accidental corruption and help confirm that a downloaded archive matches the published release artifact. They do not, by themselves, establish the identity of the publisher. Stronger provenance or attestation mechanisms may be added separately after they can be validated without weakening release reliability.
