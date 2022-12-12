#!/bin/sh
# Installation script
# Usage: install.sh

[ "$#" -eq 0 ] || { printf 'Usage: install.sh\n'; exit 1; }

[ "$(whoami)" = 'root' ] || { printf 'Root permission is needed!\n'; exit 1; }

cd "${0%/*}" || exit 1
username="$(pwd | sed -E -n 's/^\/home\/([^/]+).+$/\1/p')"

while [ "${step=1}" -le 9 ]; do clear
	# Check internet connection
	while ! ping -c 1 archlinux.org >/dev/null 2>&1; do
		printf 'No internet connection!\n'
		sleep 3
	done

	case "$step" in
		1) # Configure Pacman
			sed -E -e 's/^#?(ParallelDownloads[[:space:]]*=).+$/\1 5/' \
				-e 's/^#?(Color)$/\1/' -i /etc/pacman.conf
			;;
		2) # Install 'reflector' package
			pacman -S --needed reflector || \
				{ printf "Failed to install 'reflector' package!\n"; exit 1; }
			;;
		3) # Get the latest pacman mirrorlist
			printf 'Update pacman mirrorlist? [Y/n]: '; read -r ans
			if [ "$ans" = 'Y' ] || [ "$ans" = 'y' ] || [ -z "$ans" ]; then
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

				reflector --protocol https --latest 5 \
					--sort age --save /etc/pacman.d/mirrorlist

				# Enter `:n' and `:p' in `less' to search
				# for next and previous file, respectively.
				less /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

				printf "Delete '/etc/pacman.d/mirrorlist.bak'? [y/(r)ecover/N]: "
				read -r ans; case "$ans" in
					Y|y) rm -rf /etc/pacman.d/mirrorlist.bak ;;
					R|r) mv /etc/pacman.d/mirrorlist.bak /etc/pacman.d/mirrorlist ;;
				esac
			fi
			;;
		4) # Update system
			pacman -Syu || { printf 'Failed to update system!\n'; exit 1; }
			;;
		5) # Install packages
			sed -E -n 's/^[[:space:]]*\*[[:space:]]*([[:alnum:]_-]*)[[:space:]]*$/\1/p' \
				./packages.txt | pacman -S --needed - || \
				{ printf 'Failed to install packages!\n.\n'; exit 1; }
			;;
		6) # Install AUR helper
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
		7) # Install AUR packages
			su --pty --login "$username" -c "
				sed -E -n 's/^[[:space:]]*@[[:space:]]*([[:alnum:]_-]*)[[:space:]]*$/\1/p' \
					'$(pwd)/packages.txt' | paru -S --needed -
			" || { printf 'Failed to install AUR packages!\n'; exit 1; }
			;;
		8) # Install dotfiles
			printf 'Install dotfiles? [Y/n]: '; read -r ans
			{ [ "$ans" = 'Y' ] || [ "$ans" = 'y' ] || [ -z "$ans" ]; } && \
				su --login "$username" -c "$(pwd)/dotfiles-install.sh"
			;;
		9) # Setup firewall
			printf 'Setup firewall? [Y/n]: '; read -r ans
			{ [ "$ans" = 'Y' ] || [ "$ans" = 'y' ] || [ -z "$ans" ]; } && rm -rf ./nftables-conf && \
				git clone https://github.com/kenrendell/nftables-conf.git ./nftables-conf && \
				./nftables-conf/install.sh
			;;
	esac

	printf "Press [Enter] to continue (enter 'q' to quit): "
	read -r input; [ "$input" = 'q' ] && exit 1
	step=$((step + 1))
done; clear

# Stop DHCPCD from overwriting '/etc/resolv.conf'
printf '\nnohook resolv.conf\n' >> /etc/dhcpcd.conf

# Copy files to their respective directories
cp -r ./etc/* /etc || { printf "Failed to copy etc files to '/etc' directory!\n" 1>&2; exit 1; }

# Process all presets in /etc/mkinitcpio.d
mkinitcpio -P

# Configure the bootloader
./boot/grub-configure.sh

# Add user to some groups
usermod -a -G audio,video,uucp,wheel "$username"

# Configure shell
usermod -s /bin/zsh "$username"

# Rootless containers
touch /etc/subuid /etc/subgid
usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$username"

# Enable podman service
systemctl enable podman.service

# Enable bluetooth service
systemctl enable bluetooth.service

# Enable power services
systemctl enable tlp.service

# Enable networking
systemctl enable iwd.service
systemctl enable dhcpcd.service

# Enable SSH
systemctl enable sshd.service

# Enable firewall
systemctl enable firewall.service
systemctl enable update-nft-bogons.timer

# Scheduler
systemctl enable atd.service

# Enable chat service
#systemctl enable bitlbee.service
