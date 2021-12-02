# =============================================================================
#  Internal
# =============================================================================

# Check if an array contains a value
# array_has "something" "${array[@]}"
# Returns 0 if value exists
# -----------------------------------------------------------------------------
array_has() {
	local e

	for e in "${@:2}"; do
		[[ "$e" = "$1" ]] && return 0;
	done;

	return 1;
}

# Output the openssl binary path
# Call in a subshell to simulate a function return value
# -----------------------------------------------------------------------------
openssl_path() {
	case "$OSTYPE" in
		darwin*)
			echo "/usr/local/Cellar/openssl/1.0.2k/bin/openssl"
			;;
		*)
			echo "openssl"
			;;
	esac
}

# Show start and end dates for a domain's https certificate
# -----------------------------------------------------------------------------
cert_dates() {
	if [ -z "$1" ]; then
		echo "Usage: $FUNCNAME example.com"
		return 1
	fi
	echo "echo | openssl s_client -connect "$1":443 -servername "$1" 2>/dev/null | openssl x509 -noout -dates"
	echo | openssl s_client -connect "$1":443 -servername "$1" 2>/dev/null | openssl x509 -noout -dates
}

# Add a bash alias that includes completion for the original command.
# Inspired by https://superuser.com/a/437508.
# -----------------------------------------------------------------------------
alias_with_completion() {
	if [ $# -lt 2 ]; then
		echo "Usage: alias_with_completion <alias> <command> [<alias content>]"
		echo "       alias_with_completion mn manage"
		echo "       alias_with_completion mnl manage \"manage -e local\""
		return 1
	fi

  local alias_name="$1"
  local command_name="$2"
  local alias_content="$3"
	if [ -z "$alias_content" ]; then
		alias_content="$command_name"
	fi

	alias "$alias_name"="$alias_content"

	local existing_completion=$(complete -p | grep "$command_name")
	if [ -n "$existing_completion" ]; then
		local completion_option=$(echo "$existing_completion" | sed -Ene 's/.* -o ([^ ]*).*/\1/p')
		if [ -z "$completion_option" ]; then
			completion_option="default"
		fi
		local completion_function=$(echo "$existing_completion" | sed -Ene 's/.* -F ([^ ]*).*/\1/p')
		local arg_count=($alias_content); arg_count=${#arg_count[@]}
		local wrapper_name="_alias_completion_${alias_name}"
		local new_function="${wrapper_name}() {
			(( COMP_CWORD += $arg_count ))
			COMP_WORDS=($alias_content \${COMP_WORDS[@]:1})
			(( COMP_POINT -= \${#COMP_LINE} ))
			COMP_LINE=\${COMP_LINE/$alias_name/$alias_content}
			(( COMP_POINT += \${#COMP_LINE} ))
			$completion_function
		}"
		eval "$new_function"
		complete -o "$completion_option" -F "$wrapper_name" "$alias_name"
	fi
}



# =============================================================================
#  Files and directories
# =============================================================================

# Create a new directory and enter it
# -----------------------------------------------------------------------------
mkd() {
	mkdir -p "$@" && cd "$@"
}

# Create a file and open it in Sublime Text (touch + edit)
# -----------------------------------------------------------------------------
ted() {
	touch "$@" && subl "$@"
}

# Create a .tar.gz archive, using zopfli, pigz or gzip for compression
# -----------------------------------------------------------------------------
pack() {
	if [ -z "$1" ]; then
		echo "Usage: $FUNCNAME <file-name.tar.gz> <contents>"
		return 1
	fi

	local tmpFile="${@%/}.tar"
	tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1

	size=$(
		stat -f"%z" "${tmpFile}" 2> /dev/null; # OS X 'stat'
		stat -c"%s" "${tmpFile}" 2> /dev/null # GNU 'stat'
	)

	local cmd=""
	if (( size < 52428800 )) && hash zopfli 2> /dev/null; then
		# the .tar file is smaller than 50 MB and Zopfli is available; use it
		cmd="zopfli"
	else
		if hash pigz 2> /dev/null; then
			cmd="pigz"
		else
			cmd="gzip"
		fi
	fi

	echo "Compressing .tar using \'${cmd}\'…"
	"${cmd}" -v "${tmpFile}" || return 1
	[ -f "${tmpFile}" ] && rm "${tmpFile}"
	echo "${tmpFile}.gz created successfully."
}

# Extract depending on file extension
# -----------------------------------------------------------------------------
extract() {
	if [ -f $1 ] ; then
		case $1 in
			*.tar.bz2)   tar xvjf $1     ;;
			*.tar.gz)    tar xvzf $1     ;;
			*.bz2)       bunzip2 $1      ;;
			*.rar)       unrar x $1      ;;
			*.gz)        gunzip $1       ;;
			*.tar)       tar xvf $1      ;;
			*.tbz2)      tar xvjf $1     ;;
			*.tgz)       tar xvzf $1     ;;
			*.zip)       unzip $1        ;;
			*.Z)         uncompress $1   ;;
			*.7z)        7z x $1         ;;
			*)           echo "'$1' cannot be extracted via >extract<" ;;
		esac
	else
		echo "'$1' is not a valid file!"
	fi
}

