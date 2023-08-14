#!/bin/sh
# Enroll secure boot keys and create UEFI executables
# Usage: enroll-secureboot-keys.sh

[ "$(whoami)" = 'root' ] || { printf 'Root permission is needed!\n'; exit 1; }

cd "${0%/*}" || exit 1

secure_boot_status="$(sbctl status --json)" || exit 1

printf '%s\n' "$secure_boot_status" | jq -e '.secure_boot == false' >/dev/null || \
	{ printf 'Secure boot is already enabled!\n'; exit 1; }

printf '%s\n' "$secure_boot_status" | jq -e '.setup_mode == true' >/dev/null || \
	{ printf 'Secure boot must be in setup mode!\n'; exit 1; }

printf '%s\n' "$secure_boot_status" | jq -e '.installed == false' >/dev/null && \
	{ sbctl create-keys || exit 1; }

sbctl enroll-keys --microsoft && ./bin/dracut-install.sh
