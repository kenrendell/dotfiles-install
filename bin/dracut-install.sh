#!/bin/sh
# Create Unified Kernel Images using Dracut

[ "$(whoami)" = 'root' ] || { printf 'Root permission is needed!\n'; exit 1; }

readonly EFI_DIR="/efi/EFI/Linux"

for file in /usr/lib/modules/*/pkgbase; do
	kver="${file#'/usr/lib/modules/'}"
	kver="${kver%'/pkgbase'}"
	[ -z "${kver##*'/'*}" ] && continue

	read -r pkgbase < "$file"
	mkdir -p "$EFI_DIR" && dracut --force --uefi --kver "$kver" "${EFI_DIR}/${pkgbase}.efi"
done
