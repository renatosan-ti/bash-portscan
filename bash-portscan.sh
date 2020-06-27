#!/usr/bin/env bash

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
timeout="0.01s"

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
NC="\e[0m"

version="0.5"
verbose="0"

show_banner()
{
	message="Bash TCP Port Scan v${version}"
	printf "${WHITE}%b\n" "${message}"
	printf "${BLUE}%0.0b=" $(seq 1 "${#message}")
	printf "\n\n${NC}"
}

show_usage() {
	show_banner
	printf "${WHITE}Usage${BLUE}:${NC} sh ${0##*/} [-v] <IP> <PORT(s)>\n\n\t-v\t${WHITE}Verbose mode${NC} (show filtered ports)\n\t-h\t${WHITE}This help${NC}\n\n${WHITE}Example${BLUE}:${NC}\n\n\t$ sh ${0##*/} 192.168.1.10 1000-2000\n\t$ sh ${0##*/} 192.168.1.2 21,22,23,25,80\n\t$ sh ${0##*/} 192.168.25.1 23,80,113\n\n"
	exit
}

msg() {
	case "${1}" in
		alert) printf "%b\n" "${YELLOW}[${WHITE}!${YELLOW}]${NC} ${@:2:${#@}}" ;;
		error) printf "%b\n" "${RED}[${WHITE}-${RED}]${NC} ${@:2:${#@}}" ;;
		info) printf "%b\n" "${LBLUE}[${WHITE}+${LBLUE}]${NC} ${@:2:${#@}}" ;;
	esac
}

show_results() {
	for i in "${discoveredPorts[@]}"; do
		if [[ "${i}" =~ "filtered" ]]; then
			msg alert "${i}"
		elif [[ "${i}" =~ "closed" ]]; then
			msg error "${i}"
		elif [[ "${i}" =~ "open" ]]; then
			msg info "${i}"
		fi
	done
}

# The idea is to make a sub-process to end the execution of the command.
# It is necessary when the port is closed or filtered.

# Open port: the command runs smoothly (return code 0)
# Closed port: the command must be terminated (return code 1)
# Filtered port: the command must be terminated (return code 143)

check_port() {
	# Text from http://www.madhur.co.in/blog/2011/09/18/filteredclosed.html

	# Open port (return code 0)
	# -------------------------
	# If you send a SYN to an open port, you would expect to receive SYN/ACK.

	# Closed port (return code 1)
	# ---------------------------
	# If you send a SYN to a closed port, it will respond back with a RST.

	# Filtered port (return code 143)
	# -------------------------------
	# Presumably, the host is behind some sort of firewall.
	# Here, the packet is simply dropped and you receive no response (not even a RST).

	for port in "${ports[@]}"; do
		trap 'echo; msg error "Canceled by the user (CTRL+C)"; exit 1' INT TSTP

		(pid="${BASHPID}"; (sleep "${timeout}"; kill "${pid}") & echo >/dev/tcp/"${1}"/"${port}")
		case "${?}" in
			0)
				service=$(grep -w -m 1 "${port}"/tcp "${servicesFile}" | cut -d' ' -f1)
				[[ -z "${service}" ]] && service="unknown"
					discoveredPorts+=("${port} open ${BOLD}(${service})${NC}")
				;;
			1) ((verbose)) && discoveredPorts+=("${port} closed") ;;
			143) ((verbose)) && discoveredPorts+=("${port} filtered") ;;
		esac
	done
	show_results
}

# ---- #
# Main #
# -----#

[[ $# -eq 0 ]] && { show_usage; exit 0; }

while getopts ":vh" option; do
	case "${option}" in
		v) verbose="1" ;;
		h) show_usage ;;
		\?) msg error "Invalid option: ${WHITE}-$OPTARG${NC}"; exit 1 ;;
	esac
done

shift "$((OPTIND-1))"

# First argument
IP="${1}"
# From second to last argument
PORT="${@:2:${#@}}"
PORT="${PORT:-1-1000}"

# Small structure to define if ports will be
# a range (1-2000), sequenced values (23, 25, 80)
# or specific port (80)
if [[ "${PORT}" =~ "-" ]]; then
	ports=("${ports[@]}" $(seq $(echo "${PORT//-/ }")))
elif [[ "${PORT}" =~ "," ]]; then
	ports=("${ports[@]}" $(echo "${PORT//,/ }"))
else
	ports=("${ports[@]}" $(echo "${PORT}"))
fi

show_banner
msg info "Start scanning: ${IP} / ${PORT}"
check_port ${IP} 2>/dev/null
msg info "Done."
