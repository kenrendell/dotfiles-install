#!/bin/sh
# Configure GRUB bootloader
# Usage: grub.cfg.sh

[ "$#" -eq 0 ] || { printf 'Usage: grub.cfg.sh\n'; exit 1; }

[ "$(whoami)" = 'root' ] || { printf 'Root permission is needed!\n'; exit 1; }

cd "${0%/*}" || exit 1

cp ./fonts/* /boot/grub/fonts
cp ./themes/theme.conf /boot/grub/themes
cp /boot/grub/grub.cfg /boot/grub/grub.cfg.bak

# Find the UUID of boot and root partition
boot_uuid="$(lsblk -o MOUNTPOINT,UUID | \
	sed --posix -nE 's/^[[:space:]]*\/boot[[:space:]]+([[:alnum:]-]+)[[:space:]]*$/\1/p')"
root_uuid="$(lsblk -o MOUNTPOINT,UUID | \
	sed --posix -nE 's/^[[:space:]]*\/[[:space:]]+([[:alnum:]-]+)[[:space:]]*$/\1/p')"

cat << EOF > /boot/grub/grub.cfg
# GRUB Configuration File

# UUID of root partition
root_uuid=$root_uuid
export root_uuid

# UUID of boot partition
boot_uuid=$boot_uuid
export boot_uuid

# If boot partition exists, then use boot partition instead of root partition.
if [ -n "\$boot_uuid" ]; then
	search --no-floppy --fs-uuid --set=boot \$boot_uuid
	boot_path="(\$boot)"
else
	search --no-floppy --fs-uuid --set=root \$root_uuid
	boot_path="(\$root)/boot"
fi
export boot_path

# Graphical menu/terminal modules
insmod all_video
insmod gfxterm
insmod gfxmenu

# REGEX wildcards
insmod regexp

# Default menu entry
set default=0

# Hidden menu ('Esc' to show the menu)
set timeout_style=hidden
set timeout=0

# Enable command-line pager
set pager=1

# Terminal input/output device
terminal_input console
terminal_output gfxterm

# Video resolution
set gfxmode=auto
set gfxpayload=keep

# Load fonts
for font in \$boot_path/grub/fonts/Terminus-*-Regular.pf2; do loadfont \$font; done

# GRUB theme
set theme=\$boot_path/grub/themes/theme.conf
export theme

# Default linux kernel parameters
linux_defaults="\\
root=UUID=\$root_uuid rw nohibernate \\
loglevel=3 quiet systemd.show_status=error \\
consoleblank=300 vt.color=0x07 vt.italic=5 vt.underline=6 \\
vt.default_red=0,220,121,225,85,176,74,161,94,228,152,231,120,192,115,186 \\
vt.default_grn=0,101,179,128,150,122,176,168,104,134,196,157,172,149,196,192 \\
vt.default_blu=0,125,112,81,226,184,166,181,120,152,145,120,231,198,188,201"
export linux_defaults

####################
### MENU ENTRIES ###
####################

### ARCH LINUX (main) ### {{{

menuentry 'Arch Linux, with linux-lts' --class=none {
	linux \$boot_path/vmlinuz-linux-lts \$linux_defaults i915.modeset=1 i915.fastboot=1 i915.enable_fbc=1
	initrd \$boot_path/intel-ucode.img \$boot_path/initramfs-linux-lts.img
}

menuentry 'Arch Linux, with linux-lts (fallback)' --class=none {
	linux \$boot_path/vmlinuz-linux-lts \$linux_defaults
	initrd \$boot_path/intel-ucode.img \$boot_path/initramfs-linux-lts-fallback.img
}

menuentry 'Arch Linux, with linux-lts (recovery)' --class=none {
	linux \$boot_path/vmlinuz-linux-lts \$linux_defaults single
	initrd \$boot_path/intel-ucode.img \$boot_path/initramfs-linux-lts-fallback.img
}

### }}}

### POWER OPTIONS ### {{{

menuentry 'Reboot' --class=none --hotkey=r { reboot }
menuentry 'Shutdown' --class=none --hotkey=s { halt }

### }}}
EOF
