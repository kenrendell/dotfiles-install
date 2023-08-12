#!/bin/sh
# Set timezone
# Usage: set-timezone.sh

[ "$(whoami)" = 'root' ] || { printf 'Root permission is needed!\n'; exit 1; }

# Set timezone
TZ="$(tzselect)"
printf 'Selected timezone: %s\n' "$TZ"
ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime

# Set hardware clock from system clock
hwclock --systohc
