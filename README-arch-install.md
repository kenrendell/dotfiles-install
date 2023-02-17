# Arch linux installation guide
# BIOS system

# Set console font (/usr/share/kbd/consolefonts/)
setfont ter-v14n

# Install package to new root
pacstrap -K /mnt base linux linux-firmware grub efibootmgr booster neovim sudo git iwd dhcpcd

# Install bootloader (for example, '/dev/sda' not partition '/dev/sdaN')
grub-install --target=i386-pc /dev/sdX
