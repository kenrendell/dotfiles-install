#!/bin/sh
# Set timezone
# Usage: set-timezone.sh

[ "$(whoami)" = 'root' ] || { printf 'Root permission is needed!\n'; exit 1; }

# Set timezone
TZ="$(tzselect)" || exit 1
printf 'Selected timezone: %s\n' "$TZ"
ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime || exit 1

# Set hardware clock from system clock
hwclock --systohc || exit 1
