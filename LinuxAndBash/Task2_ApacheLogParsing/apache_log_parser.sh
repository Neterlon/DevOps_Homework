#!/bin/bash

delimiter="---------------------------------------------------------"

if [[ $# -ne 2 ]]
then
	echo "Enter script arguments:" 
	echo "The first one - a path to a log file."
	echo "The second one - a name of the file to save a result."
	exit 1
elif [[ -f $1 ]]
then
	# Clearing a file if it was not empty
	echo "" > $2


	# Collection of information about the number of requests
	# from each IP address
	ip_statistic=`cat $1 | cut -d' ' -f1 | sort | uniq -c | sort -rn -k1`


	# Selecting the IP address that made the most requests
	most_active_ip=`echo "$ip_statistic" | head -1`
	echo "IP from which there were the most requests:" >> $2
	echo `echo $most_active_ip | cut -d' ' -f2` \
	"made" `echo $most_active_ip | cut -d' ' -f1` "requests" >> $2
	echo $delimiter >> $2


	# Selecting the most requested page
	most_requested_page=`cat $1 | cut -d'"' -f2 | cut -d' ' -f2 | \
	sort | uniq -c | sort -rn -k 1 | head -1`
	echo `echo $most_requested_page | awk '{print $2}'` \
	"is most requested page \
	(`echo $most_requested_page | awk '{print $1}'` requests)" >> $2
	echo $delimiter >> $2


	# Outputting information about the number of requests
	# from each IP address
	echo "Each IP address made this many requests: " >> $2
	echo "$ip_statistic" >> $2
	echo $delimiter >> $2


	# Requested pages that do not exist
	echo "Requested pages that do not exist: " >> $2
	cat $1 | awk '{if ($9 == 404) print $7}' | sort | uniq >> $2
	echo $delimiter >> $2


	# Time when the site received the most requests
	# (Interval time in hours)
	most_busy_time=`cat $1 | cut -d' ' -f4 | cut -c 2-15 | uniq -c | \
	sort -nr -k1 | head -1`
	echo "The site received the most requests on" \
	`echo "$most_busy_time" | awk -F '[: ]' '{print $6}'` \
	"at" `echo "$most_busy_time" | awk -F '[: ]' '{print $7}'` "o'clock" \
	"(`echo "$most_busy_time" | awk -F '[: ]' '{print $5}'` requests)" >> $2
	echo $delimiter >> $2


	# Search bots that requested the website
	# (It displays the same bots with different IP addresses!)
	echo "Search bots taht requested the website." >> $2
	echo "The same bots with different IP addresses are also displayed" >> $2
	cat $1 | awk -F '"' 'BEGIN {IGNORECASE = 1} {if ($6 ~ /bot/) print $1$6 }' | \
	awk -F '[][]' '{print $1 $3}' | sort | uniq >> $2

else
	echo "Something went wrong."
	exit 1 	
fi
