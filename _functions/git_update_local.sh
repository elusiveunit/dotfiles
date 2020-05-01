#!/usr/bin/env bash
# Update (pull) all the local branches in the current git repo

if [ -f "${0%/*}/_base.sh" ]; then source "${0%/*}/_base.sh"; else echo "No _base"; exit; fi

rebase=false

# Show help message
# -----------------------------------------------------------------------------
show_help() {
	local file_name=$(basename ${BASH_SOURCE[0]})
	local usage=$"Update all the local branches in the current git repo.

Usage: $file_name [-args] [branches]

       Defaults to all local branches. Overwrite by passing branch names.

       -r  Use git pull --rebase, instead of default git pull --ff-only
       -h  Display this help message"

	printf "%s\n" "$usage"
	exit
}

# Pull all branches
# -----------------------------------------------------------------------------
update_local() {
	git fetch --prune --tags origin

	local revs=0
	local branches=($(git for-each-ref --format='%(refname:short)' refs/heads/))
	local base_branch="dev"

	# Set custom branches if any arguments were passed
	if [ $# -gt 0 ]; then
		branches=() # Empty the defaults

		for br in "$@"; do
			branches+=($br)
		done
	fi

	# Pull from all branches
	for br in "${branches[@]}"; do

		# rev-list lists commit objects, wc counts the number of lines and
		# sed trims whitespace
		revs=$(git rev-list $br...origin/$br | wc -l | sed -e 's/^ *//' -e 's/ *$//')

		if [ "$revs" -gt 0 ]; then
			print_yellow "$br has $revs revisions different from origin"

			git checkout $br

			if [ "$rebase" = true ]; then
				git pull --rebase origin $br
			else
				git pull --ff-only origin $br
			fi

		else
			print_green "$br has 0 revisions different from origin"
		fi
	done

	local current_branch=$(git rev-parse --abbrev-ref HEAD)
	if [ "$current_branch" != "$base_branch" ]; then
		echo # newline
		local base_branch_hash=$(git rev-parse --verify --quiet "$base_branch")
		if [ -z "$base_branch_hash" ]; then
			git checkout master
		else
			git checkout "$base_branch"
		fi
	fi
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
			r)
				rebase=true
				;;
		esac
	done
	shift $(( OPTIND - 1 ))

	update_local "$@"
}

init "$@"
