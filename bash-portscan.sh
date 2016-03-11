#!/bin/sh

# Simple Bash TCP Port Scan
# -------------------------
# By: Renato Santos
# http://www.p0ng.com.br

# This is a very simple implementation 
# to show some useful thins about
# TCP connection using Bash purely

# TODO: 
#	multiple IPs
#	quiet / verbose mode

# Adjust timeout
# --------------
timeout=0.01s

# ---------- #
# Begin code #
# ---------- #

# First argument
IP=$1
# From second to last argument
PORT="${@:2:${#@}}"

# /etc/services file
servFile="/etc/services"

# Small structure to define if ports will be 
# a range (1-2000) or sequenced values (23, 25, 80)
if [[ $PORT =~ "-" ]]; then
	ports=(${ports[@]} `seq $(echo $PORT | sed 's/-/ /g')`)
elif [[ $PORT =~ "," ]]; then
	ports=(${ports[@]} $(echo $PORT | sed 's/\,/ /g'))
else
	ports=(${ports[@]} $(seq $PORT))
fi

usage() {
	printf "Simple Bash TCP Port Scan\nby Renato Santos\nhttp://www.p0ng.com.br\n\nUsage: $0 <IP> <port(s)>\n\nExample:\n\tsh $0 192.168.1.10 1000-2000\n\tsh $0 192.168.1.2 21,22,23,25,80\n\tsh $0 192.168.25.1 23 80 113\n\n"
	exit
}

msg() {
	case $1 in
		info) prefix="[+]" ;;			
		error) prefix="[-]" ;;
		alert) prefix="[!]" ;;
	esac
	
	printf "$prefix $2\n"

# The idea is to make a sub-process to end the execution of the command. 
# It is necessary when the port is closed or filtered.

# Open port: the command runs smoothly (return code 0)
# Closed port: the command must be terminated (return code 1)
# Filtered port: the command must be terminated (return code 143)

chkPort() {
	for port in ${ports[@]}; do
		trap 'msg error "\n\n[-] Canceled by the user (CTRL+C)\n\n"; exit 0' SIGINT		
		(pid=$BASHPID; (sleep $timeout; kill $pid) & echo >/dev/tcp/$1/$port)
		case $? in
			0) 
				service=$(grep -w $port/tcp $servFile | cut -d' ' -f1)
				if [[ -z $service ]]; then
					service="unknown"
				fi
				msg info "$port open ($service)"
			;;
			1) 
				msg error "$port closed"
			;;
			# Future implementation: verbose / quiet mode
			#143) 
			#	msg alert "$port filtered"
			#;;
		esac
		
	done
}

# ---- #
# Main #
# -----#

if [[ $# -lt 2 ]]; then
	usage
fi

msg info "Start scanning - $IP..."
chkPort $IP 2>/dev/null
msg info "Done."