# Determine size of a file or total size of a directory
# -----------------------------------------------------------------------------
fs() {
	if du -b /dev/null > /dev/null 2>&1; then
		local arg=-sbh
	else
		local arg=-sh
	fi
	if [[ -n "$@" ]]; then
		du $arg -- "$@"
	else
		du $arg .[^.]* *
	fi
}

# Create a data URL from a file
# -----------------------------------------------------------------------------
dataurl() {
	echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Compare original and gzipped file size
# -----------------------------------------------------------------------------
gz() {
	local orig_bytes=$(wc -c < "$1")
	local gzip_bytes=$(gzip -c "$1" | wc -c)
	local ratio=$(echo "scale=1; $gzip_bytes * 100 / $orig_bytes" | bc -l)
	local orig_kb=$(echo "scale=1; $orig_bytes / 1024" | bc -l)
	local gzip_kb=$(echo "scale=1; $gzip_bytes / 1024" | bc -l)
	printf "orig: %.1f KB (%d bytes)\n" "$orig_kb" "$orig_bytes"
	printf "gzip: %.1f KB (%d bytes): %.1f%%\n" "$gzip_kb" "$gzip_bytes" "$ratio"
}

# 's' with no arguments opens the current directory in Sublime Text, otherwise
# opens the given location
# -----------------------------------------------------------------------------
s() {
	if [ $# -eq 0 ]; then
		subl .
	else
		subl "$@"
	fi
}

# 'o' with no arguments opens current directory, otherwise opens the given
# location
# -----------------------------------------------------------------------------
# Normalize `open` across Linux, macOS, and Windows.
if is_windows; then
	alias open='explorer.exe'
	# For WSL?
	# alias open='xdg-open'
fi
o() {
	if [ $# -eq 0 ]; then
		open .
	else
		open "$@"
	fi
}

# Go up X number of directories
# -----------------------------------------------------------------------------
up() {
	[ $1 -ge 0 2> /dev/null ] && x=$1 || x=1

	# Repeat '../' X number of times
	local cmd=$(eval "printf -- '../%.0s' {1..$x}")

	cd "$cmd"
}

# cd that replaces part of the current path
# -----------------------------------------------------------------------------
cdr() {
	if [ $# -lt 2 ]; then
		echo "Pass search and replace values (e.g. cdr one.com two.com)"
		return 1
	fi

	cd "${PWD/$1/$2}"
}

# Recursively change permissions on directories only
# -----------------------------------------------------------------------------
chmod_dirs() {

	# Less than two parameters
	if [ $# -lt 2 ]; then
		echo "Pass a directory path and a chmod value (e.g. `chmod_dirs uploads 775`)"
		return 1
	fi

	find "$1" -type d -print0 | xargs -0 sudo chmod "$2"
}
chmod_files() {

	# Less than two parameters
	if [ $# -lt 2 ]; then
		echo "Pass a directory path and a chmod value (e.g. `chmod_files uploads 664`)"
		return 1
	fi

	find "$1" -type f -print0 | xargs -0 sudo chmod "$2"
}

# Create a Windows symbolic link
#
# Usage: "win_link link destination"
#        link: the link to create, relative to the current working directory
#        destination: the real folder, relative to the created link
#
# Both link and destination can also be absolute. Absolute paths should use
# Windows style drive letters: "win_link C:/www/something C:/temp/folder"
# -----------------------------------------------------------------------------
win_link() {
	if [ $# -lt 2 ]; then
		print_red "Need two paths to link"
		return 1
	fi

	# Remove any previous link
	#if [ -d "$to" ] || [ -f "$to" ]; then
	#	rm "$to"
	#fi

	# Replace forward slashes with backslashes
	local to=${1//\//\\}
	local from=${2//\//\\}

	# Command to run. If the link doesn't end with a file extension pattern,
	# assume it's a directory and add the /D flag
	local cmd="cmd /c mklink"
	if [[ ! "$to" =~ \.[A-Za-z0-9]{1,4}$ ]]; then
		cmd="$cmd /D"
	fi

	# Save output from mklink
	local output=$($cmd "$to" "$from")

	local from_trim=${from//\.\.\\/} # Trim leading ..\

	if [[ "$output" == symbolisk* ]]; then
		printf "${green}[%s] ${cyan}%s${color_reset} > from > ${yellow}%s${color_reset}\n" "Link created" "$to" "$from_trim"
	else
		printf "${red}[%s] ${cyan}%s${color_reset} > from > ${yellow}%s${color_reset}\n" "Couldn't create link (?)" "$to" "$from"
	fi
}



# =============================================================================
#  Utilities
# =============================================================================

# Run Yeoman with color
# -----------------------------------------------------------------------------
yoc() {
	yo "$@" --color
}

# Clear the screen
# http://stackoverflow.com/a/5367075
# http://superuser.com/a/726295
# -----------------------------------------------------------------------------
cls() {
	if [ "$TERM_PROGRAM" == "iTerm.app" ]; then
		printf "\e]50;ClearScrollback\a"
	else
		printf "\033c"
	fi;
}

# Download a file
# -----------------------------------------------------------------------------
dlfile() {
	curl -O "$@"
}

# Download from all URLs listed in the passed text file
# -----------------------------------------------------------------------------
dllist() {
	#xargs -n 1 curl -O < "$@"
	wget -i "$@"
}

# Escape UTF-8 characters into their 3-byte format
# -----------------------------------------------------------------------------
escape() {
	printf "\\\x%s" $(printf "$@" | xxd -p -c1 -u)

	# print a newline unless we're piping the output to another program
	if [ -t 1 ]; then
		echo # newline
	fi
}

# Decode \x{ABCD}-style Unicode escape sequences
# -----------------------------------------------------------------------------
unidecode() {
	perl -e "binmode(STDOUT, ':utf8'); print \"$@\""

	# print a newline unless we're piping the output to another program
	if [ -t 1 ]; then
		echo # newline
	fi
}

# Get a character's Unicode code point
# -----------------------------------------------------------------------------
codepoint() {
	perl -e "use utf8; print sprintf('U+%04X', ord(\"$@\"))"

	# print a newline unless we're piping the output to another program
	if [ -t 1 ]; then
		echo # newline
	fi
}

# Install Grunt plugins and add them as devDependencies to package.json
# Usage: gi contrib-watch contrib-uglify zopfli
# -----------------------------------------------------------------------------
gi() {
	local IFS=,
	eval npm install --save-dev grunt-{"$*"}
}

# Kill all processes by name in Windows
# -----------------------------------------------------------------------------
winkill() {
	taskkill /f /im "$@"
}

# List all processes by name in Windows
# -----------------------------------------------------------------------------
winlist() {
	tasklist /fi "imagename eq $@"
}

# Reload the shell (i.e. invoke as a login shell)
# -----------------------------------------------------------------------------
reload() {
	exec $SHELL -l
}

# Flush DNS cache
# -----------------------------------------------------------------------------
flush_dns() {
	case "$OSTYPE" in
		darwin*)
			echo "Running 'sudo killall -HUP mDNSResponder'"
			sudo killall -HUP mDNSResponder
			;;
		"msys" | "cygwin")
			echo "Running 'ipconfig /flushdns'"
			ipconfig /flushdns
			;;
		*)
			echo "OS type '$OSTYPE' not handled" ;;
	esac
}

# From https://github.com/janmoesen/tilde
#
# Try to make sense of the date. It supports everything GNU date knows how to
# parse, as well as UNIX timestamps. It formats the given date using the
# default GNU date format, which you can override using "--format='%x %y %z'.
#
# Examples of input and output:
#
#   $ whenis 1234567890            # UNIX timestamps
#   Sat Feb 14 00:31:30 CET 2009
#
#   $ whenis +1 year -3 months     # relative dates
#   Fri Jul 20 21:51:27 CEST 2012
#
#   $ whenis 2011-10-09 08:07:06   # MySQL DATETIME strings
#   Sun Oct  9 08:07:06 CEST 2011
#
#   $ whenis 1979-10-14T12:00:00.001-04:00 # HTML5 global date and time
#   Sun Oct 14 17:00:00 CET 1979
#
#   $ TZ=America/Vancouver whenis # Current time in Vancouver
#   Thu Oct 20 13:04:20 PDT 2011
#
# For more info, check out http://kak.be/gnudateformats.
# -----------------------------------------------------------------------------
whenis() {
	local error='Unable to parse that using http://kak.be/gnudateformats';

	# Default GNU date format as seen in date.c from GNU coreutils.
	local format='%a %b %e %H:%M:%S %Z %Y';
	if [[ "$1" =~ ^--format= ]]; then
		format="${1#--format=}";
		shift;
	fi;

	# Concatenate all arguments as one string specifying the date.
	local date="$*";
	if [[ "$date"  =~ ^[[:space:]]*$ ]]; then
		date='now';
	elif [[ "$date"  =~ ^[0-9]{13}$ ]]; then
		# Cut the microseconds part.
		date="${date:0:10}";
	fi;

	if [[ "$OSTYPE" =~ ^darwin ]]; then
		# Use PHP on OS X, where "date" is not GNU's.
		php -r '
			error_reporting(-1);
			$format = $_SERVER["argv"][1];
			$date = $_SERVER["argv"][2];
			if (!is_numeric($date)) {
				$date = strtotime($date);
				if ($date === false) {
					fputs(STDERR, $_SERVER["argv"][3] . PHP_EOL);
					exit(1);
				}
			}
			echo strftime($format, $date), PHP_EOL;
		' -- "$format" "$date" "$error";
	else
		# Use GNU date in all other situations.
		[[ "$date" =~ ^[0-9]+$ ]] && date="@$date";
		date -d "$date" +"$format";
	fi;
}

# List files newer than a specific date
# -----------------------------------------------------------------------------
files_newer_than() {
	if [ "$OSTYPE" != "linux-gnu" ] || [ "$OSTYPE" != "cygwin" ]; then
		echo "Only Linux (and possibly Cygwin) for now"
		return 1
	fi

	if [ $# -lt 1 ]; then
		echo "Pass a date (probably in YYYY-MM-DD format)"
		return 1
	fi

	local newer_than=$(date -d "$1" +"%s")
	local newer_than_display=$(echo $newer_than | gawk '{print strftime("%Y-%m-%d %H:%M:%S", $0)}')
	echo "Newer than ${newer_than_display}:"

	IFS=$'\n';
	for f in $(find . -type f); do
		local filetime=$(stat -c %Y "$f")
		if [ "$filetime" -gt "$newer_than" ]; then
			local showtime=$(echo $filetime | gawk '{print strftime("%Y-%m-%d %H:%M:%S", $0)}')
			echo "${showtime}: ${f}"
		fi
	done
}

# rsync over SSH
# -----------------------------------------------------------------------------
rsync_ssh() {
	rsync -avz -e 'ssh -o StrictHostKeyChecking=no' "$@"
}

# Test server TLS
# -----------------------------------------------------------------------------
tls_test() {
	cmd=$(openssl_path)
	echo QUIT | "$cmd" s_client -connect "$@:443" -tls1_2 -tlsextdebug -status
}
ocsp_test() {
	cmd=$(openssl_path)
	output=$(echo QUIT | "$cmd" s_client -connect "$@:443" -tls1_2 -status 2> /dev/null | grep -A 17 'OCSP response:' | grep -B 17 'Next Update')
	output=${output:-'No OCSP response'}
	echo "$output"
}

# Docker shortcuts
# -----------------------------------------------------------------------------
docker_enter() {
	echo "docker exec -it $1 $2"
	docker exec -it "$1" "$2"
}
docker_enter_prod() {
	echo "kubectl --namespace production exec -it $1-0 -c $1-$2 $3"
	kubectl --namespace production exec -it "$1-0" -c "$1-$2" "$3"
}
deb() {
	docker_enter "$1" bash
}
des() {
	docker_enter "$1" sh
}
depb() {
	docker_enter_prod "$1" "$2" bash
}
deps() {
	docker_enter_prod "$1" "$2" sh
}
dcup() {
	current_path=$(pwd)
	# Does not start with sitespath or is sitespath exactly
	if [[ $current_path != $SITESPATH* ]] || [ $current_path == $SITESPATH ]; then
		echo "Not in an app"
		return
	fi
	current_path_parts=(${current_path//// })
	app_root_path=$(printf '/%s' "${current_path_parts[@]:0:4}")
	app_domain=$(basename "$app_root_path")
	app_name="${app_domain//./-}"
	(cd "$app_root_path" && docker compose --project-name "$app_name" up)
}

# Reload docker processes
# -----------------------------------------------------------------------------
reload_wp() {
	echo "docker kill -s USR2 wordpress"
	docker kill -s USR2 wordpress
}
reload_nginx() {
	echo "docker kill -s HUP nginx"
	docker kill -s HUP nginx
}
reload_sajty() {
	echo "docker kill -s USR2 sajty"
	docker kill -s USR2 sajty
}
reload_php() {
	echo "docker kill -s USR2 php"
	docker kill -s USR2 php
}
reload_nginx_sajty() {
	echo "docker kill -s HUP nginx-sajty"
	docker kill -s HUP nginx-sajty
}
reload_apache_sajty() {
	echo "docker exec -it apache-sajty apachectl -k graceful"
	docker exec -it apache-sajty apachectl -k graceful
}

# =============================================================================
#  Misc. local
# =============================================================================

# Update manually downloaded parts to the latest master versions
# -----------------------------------------------------------------------------
update_remote_scripts() {
	declare -A remote_scripts=(
		["$DOTFILES_DIR/core/z.sh"]="https://raw.githubusercontent.com/rupa/z/master/z.sh"
		["$DOTFILES_DIR/core/fzf-keybindings.sh"]="https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.bash"
		["$DOTFILES_DIR/_functions/prettyping.sh"]="https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping"
		["$DOTFILES_DIR/_functions/tldr.sh"]="https://raw.githubusercontent.com/raylee/tldr/master/tldr"
	)
	local cur_date=$(date +'%Y-%m-%d')
	for file_path in "${!remote_scripts[@]}"; do
		remote_path="${remote_scripts[$file_path]}"

		# Scripts in _functions probably have a shebang that should be first.
		if [[ $file_path != *"_functions"* ]]; then
			echo "# $remote_path" > "$file_path"
			echo "# Updated $cur_date" >> "$file_path"
			echo "# -----------------------------------------------------------------------------" >> "$file_path"
			echo "" >> "$file_path"
			curl -s "$remote_path" >> "$file_path"
		else
			curl -s "$remote_path" > "$file_path"
		fi
		print_green "Updated $file_path from latest master at $remote_path"
	done
}

www() {
	cd "$SITESPATH/${1}"
}

# Init pipenv with black
pinit() {
	pipenv install --dev
	black_path=$(pipenv run which black | tail -1)
	mkdir -p .vscode
	if [ ! -f .vscode/settings.json ]; then
		touch .vscode/settings.json
		echo "{" >> .vscode/settings.json
		echo "  \"python.formatting.blackPath\": \"$black_path\"" >> .vscode/settings.json
		echo "}" >> .vscode/settings.json
		echo "Created .vscode/settings.json"
	else
		echo ".vscode/settings.json already exists, manually add \"python.formatting.blackPath\": \"$black_path\" if it doesn't exist"
	fi
}
# Alias
black_init() {
	pinit
}

# Link/unlink dev js-common
link_js_common() {
	if [[ -L "node_modules/js-common" ]]; then
		echo "Already a symlink"
		return
	fi
	mv "node_modules/js-common" "node_modules/js-common-original"
	ln -s "$DEVELOPMENTPATH/js-common" "node_modules/js-common"
	echo "Linked node_modules/js-common"
}
unlink_js_common() {
	if [[ ! -L "node_modules/js-common" ]]; then
		echo "Not a symlink"
		return
	fi
	if [[ ! -d "node_modules/js-common-original" ]]; then
		echo "Missing a js-common-original"
		return
	fi
	unlink "node_modules/js-common"
	mv "node_modules/js-common-original" "node_modules/js-common"
	echo "Restored original node_modules/js-common"
}
unlink_all_js_common() {
	echo "Looking for js-common symlinks in $SITESPATH, this may take a minute or two..."
	local found=($(find -L "$SITESPATH" -samefile "$DEVELOPMENTPATH/js-common"))
	local trailing_sitespath="$SITESPATH/"
	if [ "${#found[@]}" -eq 0 ]; then
		echo "No symlinks found"
	else
		for found_path in "${found[@]}"; do
			unlink "$found_path"
			mv "$found_path-original" "$found_path"
			echo "Unlinked js-common at ${found_path/$trailing_sitespath/}"
		done
	fi
}

# Copy all folders from the current directory to the WordPress repo plugin
# folder. Deletes existing folders to make sure obsolete files are gone.
# -----------------------------------------------------------------------------
_wp_move_files() {
	files_path="$SITESPATH/wordpress/$1"

	if [ ! -d "$files_path" ]; then
		echo "$files_path doesn't exist"
		return 1
	fi

	for dir in */; do

		# Is a directory
		[ -d "${dir%/}" ] || continue;

		file_dest="$files_path/$dir"

		# Current version exists
		[ -d "$file_dest" ] || continue;

		echo # Newline
		echo "${dir%/}"

		rm -rf "$file_dest"
		cp -r "$dir" "$file_dest"
		print_green "Done"
	done

	# Output a dashed list for commit messages
	echo # Newline
	echo "Moved:"
	for dir in */; do
		[ -d "${dir%/}" ] || continue;
		file_dest="$files_path/$dir"
		[ -d "$file_dest" ] || continue;

		echo "- ${dir%/}"
	done
}
wp_move_plugins() {
	_wp_move_files "plugins"
}
wp_move_themes() {
	_wp_move_files "themes"
}

# SSH
# -----------------------------------------------------------------------------
ssh_init() {
	if is_mac; then
		ssh-add -K
	elif is_windows; then
		# https://help.github.com/en/github/authenticating-to-github/working-with-ssh-key-passphrases#auto-launching-ssh-agent-on-git-for-windows
		ssh_env=~/.ssh/agent.env

		ssh_agent_load_env () {
			test -f "$ssh_env" && . "$ssh_env" >| /dev/null
		}
		agent_start () {
			(umask 077; ssh-agent >| "$ssh_env")
			. "$ssh_env" >| /dev/null
		}

		ssh_agent_load_env

		# agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2= agent not running
		agent_run_state=$(ssh-add -l >| /dev/null 2>&1; echo $?)

		if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
			agent_start
			ssh-add
		elif [ "$SSH_AUTH_SOCK" ] && [ $agent_run_state = 1 ]; then
			ssh-add
		fi

		unset ssh_env
	fi
}



# =============================================================================
#  Git
# =============================================================================

# List custom git functionality
# -----------------------------------------------------------------------------
git_functions() {
	local funcs=$(declare -F)
	local aliases=$(git config --get-regexp '^alias\.')

	print_blue "Functions:"
	echo "$funcs" | while read line; do
		line=${line##declare -f }
		if [[ $line == "git_"* ]]; then
			echo "$line"
		fi
	done

	echo # Newline
	print_blue "Aliases:"
	echo "$aliases" | while read line; do
		line=${line##alias.}
		line=${line/ /  =  }
		echo "$line"
	done
}

# Move to the root of the current git project
# -----------------------------------------------------------------------------
git_to_root() {
	[ ! -z $(git rev-parse --show-cdup) ] && cd $(git rev-parse --show-cdup || pwd)
}

# Set filemode to false in repository config
# -----------------------------------------------------------------------------
git_filemode_false() {
	[ -d .git -a ! -g .git/config ] || return

	git config core.filemode false
}

# Add all files and commit with a message
# -----------------------------------------------------------------------------
git_add_commit() {
	if [ -z "$1" ]; then
		echo "Write a commit message."
		return 1
	fi

	git add --all
	git commit -m "$1"
}

# Add all files and commit with a message
# -----------------------------------------------------------------------------
git_rename_case() {
	# Less than two parameters
	if [ $# -lt 2 ]; then
		echo "Rename a folder in git, ${FUNCNAME[0]} <from> <to>."
		echo "Example: ${FUNCNAME[0]} Testing testing"
		return 1
	fi

	git mv "$1" "${1}TEMP" && git mv "${1}TEMP" "$2"
}

# Log folder names of updated plugins and themes.
# -----------------------------------------------------------------------------
git_log_wp() {
	changes=()
	current=""

	git status --porcelain | while read -r line; do
		path="${line#* }"
		path=(${path//\// })
		if [ "${path[0]}" = "plugins" ] && ! array_has "${path[1]}" "${changes[@]}"; then
			changes+=(${path[1]})
			current="${path[1]}"
			echo "$current"
		fi
	done

	#printf '%s\n' "${changes[@]}"
}
