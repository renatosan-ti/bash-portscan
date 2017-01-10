#!/bin/sh -

# Simple Bash TCP Port Scan
# -------------------------
# Author...: Renato Santos
# Site.....: http://www.p0ng.com.br

# This is a very simple implementation
# to show some useful thins about
# TCP connection using Bash purely

# TODO:
#	multiple IPs

# Adjust timeout
# --------------
timeout=0.01s

# /etc/services file
servicesFile="/etc/services"

# Colors
WHITE="\e[1;37m"
BOLD="\e[0;1m"
YELLOW="\e[0;33m"
RED="\e[0;31m"
PURPLE="\e[0;35m"
BLUE="\e[0;34m"
LBLUE="\e[1;34m"
CYAN="\e[0;36m"
LCYAN="\e[1;36m"
NO_COLOUR="\e[0m"

version="0.2"
verbose=0

showBanner() {
	printf "${WHITE}Bash TCP Port Scan v$version\n${BLUE}=======================${NO_COLOUR}\n\n"
}

usage() {
	showBanner
	printf "${WHITE}Usage${BLUE}:${NO_COLOUR} sh ${0##*/} [-v] <IP> <PORT(s)>\n\n\t-v\t${WHITE}Verbose mode${NO_COLOUR} (show filtered ports)\n\t-h\t${WHITE}This help${NO_COLOUR}\n\n${WHITE}Example${BLUE}:${NO_COLOUR}\n\n\t$ sh ${0##*/} 192.168.1.10 1000-2000\n\t$ sh ${0##*/} 192.168.1.2 21,22,23,25,80\n\t$ sh ${0##*/} 192.168.25.1 23 80 113\n\n"
	exit
}

msg() {
	case $1 in
		info) prefix="${LBLUE}[+]${NO_COLOUR}" ;;
		error) prefix="${RED}[-]${NO_COLOUR}" ;;
		alert) prefix="${YELLOW}[!]${NO_COLOUR}" ;;
	esac
	printf "$prefix $2\n"
}

showResults() {
    for i in "${discoveredPorts[@]}"; do
        if [[ $i =~ "filtered" ]]; then
            msg alert "$i"
        elif [[ $i =~ "open" ]]; then
            msg info "$i"
        fi
    done
}

# The idea is to make a sub-process to end the execution of the command.
# It is necessary when the port is closed or filtered.

# Open port: the command runs smoothly (return code 0)
# Closed port: the command must be terminated (return code 1)
# Filtered port: the command must be terminated (return code 143)

checkPort() {
	for port in ${ports[@]}; do
		trap 'msg error "Canceled by the user (CTRL+C)\n"; exit 1' SIGINT
		(pid=$BASHPID; (sleep $timeout; kill $pid) & echo >/dev/tcp/$1/$port)
		case $? in
			0)
				service=$(grep -w $port/tcp $servicesFile | head -n1 | cut -d' ' -f1)
				if [[ -z $service ]]; then
					service="unknown"
				fi
				discoveredPorts+=("$port open ($service)")
			;;
			143)
				if ((verbose)); then
					discoveredPorts+=("$port filtered")
				fi
			;;
		esac
	done
	showResults
}

# ---- #
# Main #
# -----#

if [[ $# -eq 0 ]]; then
	usage
	exit 0
fi

while getopts ":vh" option; do
	case "$option" in
		v) verbose=1 ;;
		h) usage ;;
		\?) msg error "Invalid option: ${WHITE}-$OPTARG${NO_COLOUR}"; exit 1 ;;
	esac
done

shift "$((OPTIND-1))"

# First argument
IP=$1
# From second to last argument
PORT="${@:2:${#@}}"

# Small structure to define if ports will be
# a range (1-2000) or sequenced values (23, 25, 80)
if [[ $PORT =~ "-" ]]; then
    ports=(${ports[@]} `seq $(echo ${PORT//-/ })`)
elif [[ $PORT =~ "," ]]; then
    ports=(${ports[@]} $(echo ${PORT//,/ }))
else
    ports=(${ports[@]} $(seq $PORT))
fi

showBanner
msg info "Start scanning - $IP..."
checkPort $IP 2>/dev/null
msg info "Done."
