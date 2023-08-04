# Arch linux installation guide
# BIOS system

# Set console font (/usr/share/kbd/consolefonts/)
setfont ter-v14n

# Install package to new root
pacstrap -K /mnt base linux linux-firmware efibootmgr neovim sudo git iwd dhcpcd

# Install microcode, 'intel-ucode' for intel CPUs, and 'amd-ucode' for AMD CPUs.

# Enroll Secure Boot Keys
sbctl create-keys
sbctl enroll-keys --microsoft

# Create Unified Kernel Image using Dracut
dracut-install.sh

# Add super user (uncomment the line with wheel group in sudoers file)
useradd --create-home --groups=wheel <username>
passwd <username>
passwd
