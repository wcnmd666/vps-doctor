#!/usr/bin/env bash

set -euo pipefail

REPO="${VPS_DOCTOR_REPO:-wcnmd666/vps-doctor}"
VERSION="${VPS_DOCTOR_VERSION:-main}"
PREFIX="${VPS_DOCTOR_PREFIX:-/usr/local}"
INSTALL_DIR="$PREFIX/lib/vps-doctor"
BIN_LINK="$PREFIX/bin/vps-doctor"
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SOURCE_DIR=""
TEMP_DIR=""

cleanup() { [[ -z "$TEMP_DIR" ]] || rm -rf -- "${TEMP_DIR:?}"; }
trap cleanup EXIT

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  printf 'Please run the installer as root (sudo).\n' >&2
  exit 1
fi

if [[ -f "$SCRIPT_DIR/bin/vps-doctor" && -d "$SCRIPT_DIR/checks" ]]; then
  SOURCE_DIR="$SCRIPT_DIR"
else
  command -v curl >/dev/null 2>&1 || { printf 'curl is required.\n' >&2; exit 1; }
  command -v tar >/dev/null 2>&1 || { printf 'tar is required.\n' >&2; exit 1; }
  TEMP_DIR="$(mktemp -d)"
  curl --proto '=https' --tlsv1.2 -fsSL "https://github.com/$REPO/archive/$VERSION.tar.gz" -o "$TEMP_DIR/source.tar.gz"
  tar -xzf "$TEMP_DIR/source.tar.gz" -C "$TEMP_DIR"
  SOURCE_DIR="$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)"
fi

[[ -n "$SOURCE_DIR" && -f "$SOURCE_DIR/bin/vps-doctor" ]] || { printf 'Invalid source package.\n' >&2; exit 1; }

mkdir -p "$INSTALL_DIR" "$PREFIX/bin" /etc/vps-doctor
for part in bin lib checks fixes config; do
  rm -rf -- "${INSTALL_DIR:?}/$part"
  cp -a "$SOURCE_DIR/$part" "$INSTALL_DIR/$part"
done
chmod +x "$INSTALL_DIR/bin/vps-doctor"
ln -sfn "$INSTALL_DIR/bin/vps-doctor" "$BIN_LINK"
if [[ ! -e /etc/vps-doctor/config.conf ]]; then cp "$SOURCE_DIR/config/vps-doctor.conf" /etc/vps-doctor/config.conf; fi

printf 'VPS Doctor installed: %s\n' "$BIN_LINK"
"$BIN_LINK" version
