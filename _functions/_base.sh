# Base stuff for all _functions

DOTFILES_DIR="${BASH_SOURCE%/*}"
DOTFILES_DIR="${DOTFILES_DIR%/*}"
if [ ! -d "$DOTFILES_DIR" ]; then
	echo "'$DOTFILES_DIR' is not a directory"
	exit 1
fi

# Platform, keep in sync with .bash_profile and init.sh
CURRENT_PLATFORM=$( uname | tr '[:upper:]' '[:lower:]' )
CURRENT_ARCH=$( uname -m | tr '[:upper:]' '[:lower:]' )
is_windows() { if [[ "$CURRENT_PLATFORM" == "msys"* || "$CURRENT_PLATFORM" == "cygwin"* ]]; then true; else false; fi }
is_mac() { if [[ "$CURRENT_PLATFORM" == "darwin"* ]]; then true; else false; fi }
is_apple() { if [[ "$CURRENT_PLATFORM" == "darwin"* && "$CURRENT_ARCH" == "arm64" ]]; then true; else false; fi }

for file in "$DOTFILES_DIR"/core/{colors,functions}.sh; do
	if [ ! -f "$file" ] || [ ! -r "$file" ]; then
		echo "'$file' doesn't exist or isn't readable"
		exit 1
	fi
  source "$file"
done
