#!/bin/sh
# Install dotfiles
# Usage: dotfiles-install.sh

[ "$#" -eq 0 ] || { printf 'Usage: dotfiles-install.sh\n'; exit 1; }

[ "$(whoami)" != 'root' ] || { printf 'Run this command as a normal user!\n'; exit 1; }

cd "$HOME" || { printf 'Please check the HOME environment!\n'; exit 1; }

rm -rf ./.dotfiles
git clone --bare https://github.com/kenrendell/dotfiles.git ./.dotfiles || \
	{ printf 'Failed to download dotfiles!\n'; exit 1; }

dotfiles() { git --git-dir=./.dotfiles --work-tree=./ "$@"; }

dotfiles checkout >/dev/null 2>&1 || {
	dotfiles checkout 2>&1 | \
		sed --posix -nE 's/^[[:space:]]+(.+)[[:space:]]*$/"\1"/p' | xargs rm -rf

	dotfiles checkout
}
