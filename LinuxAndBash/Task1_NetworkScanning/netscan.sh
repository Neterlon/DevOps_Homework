#!/bin/bash

# Regular expression to check an ip address and a network mask entered by user
allowed_net="(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)){3}\/\b([0-9]|[12][0-9]|3[0-2])\b"
# Regular expression to check an ip address entered by user
allowed_ip="(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)){3}$"


# Function to display documentation about the script
function usage {
	cat <<EOF
	--all {target specification}
		Displays the IP addresses and symbolic names of all 
		hosts in the current subnet.
		Use an address of a network and network prefix separated
		by a slash in the target specification.
		Target specification example: 192.168.1.0/24 

	--target {target specification}
		Displays a list of open TCP ports of the selected host.
		Use an address of a host in the target specification.
		Target specification example : 192.168.1.100

EOF
}


# Function to scan a network for hosts
function scan_network {
	scanning_result=`nmap -sT $1`
	ip_addresses=`echo "$scanning_result" | awk '/Nmap scan report for/ {print $5}'`
	hosts=`echo "$scanning_result" | awk -F"[()]" '/MAC Address/ {print $2}'`

	for (( i = 1; i < `echo "$ip_addresses" | wc -l` + 1; i++ ))
	do
		echo `echo "$ip_addresses" | sed -n "${i}p"` --- `echo "$hosts" | sed -n "${i}p"`
	done
}


# Function to explore open host ports
function scan_ports {
	open_ports=`nmap -sT $1 | sed -n '/PORT/, /Nmap done/{/open/p}'`
	if [[ -z $open_ports ]]
	then 
		echo "This host hasn't open ports"
	else
		echo "Open ports of this host:"
		echo "$open_ports"
	fi
}


# Checking the availability of the package (nmap) and installing it
function install_nmap {
	nmap &> /dev/null
	if [[ $? -eq 127 ]] 
	then 
		read -p $'Nmap is not installed. Do you want to install it? (via Yum package manager) [y/n] \n>' install
		case $install in
			[yY][eE][sS]|[yY])
				echo "Nmap installation..."
				rpm -vhU https://nmap.org/dist/nmap-7.93-1.x86_64.rpm
				if [[ $? -eq 0 ]]
				then
					echo "Nmap was successfully installed!"
				else
					echo "Something went wrong!"
					exit 1
				fi
				;;
			[nN][oO]|[nN])
				echo "Script execution is not possible without nmap!"
				exit 1
				;;
			*) echo "Incorrect option!"
				exit 1
				;;
		esac
	fi
}



# Checking the entered options
if [[ $# -eq 0 ]] 
then
	echo "Use one of the options: --all, --target. Use --help to get more information."
elif [[ $# -eq 1 ]] && [[ $1 == "--help" ]]
then
	usage
elif [[ $# -eq 2 ]] && [[ $1 == "--all" ]]
then
	if [[ $2 =~ $allowed_net ]]
		then
			scan_network $2
	else 
		echo "You have entered an incorrect target specification. \n"
		exit 1
	fi 
elif [[ $# -eq 2 ]] && [[ $1 == "--target" ]]
then 
	if [[ $2 =~ $allowed_ip ]]
		then
			scan_ports $2
	else 
		echo "You have entered an incorrect IP address."
		exit 1
	fi 
else
	echo "You have entered incorrect option. Read the documentation (--help option)"
fi