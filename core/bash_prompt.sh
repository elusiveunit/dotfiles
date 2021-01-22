# Shell prompt

# Git info
# -----------------------------------------------------------------------------
# The fast version shaves up to 120ms of the execution time, getting closer to
# the version below the more changes there are since it parses lines (about the
# same execution time with 1000 or so changes, slower than below with more).
# It also adds branch status.
# Inspired by https://github.com/dahlbyk/posh-git (at the time of writing,
# Get-GitStatus in src/GitUtils.ps1).
_prompt_git_status_fast() {
	local status_flags=''

	# Is the current directory a Git repository?
	if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" == 'true' ]; then

		# Is the current directory not .git?
		if [ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == 'false' ]; then

			# Ensure the index is up to date.
			# git update-index --really-refresh -q &>/dev/null

			local status_output=$(git status --porcelain --ignore-submodules --untracked-files=normal --branch)

			has_added_to_index=false
			has_unstaged_changes=false
			has_untracked_files=false
			has_removed_files=false
			while IFS= read -r line; do
				if [[ "$line" =~ ^[AM] ]]; then
					has_added_to_index=true
				fi
				if [[ "$line" =~ ^\ M ]]; then
					has_unstaged_changes=true
				fi
				if [[ "$line" =~ ^\?\? ]]; then
					has_untracked_files=true
				fi
				if [[ "$line" =~ ^\ ?D ]]; then
					has_removed_files=true
				fi
			done <<< "$status_output"

			if [ "$has_added_to_index" = true ]; then
				status_flags+='+'
			fi
			if [ "$has_removed_files" = true ]; then
				status_flags+='-'
			fi
			if [ "$has_unstaged_changes" = true ]; then
				status_flags+='!'
			fi
			if [ "$has_untracked_files" = true ]; then
				status_flags+='?'
			fi

			# Stashed changes
			if $(git rev-parse --verify refs/stash &>/dev/null); then
				status_flags+='$'
			fi

			# Commits ahead/behind
			local branch_flags=''
			local branch=${status_output%%$'\n'*}
			if [[ "$branch" =~ ahead\ ([[:digit:]]+) ]]; then
				branch_flags+="↑${BASH_REMATCH[1]}"
			fi
			if [[ "$branch" =~ behind\ ([[:digit:]]+) ]]; then
				branch_flags+="↓${BASH_REMATCH[1]}"
			fi
			if [ -n "${branch_flags}" ]; then
				[ -n "${status_flags}" ] && status_flags+=' '
				status_flags+="$branch_flags"
			fi

			# Add space and brackets it not null
			[ -n "${status_flags}" ] && status_flags=" [${status_flags}]"
		fi

		echo -e "${status_flags}"
	else
		return
	fi
}
_prompt_git_status() {
	local status_flags=''

	# Is the current directory a Git repository?
	if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" == 'true' ]; then

		# Is the current directory not .git?
		if [ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == 'false' ]; then

			# Ensure the index is up to date.
			# git update-index --really-refresh -q &>/dev/null

			# Check for uncommitted changes in the index.
			if ! $(git diff --quiet --ignore-submodules --cached); then
				status_flags+='+'
			fi

			# Check for unstaged changes.
			if ! $(git diff-files --quiet --ignore-submodules --); then
				status_flags+='!'
			fi

			# Check for untracked files.
			if [ -n "$(git ls-files --others --exclude-standard)" ]; then
				status_flags+='?'
			fi

			# Check for stashed files.
			if $(git rev-parse --verify refs/stash &>/dev/null); then
				status_flags+='$'
			fi

			# Add space and brackets it not null
			[ -n "${status_flags}" ] && status_flags=" [${status_flags}]"
		fi

		echo -e "${status_flags}"
	else
		return
	fi
}

# Execution time
# https://stackoverflow.com/q/1862510
# -----------------------------------------------------------------------------
function _prompt_timer_now {
	if is_mac; then
		gdate +%s%N
	else
		date +%s%N
	fi
}

function prompt_timer_start {
	_prompt_timer_start=${_prompt_timer_start:-$(_prompt_timer_now)}
}

function _prompt_timer_stop {
	local delta_ms=$((($(_prompt_timer_now) - $_prompt_timer_start) / 1000000))
	local delta_s=$((delta_ms / 1000))
	local ms=$((delta_ms % 1000))
	local s=$((delta_s % 60))
	local m=$(((delta_s / 60) % 60))
	local h=$((delta_s / 3600))

	prompt_timer_time=''
	if [ $h -gt 0 ]; then
		prompt_timer_time=${h}h${m}m
	elif [ $m -gt 0 ]; then
		prompt_timer_time=${m}m${s}s
	elif [ $s -gt 0 ]; then
		if [ $ms -ge 100 ]; then
			prompt_timer_time=${s}.$(($ms / 100))s
		else
			prompt_timer_time=${s}s
		fi
	elif [ $ms -gt 500 ]; then
		prompt_timer_time=${ms}ms
	# else
	# 	prompt_timer_time=${ms}ms
	fi

	unset _prompt_timer_start
}

