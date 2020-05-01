#!/usr/bin/env bash
# Create a zip file with changed files between two commits

if [ -f "${0%/*}/_base.sh" ]; then source "${0%/*}/_base.sh"; else echo "No _base"; exit; fi

# Show help message
# -----------------------------------------------------------------------------
show_help() {
	local file_name=$(basename ${BASH_SOURCE[0]})
	local usage=$"Create a zip file with changed files between commits

Usage: $file_name <from-sha> [to-sha]

       If to-sha is not specified, it defaults to HEAD"

	printf "%s\n" "$usage"
	exit
}

# Create diff archive
# -----------------------------------------------------------------------------
make_diff() {
	local from=$1
	local to="HEAD"

	if [ -n "$2" ]; then
		to=$2
	fi

	git archive -o diff.zip HEAD $(git diff-tree -r --name-only $from^ $to)
}

# Run script
# -----------------------------------------------------------------------------
init() {

	if [ -z "$1" ]; then
		show_help
	fi

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

	make_diff "$@"
}

init "$@"
