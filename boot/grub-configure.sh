#!/bin/sh
# Configure GRUB bootloader
# Usage: grub-configure.sh

[ "$#" -eq 0 ] || { printf 'Usage: grub-configure.sh\n' 1>&2; exit 1; }

[ "$(whoami)" = 'root' ] || { printf 'Root permission is needed!\n' 1>&2; exit 1; }

cd "${0%/*}" || exit 1

# Check if the colors.txt file is valid
{ [ "$(wc --lines ./colors.txt | cut -d ' ' -f 1)" -eq 16 ] && \
	[ "$(grep -E '^[0-9a-fA-F]{6}$' ./colors.txt | wc --lines | cut -d ' ' -f 1)" -eq 16 ]; } || \
	{ printf "'%s/colors.txt' file must be 16 lines long with 6 hexadecimal characters (no spaces) in each line!\n" "${0%/*}" 1>&2; exit 1; }

# Find the UUID of boot, root, and swap partition
# uuid_format='[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
# boot_uuid="$(lsblk -o MOUNTPOINT,UUID | \
# 	sed -E -n "s/^[[:space:]]*\/boot[[:space:]]+(${uuid_format})[[:space:]]*\$/\1/p")"
# [ -n "$boot_uuid" ] || { printf 'UUID of boot partition is missing!\n' 1>&2; exit 1; }
# root_uuid="$(lsblk -o MOUNTPOINT,UUID | \
# 	sed -E -n "s/^[[:space:]]*\/[[:space:]]+(${uuid_format})[[:space:]]*\$/\1/p")"
# [ -n "$root_uuid" ] || { printf 'UUID of root partition is missing!\n' 1>&2; exit 1; }
# swap_uuid="$(lsblk -o FSTYPE,UUID | \
# 	sed -E -n "s/^[[:space:]]*swap[[:space:]]+(${uuid_format})[[:space:]]*\$/\1/p")"
# [ -n "$swap_uuid" ] || { printf 'UUID of swap partition is missing!\n' 1>&2; exit 1; }
boot_uuid="$(findmnt --fstab --output=UUID --noheadings --target=/boot)"
[ -n "$boot_uuid" ] || { printf 'UUID of boot partition is missing!\n' 1>&2; exit 1; }
root_uuid="$(findmnt --fstab --output=UUID --noheadings --target=/)"
[ -n "$root_uuid" ] || { printf 'UUID of root partition is missing!\n' 1>&2; exit 1; }
swap_uuid="$(findmnt --fstab --output=UUID --noheadings --types=swap)"
[ -n "$swap_uuid" ] || { printf 'UUID of swap partition is missing!\n' 1>&2; exit 1; }

# Extract the colors from colors.txt file
red="$(cut -c 1-2 ./colors.txt | xargs -I = printf ',%d' 0x= | cut -d , -f 2-)"
green="$(cut -c 3-4 ./colors.txt | xargs -I = printf ',%d' 0x= | cut -d , -f 2-)"
blue="$(cut -c 5-6 ./colors.txt | xargs -I = printf ',%d' 0x= | cut -d , -f 2-)"
i=0; while read -r color; do eval "color${i}='#${color}'"; i=$((i + 1)); done < ./colors.txt

