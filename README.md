# Installation scripts for my [Dotfiles](https://github.com/kenrendell/dotfiles)

## Installation

### Configure the system

See [Arch Linux installation guide](https://wiki.archlinux.org/title/Installation_guide).

``` sh
pacstrap -K /mnt base linux linux-firmware efibootmgr sbctl git
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```

#### Nix Storage Optimization

* The `/nix/store` can grow significantly, as it holds all the Nix packages and their dependencies. If the `/nix/store` is on the root partition and it becomes too large, it could potentially exhaust the available space, causing system issues. Therefore, it's recommended to create a separate partition for `/nix`.
* Using `/nix` for building Nix packages rather than `/tmp` can help avoid running out of space, especially if `/tmp` is mounted as a tmpfs (which is often backed by RAM and swap). Since the size of `/tmp` is typically limited to a fraction of your RAM, large builds can easily exhaust this space, leading to build failures. To achieve this, set `build-dir = /nix` in `nix.conf` or set the environment variable `TMPDIR` to `/nix`.

For more info, see [storage optimization](https://nixos.wiki/wiki/Storage_optimization).

### Install Dotfiles

Prerequisites:

* Arch Linux is booted in UEFI mode. Run `cat /sys/firmware/efi/fw_platform_size` and if the file exists, then the system is booted in UEFI mode. See [UEFI from Linux](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface#From_Linux).
* Secure boot is disabled and is in setup mode. Run `sbctl status` to check the secure boot status.
* EFI partition is mounted in `/efi` directory. See [typical mount points for EFI partition](https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points).
* The EFI, Root and Swap partition must be labeled *EFI*, *SYSTEM*, and *SWAP*, respectively.

Then run the following in `arch-chroot` environment:

``` sh
git clone 'https://github.com/kenrendell/dotfiles-install.git' /srv/git/dotfiles-install
/srv/git/dotfiles-install/install.sh "${USERNAME}"
```

After successfully creating [unified kernel images](https://wiki.archlinux.org/title/Unified_kernel_image), create an UEFI boot entry for each EFI executable in `/efi/EFI/Linux` directory with the following command:

``` sh
efibootmgr --create --disk "${DISK}" --part "${DISK_PARTITION_NUMBER}" --label 'Arch Linux' --loader 'EFI\Linux\linux.efi' --unicode
efibootmgr --create --disk "${DISK}" --part "${DISK_PARTITION_NUMBER}" --label 'Arch Linux (LTS)' --loader 'EFI\Linux\linux-lts.efi' --unicode
```
