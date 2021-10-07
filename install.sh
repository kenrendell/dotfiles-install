#!/bin/sh
# Installation script
# Usage: install.sh

[ "$#" -eq 0 ] || { printf 'Usage: install.sh\n'; exit 1; }

[ "$(whoami)" = 'root' ] || { printf 'Root permission is needed!\n'; exit 1; }

cd "${0%/*}" || exit 1

username="$(pwd | sed -E -n 's/^\/home\/([^/]+).+$/\1/p')"

# Configure pacman
[ -f '/etc/pacman.conf.bak' ] || \
	sed -E --in-place='.bak' -e 's/^#(Color)$/\1/' \
		-e 's/^#(ParallelDownloads[[:space:]]*=).+$/\1 4/' /etc/pacman.conf

while [ "${step=1}" -le 7 ]; do clear

	# Check internet connection
	while ! ping -c 2 archlinux.org >/dev/null 2>&1; do
		printf 'No internet connection!\n'
		sleep 3
	done

	case "$step" in
		1) # Install 'reflector' package
			pacman -S --needed reflector || \
				{ printf "Failed to install 'reflector' package!\n"; exit 1; }
			;;
		2) # Get the latest pacman mirrorlist
			printf 'Update pacman mirrorlist? [Y/n]: '; read -r ans

			if [ "$ans" = 'Y' ] || [ -z "$ans" ]; then
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

				reflector --verbose --protocol https --latest 30 \
					--fastest 5 --save /etc/pacman.d/mirrorlist

				less /etc/pacman.d/mirrorlist
			fi
			;;
		3) # Update system
			pacman -Syu || { printf 'Failed to update system!\n'; exit 1; }
			;;
		4) # Install packages
			sed -E -n 's/^[[:space:]]*\*[[:space:]]*([[:alnum:]_-]*)[[:space:]]*$/\1/p' \
				./packages.txt | pacman -S --needed - || \
				{ printf 'Failed to install packages!\n.\n'; exit 1; }
			;;
		5) # Install AUR helper
			if ! command -v paru >/dev/null 2>&1; then
				su --pty --login "$username" -c "
					git clone https://aur.archlinux.org/paru-bin.git '$(pwd)/paru-bin'
					( cd '$(pwd)/paru-bin' && makepkg -si )
					rm -rf ./paru-bin
				"
				command -v paru >/dev/null 2>&1 || \
					{ printf 'Failed to install AUR helper!\n'; exit 1; }
			else
				printf 'AUR helper is already installed, skipping ...\n'
			fi
			;;
		6) # Install AUR packages
			su --pty --login "$username" -c "
				sed -E -n 's/^[[:space:]]*@[[:space:]]*([[:alnum:]_-]*)[[:space:]]*$/\1/p' \
					'$(pwd)/packages.txt' | paru -S --needed -
			" || { printf 'Failed to install AUR packages!\n'; exit 1; }
			;;
		7) # Install dotfiles
			su --login "$username" -c "$(pwd)/dotfiles-install.sh" ;;
	esac

	step=$((step + 1))
	./bin/countdown.sh 60

done; clear

# Configure mkinitcpio and create initial ramdisks
cp ./boot/mkinitcpio.conf /etc/mkinitcpio.conf
mkinitcpio -P

# Configure GRUB bootloader
./boot/grub/grub.cfg.sh

# Configure the virtual console
printf 'KEYMAP=us1\nFONT=ter-v14n\n' > /etc/vconsole.conf

# Add user to video and audio group
usermod -a -G audio,video "$username"

# Configure shell
usermod -s /bin/zsh "$username"

# Enable bluetooth service
systemctl --now enable bluetooth.service

# Enable tlp for power saving
systemctl --now enable tlp.service

# Enable network manager
systemctl --now enable NetworkManager.service

# Enable firewall
ufw enable
systemctl --now enable ufw.service
