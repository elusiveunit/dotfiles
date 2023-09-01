# Platform, keep in sync with _functions/_base.sh
CURRENT_PLATFORM=$( uname | tr '[:upper:]' '[:lower:]' )
is_windows() { case "$CURRENT_PLATFORM" in msys*|cygwin*) true ;; *) false ;; esac }
is_mac() { case "$CURRENT_PLATFORM" in darwin*) true ;; *) false ;; esac }

if is_mac; then
	[ -f /usr/local/bin/brew ] && BREW_PATH='/usr/local/bin/brew'
	[ -f /opt/homebrew/bin/brew ] && BREW_PATH='/opt/homebrew/bin/brew'
	eval "$($BREW_PATH shellenv bash)"
	DOTFILES_DIR="$(dirname "$(greadlink -f "${BASH_SOURCE[0]}")")"
else
	DOTFILES_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
fi

# Set core paths
if is_mac; then
	export DEVELOPMENTPATH="$HOME/dev"
	export SITESPATH="$HOME/www"
	export GOLANGPATH="$DEVELOPMENTPATH/go"
	export GOPATH="$HOME/go"
	export DOTFILESPATH="$DEVELOPMENTPATH/dotfiles" # Company version
	export PYTHONPATH="$DEVELOPMENTPATH"
	export DEVOPSPATH="$DEVELOPMENTPATH/devops"
	export ANSIBLEPATH="$DEVOPSPATH/ansible"
elif is_windows; then
	export DEVELOPMENTPATH="/c/_/dev"
	export SITESPATH="$DEVELOPMENTPATH/www"
	export GOLANGPATH="$DEVELOPMENTPATH/go"
	export GOPATH="$HOME/go"
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
		[ -r "${file}.sh" ] && [ -f "${file}.sh" ] && source "${file}.sh"
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

# cd when running a directory as a command. Also works with globs, e.g. `**/baz`
# will enter `./foo/bar/baz`.
# shopt -s autocd

# Autocorrect typos in path names when using `cd`.
# shopt -s cdspell

# Enable recursive globbing (`**` matching all files and zero or more
# directories and subdirectories).
shopt -s globstar

# Case-insensitive globbing (used in pathname expansion).
shopt -s nocaseglob

# Don't autocomplete an empty prompt since it takes a long time.
shopt -s no_empty_cmd_completion

# Increase Bash history size, default is 500.
export HISTSIZE=5000
export HISTFILESIZE="${HISTSIZE}"
# Prevent duplicates in command history.
export HISTCONTROL=ignoredups:erasedups
# Append to the Bash history file, rather than overwriting it.
shopt -s histappend

# Prefer US English and UTF-8.
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Open file selected in fzf with VS Code.
export FZF_DEFAULT_OPTS="--bind='ctrl-o:execute(code {})+abort'"

# Misc.
export ENV=local
export EDITOR=vim
export REACT_EDITOR=code

export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# Increase from default 15 seconds.
export PIP_DEFAULT_TIMEOUT=30

# Mac only
# -----------------------------------------------------------------------------
if is_mac; then
	# Misc.
	export ANDROID_HOME="$HOME/Library/Android/sdk/"
	export PATH="$GOPATH/bin:$DEVELOPMENTPATH/flutter/bin:$HOME/.pub-cache/bin:$HOME/.local/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:/usr/local/sbin:~/.fastlane/bin:~/.local/bin:${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

	source "$HOMEBREW_PREFIX/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"
	source "$HOMEBREW_PREFIX/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"

	# Load nvm
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

	# Completion.
	# Generate manage completion on every start to keep it updated.
	# manage completion bash > /usr/local/etc/bash_completion.d/manage_bash_completion.sh
	[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
	source "$DOTFILES_DIR"/core/aliases_completion.sh

	# Use curl from Homebrew.
	export PATH="$HOMEBREW_PREFIX/opt/curl/bin:$PATH"

	# Add pyenv shim to PATH. SHOULD ALWAYS BE BELOW OTHER PATH CONFIG.
	eval "$(pyenv init -)"

	# Go to www folder if starting in the home directory. If starting somewhere
	# else, it probably means the shell was invoked there and the path shouldn't
	# be overridden.
	current_location=$(pwd)
	if [ "$current_location" == "$HOME" ]; then
		cd "$SITESPATH"
	fi
	unset current_location

# Windows only
# -----------------------------------------------------------------------------
elif is_windows; then
	# The Git and MSYS versions of less do not correctly interpret colors on
	# Windows: https://github.com/sharkdp/bat#using-bat-on-windows
	export BAT_PAGER=""
fi

# Start SSH agent
# -----------------------------------------------------------------------------
ssh_init
