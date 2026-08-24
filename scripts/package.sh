#!/usr/bin/env bash

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(awk -F'"' '/^VERSION=/{print $2; exit}' "$ROOT_DIR/bin/vps-doctor")"
DIST_DIR="$ROOT_DIR/dist"
STAGE="$(mktemp -d)"
trap 'rm -rf -- "${STAGE:?}"' EXIT

mkdir -p "$DIST_DIR" "$STAGE/vps-doctor-$VERSION"
for path in bin checks config fixes lib docs LICENSE README.md README.zh-CN.md CHANGELOG.md SECURITY.md \
  PROJECT_SUMMARY.md ROADMAP.md ARCHITECTURE.md CONTRIBUTING.md CODE_OF_CONDUCT.md SUPPORT.md; do
  cp -a "$ROOT_DIR/$path" "$STAGE/vps-doctor-$VERSION/"
done
cp "$ROOT_DIR/install.sh" "$ROOT_DIR/uninstall.sh" "$STAGE/vps-doctor-$VERSION/"
tar -czf "$DIST_DIR/vps-doctor-$VERSION.tar.gz" -C "$STAGE" "vps-doctor-$VERSION"
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$DIST_DIR" && sha256sum "vps-doctor-$VERSION.tar.gz" >SHA256SUMS)
fi
printf 'Created %s\n' "$DIST_DIR/vps-doctor-$VERSION.tar.gz"
