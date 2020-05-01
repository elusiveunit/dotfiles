# Base stuff for all _functions

DOTFILES_DIR="${BASH_SOURCE%/*}"
DOTFILES_DIR="${DOTFILES_DIR%/*}"
if [ ! -d "$DOTFILES_DIR" ]; then
	echo "'$DOTFILES_DIR' is not a directory"
	exit 1
fi

# Platform, keep in sync with .bash_profile
CURRENT_PLATFORM=$( uname | tr '[:upper:]' '[:lower:]' )
is_windows() { case "$CURRENT_PLATFORM" in msys*|cygwin*) true ;; *) false ;; esac }
is_mac() { case "$CURRENT_PLATFORM" in darwin*) true ;; *) false ;; esac }

for file in "$DOTFILES_DIR"/core/{colors,functions}.sh; do
	if [ ! -f "$file" ] || [ ! -r "$file" ]; then
		echo "'$file' doesn't exist or isn't readable"
		exit 1
	fi
  source "$file"
done
