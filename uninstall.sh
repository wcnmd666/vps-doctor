#!/usr/bin/env bash

set -euo pipefail
PREFIX="${VPS_DOCTOR_PREFIX:-/usr/local}"
[[ "${EUID:-$(id -u)}" -eq 0 ]] || { printf 'Please run as root (sudo).\n' >&2; exit 1; }
rm -f "$PREFIX/bin/vps-doctor"
rm -rf -- "${PREFIX:?}/lib/vps-doctor"
printf 'VPS Doctor removed. /etc/vps-doctor was kept for recovery.\n'
