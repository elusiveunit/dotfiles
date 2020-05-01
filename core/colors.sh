# Reset to default
color_reset="\e[0m"

# Regular
black="\e[0;30m"
red="\e[0;31m"
green="\e[0;32m"
yellow="\e[0;33m"
blue="\e[0;34m"
purple="\e[0;35m"
cyan="\e[0;36m"
white="\e[0;37m"

# Bright
Bblack="\e[1;30m"
Bred="\e[1;31m"
Bgreen="\e[1;32m"
Byellow="\e[1;33m"
Bblue="\e[1;34m"
Bpurple="\e[1;35m"
Bcyan="\e[1;36m"
Bwhite="\e[1;37m"

# Underline
Ublack="\e[4;30m"
Ured="\e[4;31m"
Ugreen="\e[4;32m"
Uyellow="\e[4;33m"
Ublue="\e[4;34m"
Upurple="\e[4;35m"
Ucyan="\e[4;36m"
Uwhite="\e[4;37m"

# Background
OnBlack="\e[40m"
OnRed="\e[30;41m"
OnGreen="\e[30;42m"
OnYellow="\e[30;43m"
OnBlue="\e[30;44m"
OnPurple="\e[30;45m"
OnCyan="\e[30;46m"
OnWhite="\e[30;47m"

# High Intensity
Iblack="\e[0;90m"
Ired="\e[0;91m"
Igreen="\e[0;92m"
Iyellow="\e[0;93m"
Iblue="\e[0;94m"
Ipurple="\e[0;95m"
Icyan="\e[0;96m"
Iwhite="\e[0;97m"

# Bright High Intensity
BIblack="\e[1;90m"
BIred="\e[1;91m"
BIgreen="\e[1;92m"
BIyellow="\e[1;93m"
BIblue="\e[1;94m"
BIpurple="\e[1;95m"
BIcyan="\e[1;96m"
BIwhite="\e[1;97m"

# High Intensity Backgrounds
IOnBlack="\e[0;30;100m"
IOnRed="\e[0;37;101m"
IOnGreen="\e[0;1;37;102m"
IOnYellow="\e[0;1;37;103m"
IOnBlue="\e[0;1;37;104m"
IOnPurple="\e[0;1;37;105m"
IOnCyan="\e[0;1;37;106m"
IOnWhite="\e[0;30;107m"

# Print colored messages
# -----------------------------------------------------------------------------
print_red() { printf "${red}%s${color_reset}\n" "$1"; }
print_green() { printf "${green}%s${color_reset}\n" "$1"; }
print_yellow() { printf "${yellow}%s${color_reset}\n" "$1"; }
print_blue() { printf "${blue}%s${color_reset}\n" "$1"; }
print_purple() { printf "${purple}%s${color_reset}\n" "$1"; }
print_cyan() { printf "${cyan}%s${color_reset}\n" "$1"; }

# Display available colors
# -----------------------------------------------------------------------------
color_list() {
	echo # Newline
	echo -e "${color_reset}Regular\tBright"
	echo -e "-------\t-------"
	echo -e "${white}White\t${Bwhite}White"
	echo -e "${black}Black\t${Bblack}Black"
	echo -e "${blue}Blue\t${Bblue}Blue"
	echo -e "${green}Green\t${Bgreen}Green"
	echo -e "${cyan}Cyan\t${Bcyan}Cyan"
	echo -e "${red}Red\t${Bred}Red"
	echo -e "${purple}Purple\t${Bpurple}Purple"
	echo -e "${yellow}Yellow\t${Byellow}Yellow"
}

# Display all the above colors
# -----------------------------------------------------------------------------
color_list_full() {
	local output="
Regular
--------------------------
${black}black
${red}red
${green}green
${yellow}yellow
${blue}blue
${purple}purple
${cyan}cyan
${white}white

${color_reset}Bright
--------------------------
${Bblack}Bblack
${Bred}Bred
${Bgreen}Bgreen
${Byellow}Byellow
${Bblue}Bblue
${Bpurple}Bpurple
${Bcyan}Bcyan
${Bwhite}Bwhite

${color_reset}Underline
--------------------------
${Ublack}Ublack
${Ured}Ured
${Ugreen}Ugreen
${Uyellow}Uyellow
${Ublue}Ublue
${Upurple}Upurple
${Ucyan}Ucyan
${Uwhite}Uwhite

${color_reset}Background
--------------------------
${OnBlack}OnBlack${color_reset}
${OnRed}OnRed${color_reset}
${OnGreen}OnGreen${color_reset}
${OnYellow}OnYellow${color_reset}
${OnBlue}OnBlue${color_reset}
${OnPurple}OnPurple${color_reset}
${OnCyan}OnCyan${color_reset}
${OnWhite}OnWhite${color_reset}

${color_reset}High Intensity
--------------------------
${Iblack}Iblack
${Ired}Ired
${Igreen}Igreen
${Iyellow}Iyellow
${Iblue}Iblue
${Ipurple}Ipurple
${Icyan}Icyan
${Iwhite}Iwhite

${color_reset}Bright High Intensity
--------------------------
${BIblack}BIblack
${BIred}BIred
${BIgreen}BIgreen
${BIyellow}BIyellow
${BIblue}BIblue
${BIpurple}BIpurple
${BIcyan}BIcyan
${BIwhite}BIwhite

${color_reset}High Intensity Backgrounds
--------------------------
${IOnBlack}IOnBlack${color_reset}
${IOnRed}IOnRed${color_reset}
${IOnGreen}IOnGreen${color_reset}
${IOnYellow}IOnYellow${color_reset}
${IOnBlue}IOnBlue${color_reset}
${IOnPurple}IOnPurple${color_reset}
${IOnCyan}IOnCyan${color_reset}
${IOnWhite}IOnWhite${color_reset}
"

	printf "$output"
}

# Display tables of color options
# http://misc.flogisoft.com/bash/tip_colors_and_formatting
# -----------------------------------------------------------------------------
color_table() {
	for clbg in {40..47} {100..107} 49; do
		# Foreground
		for clfg in {30..37} {90..97} 39; do
			# Formatting
			for attr in 0 1 2 4 5 7; do
				# Print the result
				echo -en "\e[${attr};${clbg};${clfg}m ^[${attr};${clbg};${clfg}m \e[0m"
			done

			echo # Newline
		done
	done
}
