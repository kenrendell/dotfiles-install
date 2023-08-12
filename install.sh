#!/bin/sh
# Installation script
# Usage: install.sh <username>

[ "$#" -ne 1 ] && { printf 'Usage: install.sh <username>\n'; exit 1; }

[ "$(whoami)" = 'root' ] || { printf 'Root permission is needed!\n'; exit 1; }

cd "${0%/*}" || exit 1

username="$1"

# Configure user
id -u "$username" >/dev/null 2>&1 || \
	useradd -m -G wheel,audio,video,uucp,disk "$username"

# Configure user password
[ "$(passwd -S "$username" | cut -d ' ' -f 2)" != 'P' ] && \
	{ printf 'User Password\n'; passwd -q "$username"; }

# Configure root password
[ "$(passwd -S | cut -d ' ' -f 2)" != 'P' ] && \
	{ printf 'Root Password\n'; passwd -q; }

step=1
while [ "$step" -gt 0 ]; do clear
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
			printf 'Update pacman mirrorlist? [y/N]: '; read -r ans
			[ -n "${ans}" ] && { [ -z "${ans#y}" ] || [ -z "${ans#Y}" ]; } && ./bin/update-mirrorlist.sh
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
		*) step=-1 ;;
	esac

	printf "Press [Enter] to continue (enter 'q' to quit): "
	read -r input; [ "$input" = 'q' ] && exit 1
	step=$((step + 1))
done; clear

# Set user shell
usermod -s /bin/zsh "$username"

# Copy files to their respective directories
cp -r ./etc/* /etc || { printf "Failed to copy etc files to '/etc' directory!\n" 1>&2; exit 1; }
cp -r ./bin/* /usr/local/bin/

# Set timezone
./set-timezone.sh

# Generate the locales
locale-gen

# Hostname
printf 'Hostname: '; read -r hostname
printf '%s\n' "$hostname" > /etc/hostname

# Enable networking
systemctl enable systemd-resolved.service
systemctl enable systemd-networkd.service
systemctl disable systemd-networkd-wait-online.service
systemctl enable iwd.service

# Enable firewall
systemctl enable nftables.service

# Rootless containers
#touch /etc/subuid /etc/subgid
#usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$username"

# Enable podman service
systemctl enable podman.service

# Enable apparmor service
systemctl enable apparmor.service

# Enable bluetooth service
systemctl enable bluetooth.service

# Enable power services
systemctl enable tlp.service

# Enable SSH
systemctl enable sshd.service

# Enable music player daemon (MPD)
su --login "$username" -c 'mkdir -p ~/.local/share/mpd/playlists'
systemctl --user --machine="${username}"'@.host' enable mpd.service

# Enable Syncthing
systemctl --user --machine="${username}"'@.host' enable syncthing.service

# Enable audio
systemctl --user --machine="${username}"'@.host' enable pipewire.service
systemctl --user --machine="${username}"'@.host' enable wireplumber.service

# Enable automount
systemctl enable autofs.service

sbctl create-keys
sbctl enroll-keys --microsoft
./install-cpu-microcode.sh
