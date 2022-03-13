#!/bin/sh
# Install dotfiles
# Usage: dotfiles-install.sh

[ "$#" -eq 0 ] || { printf 'Usage: dotfiles-install.sh\n'; exit 1; }

[ "$(whoami)" != 'root' ] || { printf 'Run this command as a normal user!\n'; exit 1; }

rm -rf "$HOME/.dotfiles"
git clone --bare 'https://github.com/kenrendell/dotfiles.git' "$HOME/.dotfiles" || \
	{ printf 'Failed to download dotfiles!\n'; exit 1; }

alias dotfiles="git --git-dir='$HOME/.dotfiles' --work-tree='$HOME'"
dotfiles config status.showUntrackedFiles no
dotfiles checkout >/dev/null 2>&1 || {
	dotfiles checkout 2>&1 | sed -E -n "s/^[[:space:]]+(.+)[[:space:]]*\$/'\1'/p" | xargs rm -rf
	dotfiles checkout
}
