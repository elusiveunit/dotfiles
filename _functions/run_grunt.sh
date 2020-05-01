#!/usr/bin/env bash
# Run grunt from outside its location

if [ -f "${0%/*}/_base.sh" ]; then source "${0%/*}/_base.sh"; else echo "No _base"; exit; fi

# Run script
# -----------------------------------------------------------------------------
init() {
	[ ${BASH_VERSION%%[^0-9]*} -lt 4 ] && echo "Function requires Bash 4" && return 0

	local folders=("public_html" "wp-content" "themes")
	local search_path=""

	# Traverse directories
	for dir in "${folders[@]}"; do
		[ -d "$search_path$dir" ] && search_path+="$dir/"
	done

	# Don't search if run outside a project
	if [ -z "$search_path" ]; then
		print_red "No path to search"
		return 0
	fi

	local found=($(cd "$search_path" && find . -type f -name Gruntfile.js -not -path "*/node_modules/*"))
	local run_path="$search_path"

	# More than one grunt found, choose between them
	if [ "${#found[@]}" -gt 1 ]; then
		found_names=()
		declare -A found_names_map

		# Create clean theme names and paths
		for found_path in "${found[@]}"; do
			found_path=${found_path//\.\//} # Leading ./
			found_name=${found_path%%/*} # Remove everything after first slash

			found_names+=("$found_name")
			found_names_map["$found_name"]=${found_path%%Gruntfile.js} # Trailing Gruntfile.js
		done

		# Select between found
		PS3="Start which grunt? "
		select opt in "${found_names[@]}"; do
			if [ ${found_names_map[$opt]+isset} ]; then
				print_cyan "Trying to start grunt in $opt..."
				run_path+=${found_names_map[$opt]}
			else
				print_cyan "Aborting"
				run_path=""
			fi
			break
		done

	# A single grunt found
	elif [ "${#found[@]}" -eq 1 ]; then
		found_path=${found[0]}
		found_path=${found_path//\.\//} # Leading ./
		found_path=${found_path%%Gruntfile.js} # Trailing Gruntfile.js
		run_path+="$found_path"
	else
		print_cyan "No grunt found"
		return 0
	fi

	# Trim trailing slash
	run_path=${run_path%\/}

	com="grunt"
	if [ -n "$1" ]; then
		com="$com $1"
	fi

	if [ -d "$run_path" ] && [ ! -d "$run_path/node_modules" ]; then
		read -p "Grunt found, but no node_modules. Run npm install? " -n 1 reply
		case $reply in
			y|Y)
				echo # Newline
				print_green "Running npm install; run $BASH_SOURCE again when done to start grunt."
				echo # Newline
				(cd "$run_path" && npm install)
				;;
			*)
				echo # Newline
				print_cyan "Aborting"
				return 0
				;;
		esac
	elif [ -d "$run_path" ]; then
		(cd "$run_path" && eval $com)
	elif [ -n "$run_path" ]; then
		print_red "The computed path doesn't resolve:"
		echo "$run_path"
	fi
}

init "$@"
