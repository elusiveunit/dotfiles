# Platform, keep in sync with _functions/_base.sh
CURRENT_PLATFORM=$( uname | tr '[:upper:]' '[:lower:]' )
is_windows() { case "$CURRENT_PLATFORM" in msys*|cygwin*) true ;; *) false ;; esac }
is_mac() { case "$CURRENT_PLATFORM" in darwin*) true ;; *) false ;; esac }

if is_mac; then
	DOTFILES_DIR="$(dirname "$(greadlink -f "${BASH_SOURCE[0]}")")"
else
	DOTFILES_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
fi

# Source files
# -----------------------------------------------------------------------------
if is_mac; then
	# Git Bash on Windows has a __git_ps1 built in.
	source "$DOTFILES_DIR"/core/git_ps1.sh
	# The overridden PROMPT_COMMAND adds a noticeable delay in Windows git bash.
	source "$DOTFILES_DIR"/core/z.sh
	# fzf settings and keybindings.
	[ -f ~/.fzf.bash ] && source ~/.fzf.bash
fi
if is_windows; then
	# fzf keybindings, not included in the scoop install.
	source "$DOTFILES_DIR"/core/fzf-keybindings.sh
fi

# Core files for every OS.
for file in "$DOTFILES_DIR"/core/{colors,bash_prompt,aliases,functions}; do
	source "${file}.sh"
done

# Optional files (use the TEMP hack for easier future additions).
for file in "$DOTFILES_DIR"/optional/{secrets,TEMP}; do
	if [ "${file: -4}" != "TEMP" ]; then
		source "${file}-default.sh"
		[ -r "${file}.sh" ] && [ -f "${file}.sh" ] && source "${file}.sh";
	fi
done
unset file

# Prompt
# -----------------------------------------------------------------------------
trap 'prompt_timer_start' DEBUG

if [ "$PROMPT_COMMAND" == "" ]; then
  PROMPT_COMMAND="set_bash_prompt"
else
  PROMPT_COMMAND="set_bash_prompt; $PROMPT_COMMAND"
fi

# Various options
# -----------------------------------------------------------------------------

# Turn off beep.
set bell-style none

# Autocorrect typos in path names when using `cd`.
shopt -s cdspell

# Case-insensitive globbing (used in pathname expansion).
shopt -s nocaseglob

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null;
done;

# Increase Bash history size, default is 500.
export HISTSIZE=5000
export HISTFILESIZE="${HISTSIZE}"
# Prevent duplicates in command history.
export HISTCONTROL=ignoredups:erasedups
# Append to the Bash history file, rather than overwriting it.
shopt -s histappend;

# Prefer US English and UTF-8.
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Open file selected in fzf with VS Code.
export FZF_DEFAULT_OPTS="--bind='ctrl-o:execute(code {})+abort'"

# Misc.
export ENV=local
export EDITOR=vim
export REACT_EDITOR=code

# Mac only
# -----------------------------------------------------------------------------
if is_mac; then
	# Paths
	export DEVELOPMENTPATH="$HOME/dev"
	export SITESPATH="$HOME/www"
	export GOLANGPATH="$DEVELOPMENTPATH/go"
	export GOPATH="$HOME/go"
	export DOTFILESPATH="$DEVELOPMENTPATH/dotfiles" # Company version
	export PYTHONPATH="$DEVELOPMENTPATH"
	export DEVOPSPATH="$DEVELOPMENTPATH/devops"
	export ANSIBLEPATH="$DEVOPSPATH/ansible"

	# Misc.
	export ANDROID_HOME="$HOME/Library/Android/sdk/"
	export PATH="$DOTFILESPATH/bin:$GOPATH/bin:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:/usr/local/sbin:$DEVOPSPATH/bin:~/.fastlane/bin":$PATH

	source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc'
	source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc'

	# Incremental searching with up and down, e.g. type 'ssh <up>' to get the
	# last 'ssh' command used.
	"\e[A": history-search-backward
	"\e[B": history-search-forward

	# Use curl from Homebrew.
	#export PATH="/usr/local/opt/curl/bin:$PATH"

	# Go to www folder if starting in the home directory. If starting somewhere
	# else, it probably means the shell was invoked there and the path shouldn't
	# be overridden.
	current=$(pwd)
	if [ "$current" == "$HOME" ]; then
		cd "$SITESPATH"
	fi
	unset current

# Windows only
# -----------------------------------------------------------------------------
elif is_windows; then
	# Paths
	export DEVELOPMENTPATH="/c/_/dev"
	export SITESPATH="$DEVELOPMENTPATH/www"
	export GOLANGPATH="$DEVELOPMENTPATH/go"
	export GOPATH="$HOME/go"

	# The Git and MSYS versions of less do not correctly interpret colors on
	# Windows: https://github.com/sharkdp/bat#using-bat-on-windows
	export BAT_PAGER=""
fi

# Start SSH agent
# -----------------------------------------------------------------------------
ssh_init
