#!/usr/bin/env bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
CURRENT_PLATFORM=$( uname | tr '[:upper:]' '[:lower:]' )
is_windows() { case "$CURRENT_PLATFORM" in msys*|cygwin*) true ;; *) false ;; esac }
is_mac() { case "$CURRENT_PLATFORM" in darwin*) true ;; *) false ;; esac }

source "$DOTFILES_DIR"/core/colors.sh

# Make files executable
chmod u+x ./Nodefile
for func_file in "${DOTFILES_DIR}/_functions/"*; do
	# Skip files beginning with underscore
	func_name=${func_file#$DOTFILES_DIR/_functions/}
	[ "${func_name:0:1}" = "_" ] && continue;
	chmod u+x "$func_file"
done
print_green "Made files executable"

# Because ln in git bash is just a cp
if is_windows; then
	print_yellow "On Windows, run init.ps1 through an elevated PowerShell prompt instead."
	exit
fi

# Hack to remove beep when pressing Ctrl+Cmd+Arrow
# https://github.com/adobe/brackets/issues/2419
if is_mac; then
	mkdir -p ~/Library/KeyBindings
	cp "$DOTFILES_DIR/DefaultKeyBinding.dict" ~/Library/KeyBindings/DefaultKeyBinding.dict
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

while true; do
	read -p "Add vim plugins? [y/N] " yn
	case $yn in
		[Yy]*)
			mkdir -p ~/.vim/pack/vendor/start
			git -C ~/.vim/pack/vendor/start clone https://github.com/itchyny/lightline.vim.git
			git -C ~/.vim/pack/vendor/start clone https://github.com/editorconfig/editorconfig-vim.git
			git -C ~/.vim/pack/vendor/start clone https://github.com/preservim/nerdtree.git
			vim -u NONE -c "helptags ~/.vim/pack/vendor/start/nerdtree/doc" -c q
			git -C ~/.vim/pack/vendor/start clone https://github.com/airblade/vim-gitgutter.git
			vim -u NONE -c "helptags ~/.vim/pack/vendor/start/vim-gitgutter/doc" -c q
			git -C ~/.vim/pack/vendor/start clone https://github.com/mhartington/oceanic-next.git
			print_green "Added vim plugins"
			break ;;
		*)
			print_yellow "Skipped vim plugins"
			break ;;
	esac
done
