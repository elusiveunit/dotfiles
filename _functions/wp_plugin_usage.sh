#!/usr/bin/env bash
# Check on which sites a WordPress plugin is used

if [ -f "${0%/*}/_base.sh" ]; then source "${0%/*}/_base.sh"; else echo "No _base"; exit; fi

print_plain=false

# Show help message
# -----------------------------------------------------------------------------
show_help() {
	local file_name=$(basename ${BASH_SOURCE[0]})
	local usage=$"Check on which sites WordPress plugins are used

Usage: $file_name [-args] <plugin_dir_name>

       -a  Check all plugins on all sites. Ignores plugin_dir_name.
       -h  Display this help message
       -p  Plain text (no colors) output. Use if saving output to a file."

	printf "%s\n" "$usage"
	exit
}

# Get an array of plugins from app.toml.
# Usage: plugins=( $(get_conf_plugins "path/to/app.toml") )
# -----------------------------------------------------------------------------
get_conf_plugins() {

	# Extract the array by translating newlines to spaces and
	# grepping for plugins = [...]
	arr=$(tr '\n' ' ' < "$1" | egrep -o "plugins ?= ?[^]]+\]")

	# Remove whitespace, quotes and square brackets
	arr=$(echo "$arr" | tr -d [[:space:]]\"\'\[)

	# Remove leading 'plugins='
	arr=${arr#"plugins"=}

	# Replace commas with spaces and wrap in brackets to create an array
	arr=(${arr//,/ })

	# Output, call in subshell to simulate a return
	echo "${arr[@]}"
}

# Search for the specified plugin in every app.toml
# -----------------------------------------------------------------------------
search_plugins() {
	search_for="$1"
	matches=()

	echo # Newline
	msg="Searching for $search_for..."
	[ "$print_plain" = true ] && echo "$msg" || print_blue "$msg"

	for dir in "${SITESPATH}/"*/; do

		# Symlink
		[ -L "${dir%/}" ] && continue;

		site=${dir#${SITESPATH}/}
		site=${site%/}

		# A local site that contains all plugins for update checks, ignore
		[ "$site" = "wp-updates.test" ] && continue;

		conf_path="${dir}config/app.toml"

		# app.toml exists and is readable
		[ -f "$conf_path" ] && [ -r "$conf_path" ] || continue;

		# grep for kind wordpress, will be empty if not found
		is_wordpress=$(tr '\n' ' ' < "$conf_path" | egrep -o 'kind ?= ?"wordpress"')
		[ "$is_wordpress" ] || continue;

		plugins=( $(get_conf_plugins "$conf_path") )

		if [ "${#plugins[@]}" -gt 0 ]; then
			for plug in "${plugins[@]}"; do
				if [ "$plug" == "$search_for" ]; then
					matches+=("$site")
				fi
			done;
		fi
	done

	match_count="${#matches[@]}"

	if [ "$match_count" -gt 0 ]; then
		[ "$match_count" -eq 1 ] && site_string="one site" || site_string="$match_count sites"
		msg="$search_for is used on $site_string:"
		[ "$print_plain" = true ] && echo "$msg" || print_green "$msg"
		printf -- '   %s\n' "${matches[@]}"
	else
		msg="$search_for isn't used anywhere."
		[ "$print_plain" = true ] && echo "$msg" || print_red "$msg"
	fi
}

# Search for all plugins in every site
# -----------------------------------------------------------------------------
search_all() {
	plugins_dir="${SITESPATH}/wordpress/plugins"
	#plugins=( "$plugins_dir"/* )
	plugins=($(ls "$plugins_dir"))
	plugins=( "${plugins[@]##*/}" )

	for plug in "${plugins[@]}"; do
		search_plugins "$plug"
	done
}

# Run script
# -----------------------------------------------------------------------------
init() {
	if [ -z "$1" ]; then
		show_help
	fi

	check_all=false

	# Check flags
	local OPTIND
	while getopts "ahp" opt; do
		case $opt in
			a) check_all=true
				;;
			h) show_help
				;;
			p) print_plain=true
				;;
		esac
	done
	shift $(( OPTIND - 1 ))

	if [ "$check_all" = true ]; then
		search_all
	else
		search_plugins "$1"
	fi
}

init "$@"
