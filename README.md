# Installation scripts for my [dotfiles](https://github.com/kenrendell/dotfiles)

## Installation

### Configure the system

See [Arch Linux installation guide](https://wiki.archlinux.org/title/Installation_guide).

``` sh
pacstrap -K /mnt base linux linux-firmware efibootmgr sbctl git
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```

### Install dotfiles

Prerequisites:

* Arch Linux is booted in UEFI mode. Run `cat /sys/firmware/efi/fw_platform_size` and if the file exists, then the system is booted in UEFI mode. See [UEFI](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface#From_Linux).
* Secure boot is disabled and is in setup mode. Run `sbctl status` to check the secure boot status.
* EFI partition is mounted in `/efi` directory. See [EFI partition](https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points).
* The root and swap partition must be labeled "SYSTEM" and "SWAP", respectively.

Then run the following in `arch-chroot` environment:

``` sh
git clone 'https://github.com/kenrendell/dotfiles-install.git' /srv/git/dotfiles-install
/srv/git/dotfiles-install/install.sh username
```

After successfully creating [unified kernel images](https://wiki.archlinux.org/title/Unified_kernel_image), create an UEFI boot entry for each EFI executable in `/efi/EFI/Linux` directory with the following command:

``` sh
efibootmgr --create --disk /dev/sdX --part partition-number --label "Arch Linux" --loader 'EFI\Linux\linux.efi' --unicode
```