# Create a backup and copy files to their respective directories
rm -rf /boot/grub.bak || { printf "Failed to remove '/boot/grub.bak' backup file!\n" 1>&2; exit 1; }
cp -r /boot/grub /boot/grub.bak || { printf "Failed to create '/boot/grub.bak' backup file!\n" 1>&2; exit 1; }
cp -r ./grub/* /boot/grub || { printf "Failed to copy GRUB files to '/boot/grub'!\n" 1>&2; exit 1; }

# Extract the boot parameters from boot-parameters.txt file
unset boot_params
while read -r param; do
	[ -n "$boot_params" ] && boot_params="${boot_params}"' \\\n'
	boot_params="${boot_params}${param}"
done < ./boot-parameters.txt

# GRUB configuration
cat << EOF > /boot/grub/grub.cfg
# GRUB Configuration File

# UUID of root partition
root_uuid=${root_uuid}
export root_uuid

# UUID of boot partition
boot_uuid=${boot_uuid}
export boot_uuid

# UUID of swap partition
swap_uuid=${swap_uuid}
export swap_uuid

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
set theme=\$boot_path/grub/theme.conf
export theme

# Virtual terminal parameters (see 'bootparam')
vt_defaults="\\
vt.color=0x07 vt.italic=5 vt.underline=6 \\
vt.default_red=${red} \\
vt.default_grn=${green} \\
vt.default_blu=${blue}"
export vt_defaults

# Linux default parameters (see 'bootparam')
defaults="$(printf '\\\n%b' "${boot_params}")"
export defaults

####################
### MENU ENTRIES ###
####################

### ARCH LINUX (main) ### {{{

menuentry 'Arch Linux' --class=none {
	linux \$boot_path/vmlinuz-linux root=UUID=\$root_uuid resume=UUID=\$swap_uuid rw loglevel=3 quiet \$vt_defaults \$defaults
	initrd \$boot_path/intel-ucode.img \$boot_path/booster-linux.img
}

menuentry 'Arch Linux (fallback)' --class=none {
	linux \$boot_path/vmlinuz-linux root=UUID=\$root_uuid resume=UUID=\$swap_uuid rw \$vt_defaults
	initrd \$boot_path/intel-ucode.img \$boot_path/booster-linux.img
}

menuentry 'Arch Linux, with linux-lts' --class=none {
	linux \$boot_path/vmlinuz-linux-lts root=UUID=\$root_uuid resume=UUID=\$swap_uuid rw loglevel=3 quiet \$vt_defaults \$defaults
	initrd \$boot_path/intel-ucode.img \$boot_path/booster-linux-lts.img
}

menuentry 'Arch Linux, with linux-lts (fallback)' --class=none {
	linux \$boot_path/vmlinuz-linux-lts root=UUID=\$root_uuid resume=UUID=\$swap_uuid rw \$vt_defaults
	initrd \$boot_path/intel-ucode.img \$boot_path/booster-linux-lts.img
}

### }}}

### POWER OPTIONS ### {{{

menuentry 'Reboot' --class=none --hotkey=r { reboot }
menuentry 'Shutdown' --class=none --hotkey=s { halt }

### }}}
EOF
[ "$?" = 0 ] || { printf "Failed to create/update '/boot/grub/grub.cfg' file!\n" 1>&2; exit 1; }

# GRUB Theme
cat << EOF > /boot/grub/theme.conf
# GRUB Theme

desktop-color:   "${color0}"
terminal-font:   "Terminus Regular 16"
terminal-width:  "100%"
terminal-height: "100%"
terminal-border: "0"

+ boot_menu {
	item_font           = "Terminus Regular 16"
	selected_item_font  = "Terminus Regular 18"
	item_color          = "${color4}"
	selected_item_color = "${color12}"
	height              = "60%"
	width               = "100%"
	align               = "left"
	item_height         = "24"
	item_padding        = "10"
	item_spacing        = "0"
	item_icon_space     = "0"
	icon_height         = "0"
	icon_width          = "0"
	scrollbar           = "false"
}

+ label {
	id    = "__timeout__"
	text  = "Booting in %d seconds"
	font  = "Terminus Regular 14"
	color = "${color5}"
	top   = "100%-50"
	width = "100%"
	align = "center"
}

+ label {
	text  = "(e)dit - (c)ommand - (r)eboot - (s)hutdown"
	font  = "Terminus Regular 12"
	color = "${color8}"
	top   = "100%-25"
	width = "100%"
	align = "center"
}
EOF
[ "$?" = 0 ] || { printf "Failed to create/update '/boot/grub/theme.conf' file!\n" 1>&2; exit 1; }
