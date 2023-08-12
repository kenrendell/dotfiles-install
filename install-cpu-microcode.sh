#!/bin/sh
# Install CPU microcode
# Usage: install-cpu-microcode.sh

[ "$(whoami)" = 'root' ] || { printf 'Root permission is needed!\n'; exit 1; }

vendor_id="$(sed -E -n 's/^[[:blank:]]*vendor_id[[:blank:]]*:[[:blank:]]*([[:alpha:]]*)[[:blank:]]*$/\1/p' /proc/cpuinfo | head -n 1)"

case "$vendor_id" in
	GenuineIntel) printf 'CPU vendor: Intel\n'; pacman -S --needed intel-ucode ;;
	AuthenticAMD) printf 'CPU vendor: AMD\n'; pacman -S --needed amd-ucode ;;
	*) printf 'Unknown CPU vendor!\n' ;;
esac
