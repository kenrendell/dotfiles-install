# Installation scripts for my [DOTFILES](https://github.com/kenrendell/dotfiles)

## Installation

### Configure the System

See (Arch Linux installation guide)[https://wiki.archlinux.org/title/Installation_guide].

``` sh
pacstrap -K /mnt base linux linux-firmware git sbctl
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```

### Install Dotfiles

Prerequisites:

* Arch Linux is booted in UEFI mode. Run `cat /sys/firmware/efi/fw_platform_size` and if the file exists, then the system is booted in UEFI mode.
* Secure boot is disabled and is in setup mode. Run `sbctl status` to check the secure boot status.
* EFI partition is mounted in `/efi` directory, see (EFI partition)[https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points].
* The root and swap partition must be labeled "SYSTEM" and "SWAP", respectively.

Then run the following in `arch-chroot` environment:

``` sh
git clone 'https://github.com/kenrendell/dotfiles-install.git' /srv/git/dotfiles-install
/srv/git/dotfiles-install/install.sh username
```
