#!/bin/sh
# Create Unified Kernel Images using Dracut

[ "$(whoami)" = 'root' ] || { printf 'Root permission is needed!\n'; exit 1; }

readonly EFI_DIR="/efi/EFI/Linux"
readonly EFI_BACKUP_DIR="/boot/${EFI_DIR#'/efi/'}-backup" # Backup directory for EFI files

for file in /usr/lib/modules/*/pkgbase; do
	kver="${file#'/usr/lib/modules/'}"
	kver="${kver%'/pkgbase'}"
	[ -z "${kver##*'/'*}" ] && continue

	read -r pkgbase < "$file"
	efi_file="${EFI_DIR}/${pkgbase}.efi"

	mkdir -p "$EFI_BACKUP_DIR" && cp -f "$efi_file" "$EFI_BACKUP_DIR"
	mkdir -p "$EFI_DIR" && dracut --force --uefi --kver "$kver" "$efi_file"
done
