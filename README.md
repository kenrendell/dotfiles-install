# Arch linux installation guide
# BIOS system

# Set console font (/usr/share/kbd/consolefonts/)
setfont ter-v14n

# Install package to new root
pacstrap /mnt base linux-lts linux-lts-headers linux-firmware grub networkmanager neovim sudo git f2fs-tools

# Install bootloader (for example, '/dev/sda' not partition '/dev/sdaN')
grub-install --target=i386-pc /dev/sdX
