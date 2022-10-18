#!/bin/bash


# An example of using a user crontab file to run this script every minute:
# * * * * * /home/vlad/opt/dirbackup.sh /home/vlad/dir1 /home/vlad/dir_backup


# Creating a directory where all backups 
# will be stored and creating the actual first backup.
# Logging initial files (backup.log).
function first_backup {
	# Backup operations
	mkdir -p $2
	backups_main_dir=`basename $2`
	backup_time=`date +%Y-%m-%d_%H:%M`
	backup_files=$(tar -czvf $2/$backups_main_dir--${backup_time}.tar.gz $1)
	# Logging
	touch $2/backup.log
	echo "$backup_files" | awk -F '/' -v t="$backup_time" \
	'{if (NR!=1) {print t " -- " $2 " -- was in the first backup"}}' \
	>> $2/backup.log
}


# Creating all other backups except the first one.
# Comparing the files of the new and previous backups.
# Logging of added and deleted files (backup.log).
function any_backup {
	# Getting information about the previous backup
	previous_backup_name=`ls -At $2 | head -2 | \
	awk '{if ($1 != "backup.log"){print $1}}' | head -1`
	tar -tzf "$2/$previous_backup_name" | sort > $2/.temp1
	# Backup operations
	backups_main_dir=`basename $2`
	backup_time=`date +%Y-%m-%d_%H:%M`
	tar -czvf $2/$backups_main_dir--${backup_time}.tar.gz $1 | sort > $2/.temp2
	# Logging
	backup_differences=`diff $2/.temp1 $2/.temp2`
	rm $2/.temp1 $2/.temp2
	echo "$backup_differences" | awk -F '[/ ]' -v t="$backup_time" \
	'{if (substr($1,1,1) == ">") {print t " -- " $3 " -- was added ";} \
	else if (substr($1,1,1) == "<") { print t " -- " $3 " -- was deleted"}}' \
	>> $2/backup.log
}


# Checking if the destination directory exists
# and performing various actions in the presence or
# absence of the destination directory
if [[ $# -eq 2 ]] && [[ ! -d $2 ]]
then
	first_backup $1 $2
elif [[ $# -eq 2 ]] && [[ -d $2 ]] && [[ -f $2/backup.log ]]
then
	any_backup $1 $2
elif [[ $# -eq 2 ]] && [[ -d $2 ]] && [[ ! -f $2/backup.log ]]
then
	if [[ -z "$(ls -A $2)" ]]
	then
		first_backup $1 $2
	elif [[ ! -z "$(ls -A $2)" ]]
	then
		echo "This directory already has files." \ 
		echo "You can not use it to make backups."
	fi
else 
	echo "Something went wrong."
	echo "Enter script arguments:"
	echo "The first one - path to the syncing directory."
	echo "The second one - path to the directory where backups will be stored"
fi

