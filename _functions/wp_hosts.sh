#!/usr/bin/env bash
# Search for sites with a host different from the name

if [ -f "${0%/*}/_base.sh" ]; then source "${0%/*}/_base.sh"; else echo "No _base"; exit; fi

print_plain=false

# Show help message
# -----------------------------------------------------------------------------
show_help() {
	local file_name=$(basename ${BASH_SOURCE[0]})
	local usage=$"Search for sites with a host different from the name

Usage: $file_name [-args] <plugin_dir_name>

       -a  Check all plugins on all sites. Ignores plugin_dir_name.
       -h  Display this help message
       -p  Plain text (no colors) output. Use if saving output to a file."

	printf "%s\n" "$usage"
	exit
}

# Get a string value from app.toml.
# Usage: val=( $(get_conf_string "path/to/app.toml") )
# -----------------------------------------------------------------------------
get_conf_string() {
	conf_path="$1"
	conf_str="$2"

	# Extract the value; search for name = ...
	value=$(cat "$conf_path" | grep -Poz "$conf_str ?= ?[^\n]+")

	# Remove whitespace, quotes and square brackets
	value=$(echo "$value" | tr -d [[:space:]]\"\')

	# Remove leading 'name='
	value=${value#"$conf_str"=}

	# Output, since bash doesn't return data
	echo "$value"
}

# Search for the specified plugin in every app.toml
# -----------------------------------------------------------------------------
check_hosts() {
	matches=()

	echo # Newline
	msg="Checking hosts..."
	[ "$print_plain" = true ] && echo "$msg" || print_blue "$msg"

	for dir in "${SITESPATH}/"*/; do

		# Symlink
		[ -L "${dir%/}" ] && continue;

		site=${dir#$SITESPATH}
		site=${site%/}
		conf_path="${dir}config/app.toml"

		# app.toml exists and is readable
		[ -f "$conf_path" ] && [ -r "$conf_path" ] || continue;

		name=$(get_conf_string "$conf_path" name)
		host=$(get_conf_string "$conf_path" host)

		if [ "$name" != "$host" ]; then
			matches+=("$site")
		fi
	done

	match_count="${#matches[@]}"

	if [ "$match_count" -gt 0 ]; then
		msg="Sites with a host different from the name:"
		[ "$print_plain" = true ] && echo "$msg" || print_blue "$msg"
		printf -- '   %s\n' "${matches[@]}"
	else
		echo # Newline
		msg="All hosts are the same."
		[ "$print_plain" = true ] && echo "$msg" || print_blue "$msg"
	fi
}

# Run script
# -----------------------------------------------------------------------------
init() {

	# Check flags
	local OPTIND
	while getopts "hp" opt; do
		case $opt in
			h) show_help
				;;
			p) print_plain=true
				;;
		esac
	done
	shift $(( OPTIND - 1 ))

	check_hosts
}

init "$@"
