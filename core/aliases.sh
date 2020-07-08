# NOTE! Aliases with bash completion are defined in a separate file.

# Navigation shortcuts
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="cd -"

alias dev="cd $DEVELOPMENTPATH"
alias gosrc="cd $DEVELOPMENTPATH/go/mindius"
alias temp="cd $HOME/temp"
alias projects="cd $HOME/projects"
alias web="cd $HOME/projects/web"
alias devops="cd $DEVOPSPATH"

# Command shortcuts
alias c="cls"
alias q="exit"
alias r="reload"
alias g="git"
alias gr="grunt"
alias nr="npm run"
alias please="sudo"

# Docker shortcuts
alias dc="docker-compose"
alias dcu="docker-compose up"
alias dcd="docker-compose down"
alias dcs="docker-compose stop"
alias dps="docker ps"
alias di="docker images"

# Google cloud shortcuts
alias kc="kubectl"
alias kcs="kubectl --namespace staging"
alias kcp="kubectl --namespace production"
alias kcaf="kubectl apply -f"

# Shell script and function shortcuts
alias gitma="git_merge_all"
alias gma="git_merge_all"
alias gitup="git_update_local"
alias gul="git_update_local"
alias gitbr="git_set_branches"
alias gitac="git_add_commit"
alias gitrel="git_release"
alias gitroot="git_to_root"

# Typos
alias cd..="cd .."
alias sl="ls"
alias grpe="grep"
alias gerp="grep"
alias gti="git"

# Force english git output
alias git="LANG=en_US git"

# Misc. utility stuff
alias myip="curl -s http://ip.mindius.se/text/"
alias rsync_s="rsync -avz -e 'ssh -o StrictHostKeyChecking=no'"
alias ping_ext="dig @8.8.8.8"

# Get week number
alias week="date +%V"

# Stopwatch
_timer_stop_key="Ctrl-D"
if is_windows; then _timer_stop_key="Ctrl-C"; fi
alias timer="echo 'Timer started. Stop with $_timer_stop_key.' && date && time cat && date"

# Proper git
alias wow="git status"
alias such="git"
alias very="git"
alias so="git"
alias much="git"

# Better listing formats
alias lsa="ls -AhlvF"
alias lss="ls -AhlvF | sort -k1 -r"
alias lsd="(ls -d1 */ | cut -f1 -d'/')"

# Improved commands. Some are defined only for Mac below.
# https://remysharp.com/2018/08/23/cli-improved
alias prw="fzf --preview 'bat --color \"always\" {}'"
alias cat="bat"

# Mac only
if is_mac; then
	alias ping="prettyping"
	alias prw="fzf --height 80% --preview 'if file -i {}|grep -q binary; then file -b {}; else bat --color \"always\" --line-range :40 {}; fi'"
	alias top="sudo htop"
	alias dun="ncdu --color dark -rr -x --exclude .git --exclude node_modules"
	alias help="tldr"

	alias count_open_files="lsof -d '^txt' | wc -l"

	alias openssl_brew="/usr/local/Cellar/openssl/1.0.2k/bin/openssl"
	alias gitinspector="export LC_ALL=en_US.UTF-8;export LANG=en_US.UTF-8;~/projects/gitinspector/gitinspector.py"
	alias tftp_server="ptftpd -D -v -p 6969 en0 tftp-test"

	# Recursively delete .DS_Store files
	alias dsstore="find . -name '*.DS_Store' -type f -ls -delete"

	# MacOS has a BSD ls with other options
	alias lsa="ls -AhlvFG"

	# Force git output in english
	alias git="LANG=en_US git"
fi

# Generate aliases for all _functions files
for func in "${DOTFILES_DIR}/_functions/"*; do

	# Trim path
	func_name=${func#$DOTFILES_DIR/_functions/}

	# Trim file extension
	func_name=${func_name%.sh}

	# Begins with underscore, skip
	[ "${func_name:0:1}" = "_" ] && continue;

	alias "$func_name"="$func"
done
