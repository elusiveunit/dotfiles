#!/usr/bin/env bash
# Create a directory with changed files between two WordPress versions.
# Make sure the 'wp_git' and 'output' variables point to proper locations.

if [ -f "${0%/*}/_base.sh" ]; then source "${0%/*}/_base.sh"; else echo "No _base"; exit; fi

# WordPress git repo path
wp_git="${SITESPATH}/wordpress-github"

# Output path
output_base="${SITESPATH}/wordpress-changes"

# Options
swedish=true
clear_content=true

# Show help message
# -----------------------------------------------------------------------------
show_help() {
	local file_name=$(basename ${BASH_SOURCE[0]})
	local usage=$"Create a directory with changed files between two WordPress versions.

Usage: $file_name <from/old-tag> <to/new-tag> [-args]
       For example: $file_name 3.8 3.8.1

       -c  Keep the wp-content directory
       -e  English version, doesn't add \$wp_local_package to version.php
       -h  Display this help message"

	printf "%s\n" "$usage"
	exit
}

# Make sure the required paths exist
# -----------------------------------------------------------------------------
check_paths() {
	if [ ! -d "$wp_git" ]; then
		print_red "Missing WordPress git directory at $wp_git"
		exit
	fi

	if [ ! -d "$output_base" ]; then
		print_cyan "Creating $output_base"
		mkdir -p "$output_base"
	fi
}

# Make the diff package
# -----------------------------------------------------------------------------
make_diff() {
	local original_location=$(pwd)
	local from="$1"
	local to="$2"
	local output="${output_base}/${from}-to-${to}" # Output path

	# Move to base WordPress git directory
	if [ "$PWD" != "$wp_git" ]; then
		cd $wp_git;
		sleep 1
	fi

	print_cyan "Updating WordPress from Github..."
	git fetch --tags
	git pull

	# Get commit hashes
	local old=$(git rev-list -1 $from)
	local new=$(git rev-list -1 $to)

	# Add Swedish to path
	if [ "$swedish" = true ]; then
		output="${output}-sv_SE"
	fi

	rm -rf $output
	git checkout tags/$to
	git archive -o diff.zip HEAD $(git diff-tree -r --name-only ${new}^ ${old})
	git checkout master
	unzip diff.zip -d $output
	rm -f diff.zip

	# Remove wp-content
	if [ "$clear_content" = true ]; then
		rm -rf "${output}/wp-content"
	fi

	# Set Swedish in version.php
	if [ "$swedish" = true ]; then
		printf "\n\$wp_local_package = 'sv_SE';\n" >> "${output}/wp-includes/version.php"
	fi

	# Go back to directory where function was called
	cd "$original_location"
}

# Run script
# -----------------------------------------------------------------------------
init() {

	echo "$BASH_SOURCE"

	# Less than two parameters
	if [ $# -lt 2 ]; then
		show_help
	fi

	local from="$1"
	local to="$2"

	# Remove the first two positional parameters (from and to) for getopts
	shift 2

	# Check flags
	local OPTIND
	while getopts "ceh" opt; do
		case $opt in
			c) clear_content=false
				;;
			e) swedish=false
				;;
			h) show_help
				;;
		esac
	done

	check_paths
	make_diff "$from" "$to"

	echo # Newline
	echo "Created diff at ${output_base}/${from}-to-${to}"
}

init "$@"