# Set the prompt
# Uses unicode characters (→ ┌ └ ─) in hex escape sequences. In a UTF-8 enabled
# prompt, do 'echo → | hexdump -C' and use the first three pairs. Example:
# '00000000  e2 86 92 0a' becomes '\xe2\x86\x92'
# -----------------------------------------------------------------------------
set_bash_prompt() {
	local exit_code="$?" # Must be first

	_prompt_timer_stop

	# Set window/tab title
	if is_windows; then
		PS1='\[\033]0;$TITLEPREFIX:$PWD\007\]'
	else
		PS1='\033]0;${PWD/#$HOME/\~}\007'
	fi

	# ---------- Line 1 ----------
	PS1+="\[${white}\]\n"                    # newline, set white
	PS1+=$'\xe2\x94\x8c\xe2\x94\x80'         # ┌ and ─
	PS1+="\[${Bpurple}\]\u"                  # username
	# PS1+="\[${white}\] at "                  # at
	# PS1+="\[${Byellow}\]\h"                  # host
	PS1+="\[${white}\] in "                  # in
	PS1+="\[${Bgreen}\]\w"                   # working directory

	# Git
	if is_windows; then
		# From the default git bash prompt
		if test -z "$WINELOADERNOEXEC"; then
			GIT_EXEC_PATH="$(git --exec-path 2>/dev/null)"
			COMPLETION_PATH="${GIT_EXEC_PATH%/libexec/git-core}"
			COMPLETION_PATH="${COMPLETION_PATH%/lib/git-core}"
			COMPLETION_PATH="$COMPLETION_PATH/share/git/completion"
			if test -f "$COMPLETION_PATH/git-prompt.sh"; then
				. "$COMPLETION_PATH/git-completion.bash"
				. "$COMPLETION_PATH/git-prompt.sh"
				PS1+='`__git_ps1 "\[${white}\] on \[${Bcyan}\]%s"`' # git branch prefixed with 'on'
				PS1+="\[${Bred}\]"
				PS1+='`_prompt_git_status_fast`' # [git status]
			fi
		fi
	else
		PS1+="\$(__git_ps1 \"\[${white}\] on \[${Bcyan}\]%s\")"  # on git branch
		PS1+="\[${Bred}\]\$(_prompt_git_status_fast)"            # [git status]
	fi

	# Exit code if not 0
	if [ "$exit_code" != 0 ]; then
		PS1+=" \[${Byellow}\]$exit_code"
	fi

	# Execution time
	if [ "$prompt_timer_time" ]; then
		PS1+=" \[${Bblack}\]$prompt_timer_time"
	fi

	# ---------- Line 2 ----------
	PS1+="\[${white}\]\n"                # newline, set white
	PS1+=$'\xe2\x94\x94\xe2\x94\x80[\A]' # └ and ─, time in [HH:MM]
	PS1+=$'\xe2\x86\x92  '               # → and trailing space
	PS1+="\[${color_reset}\]"            # reset color

	export PS1;
}

# See above. Without git status.
# -----------------------------------------------------------------------------
set_simple_bash_prompt() {
	PS1="\[${white}\]\n"                                    # newline
	PS1+=$'\xe2\x94\x8c\xe2\x94\x80'                        # ┌ and ─
	PS1+="\[${purple}\]\u"                                  # username
	PS1+="\[${white}\] at "                                 # at
	PS1+="\[${Byellow}\]\h"                                 # host
	PS1+="\[${white}\] in "                                 # in
	PS1+="\[${Bgreen}\]\w"                                  # working directory
	PS1+="\$(__git_ps1 \"\[${white}\] on \[${cyan}\]%s\")"  # on git branch
	PS1+="\[${white}\]\n"                                   # newline, set white
	PS1+=$'\xe2\x94\x94\xe2\x94\x80[\A]'                    # └ and ─, time in [HH:MM]
	PS1+=$'\xe2\x86\x92 '                                   # →
	PS1+="\[${color_reset}\]"                               # reset color

	export PS1;
}

# Set the prompt title
# -----------------------------------------------------------------------------
# export PROMPT_COMMAND='echo -ne "\033]0;${PWD/#$HOME/\~}\007"'
