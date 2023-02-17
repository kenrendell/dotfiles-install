# Arch linux installation guide
# BIOS system

# Set console font (/usr/share/kbd/consolefonts/)
setfont ter-v14n

# Install package to new root
pacstrap -K /mnt base linux linux-firmware grub efibootmgr booster neovim sudo git iwd dhcpcd

# Add super user (uncomment the line with wheel group in sudoers file)
useradd --create-home --groups=wheel <username>
passwd <username>
passwd
