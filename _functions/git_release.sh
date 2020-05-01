#!/usr/bin/env bash
# Put changes between branches dev and master into a "release" directory

if [ -f "${0%/*}/_base.sh" ]; then source "${0%/*}/_base.sh"; else echo "No _base"; exit; fi

merge=false

# Show help message
# -----------------------------------------------------------------------------
show_help() {
	local file_name=$(basename ${BASH_SOURCE[0]})
	local usage=$"Create a directory with changed files between dev and master.

Usage: $file_name [src SHA] [-args]

       Optionally pass a SHA1 to compare with the dev branch. Uses the current
       master commit by default.

       -h  Display this help message
       -m  Merge dev into master when done"

	printf "%s\n" "$usage"
	exit
}

# Create release directory with changes
# -----------------------------------------------------------------------------
make_release() {
	local original_location=$(pwd)
	local output=$(git rev-parse --show-toplevel)
	local src="master"

	output="$output/release"

	# Set source if any arguments were passed
	if [ $# -gt 0 ]; then
		src=$1
	fi

	# Go to root and export changes into the directory, if there is a diff
	git_to_root
	diff=$(git diff --name-only "${src}..dev")

	if [ ! "$diff" ]; then
		if [ "$src" == "master" ]; then
			echo "The diff was empty. Does master and dev point at the same commit?"
		else
			echo "The diff was empty"
		fi
		return 1
	fi

	rm -rf $output
	git archive -o diff.zip HEAD $(git diff --name-only --diff-filter=d "${src}..dev")

	# Empty diff
	if [ ! -s diff.zip ]; then
		print_red "Empty diff, aborting"
		rm -f diff.zip
		exit
	fi

	unzip diff.zip -d $output
	rm -f diff.zip

	# Merge dev into master
	if [ "$merge" = true ]; then
		git stash
		git checkout master
		git merge dev
		git checkout dev
		git stash pop
	fi

	# Go back to directory where function was called
	cd "$original_location"
}

# Run script
# -----------------------------------------------------------------------------
init() {

	# Check flags
	local OPTIND
	while getopts "hm" opt; do
		case $opt in
			h)
				show_help
				;;
			m)
				merge=true
				;;
		esac
	done
	shift $(( OPTIND - 1 ))

	make_release "$@"
}

init "$@"
