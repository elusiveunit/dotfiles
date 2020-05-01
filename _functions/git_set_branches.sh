#!/usr/bin/env bash
# Set up development branches locally and on remote
# Defaults to branch 'dev'

if [ -f "${0%/*}/_base.sh" ]; then source "${0%/*}/_base.sh"; else echo "No _base"; exit; fi

branches=( dev )

# Show help message
# -----------------------------------------------------------------------------
show_help() {
	local file_name=$(basename ${BASH_SOURCE[0]})
	local usage=$"Set up multiple development branches.

Usage: $file_name [-args] <branches>

       For example: $file_name -t foo bar

       Tries to sync the state between local and remote, by creating and/or
       tracking branches. Defaults to branch 'dev'.

       -p  Push existing local branches to remote
       -t  Set local branches to track remote
       -h  Display this help message"

	printf "%s\n" "$usage"
	exit
}

# Set custom branches if any arguments were passed
# -----------------------------------------------------------------------------
set_branches() {

	# Set custom branches if any arguments were passed
	if [ $# -gt 0 ]; then
		branches=() # Empty the defaults

		for br in "$@"; do
			branches+=($br)
		done
	fi
}

# Set branches depending on current state
# -----------------------------------------------------------------------------
sync_branches() {
	git fetch origin
	local remotes=($(git branch -r --no-color))

	# Handle every branch
	for br in "${branches[@]}"; do
		echo # newline
		print_cyan "Checking branch $br..."

		[ -n "$(git show-ref refs/heads/$br)" ] && local_exists=true || local_exists=false

		remote_exists=false
		[ ${#remotes[@]} -gt 0 ] && array_has "origin/$br" "${remotes[@]}" && remote_exists=true

		if [ "$local_exists" = false ] && [ "$remote_exists" = false ]; then
			git checkout -b $br
			git push --set-upstream origin $br

		elif [ "$local_exists" = true ] && [ "$remote_exists" = false ]; then
			git checkout $br
			git push --set-upstream origin $br

		elif [ "$local_exists" = false ] && [ "$remote_exists" = true ]; then
			git branch --track $br origin/$br

		elif [ "$local_exists" = true ] && [ "$remote_exists" = true ]; then
			git branch --set-upstream-to=origin/$br $br
		fi
	done

	# Branch dev exists and it's not the current. Super overkill to stop the
	# 'branch up to date' and 'already on dev' messages.
	[ -n "$(git show-ref refs/heads/dev)" ] && [ $(git rev-parse --abbrev-ref HEAD) != "dev" ] && git checkout dev
}

# Run script
# -----------------------------------------------------------------------------
init() {

	# Check flags
	local OPTIND
	while getopts "h" opt; do
		case $opt in
			h)
				show_help
				;;
		esac
	done
	shift $(( OPTIND - 1 ))

	set_branches "$@"
	sync_branches
}

init "$@"
