#!/usr/bin/env bash
# Merge git dev branch into all other branches

if [ -f "${0%/*}/_base.sh" ]; then source "${0%/*}/_base.sh"; else echo "No _base"; exit; fi

# Show help message
# -----------------------------------------------------------------------------
show_help() {
	local file_name=$(basename ${BASH_SOURCE[0]})
	local usage=$"Merge a branch into all other branches of the repository.

The source branch defaults to 'dev'.

Usage: $file_name [source branch] [-args]

       -h  Display this help message"

	printf "%s\n" "$usage"
	exit
}

# Merge dev into others
# -----------------------------------------------------------------------------
merge_all() {
	local source_branch=${1:-dev}
	local branches=($(git for-each-ref --format='%(refname:short)' refs/heads/))

	# Merge into all branches, except the source branch itself
	for br in "${branches[@]}"; do
		[ "$br" = "$source_branch" ] && continue;

		git checkout $br
		git merge "$source_branch"
	done

	git checkout "$source_branch"
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

	merge_all "$@"
}

init "$@"
