#!/usr/bin/env bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
CURRENT_PLATFORM=$( uname | tr '[:upper:]' '[:lower:]' )
is_windows() { case "$CURRENT_PLATFORM" in msys*|cygwin*) true ;; *) false ;; esac }

source "$DOTFILES_DIR"/core/colors.sh

# Because ln in git bash is just a cp
if is_windows; then
	print_yellow "On Windows, run init.ps1 through an elevated PowerShell prompt instead."
	exit
fi

while true; do
	read -p "Replace existing dotfiles (.bashrc/.bash_profile/.inputrc/.ackrc/.npmrc) with symlinks? [y/N] " yn
	case $yn in
		[Yy]*)
			for file in .{bashrc,bash_profile,inputrc,ackrc,npmrc}; do
				src="$DOTFILES_DIR/$file"
				dest="$HOME/$file"

				rm -f "$dest"
				ln -s "$src" "$dest"

				print_green "Linked $src -> $dest"
			done
			break ;;
		*)
			print_yellow "Skipped symlinks"
			break ;;
	esac
done

while true; do
	read -p "Add include to global .gitconfig? [y/N] " yn
	case $yn in
		[Yy]*)
			git config --global include.path "$DOTFILES_DIR/.gitconfig"
			print_green "Added git config include"
			break ;;
		*)
			print_yellow "Skipped git config include"
			break ;;
	esac
done
