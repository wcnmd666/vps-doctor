# Release verification

VPS Doctor may be installed with root privileges, so release artifacts should be verified before installation on production systems.

## Recommended trust path

1. Download the tagged release archive and `SHA256SUMS` from the same GitHub Release.
2. Verify the archive checksum locally.
3. Verify the GitHub build provenance attestation when available.
4. Inspect the installer and package contents before running anything as root.
5. Install from the verified local checkout.

Example:

```bash
sha256sum --check SHA256SUMS

gh attestation verify vps-doctor-<version>.tar.gz \
  --repo wcnmd666/vps-doctor

tar -xzf vps-doctor-<version>.tar.gz
cd vps-doctor-<version>
less install.sh
sudo bash ./install.sh
```

`sha256sum --check` should report `OK` for the archive you downloaded. `gh attestation verify` should confirm that the archive has build provenance from this repository. Do not continue if the checksum is missing or mismatched, or if provenance verification fails when an attestation is expected.

## What each check proves

- `SHA256SUMS` confirms that the archive you downloaded matches the checksum published with that release.
- GitHub build provenance binds the archive digest to the repository's release workflow using GitHub's OIDC-backed attestation service.
- Neither check replaces source review. For a root-capable tool, inspect the tagged source and installer before installation on important systems.

## Why not pipe directly to root?

A command such as:

```bash
curl -fsSL https://raw.githubusercontent.com/wcnmd666/vps-doctor/main/install.sh | sudo bash
```

is convenient for disposable testing, but it executes mutable remote content with elevated privileges before you can inspect or verify the exact package. It is not the recommended production trust path.

## Release automation

Tagged releases are packaged by the repository's release workflow. The archive and `SHA256SUMS` are generated from the same checked-out tag, validated before publication, and the archive receives GitHub build provenance. Release publication is designed to be safe to rerun: if the GitHub Release already exists, the workflow replaces the generated artifacts instead of trying to create a duplicate release.

The release workflow pins third-party GitHub Actions to immutable commit SHAs and grants only the permissions required for repository contents, OIDC, and attestations.
