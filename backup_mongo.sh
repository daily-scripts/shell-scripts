#!/bin/bash
#auth:xuel@anchnet.com
#backup mongodb

. /etc/profile
CMD=`which mongodump`
DATE=`date +%F`
DB="test"
DB_HOST="localhost"
DB_PORT="27017"
DB_USER="testuser"
DB_PWD="testpass"
BACKUP_DIR="/data/mongodb/"
TAR_DIR="/data/tardir/"
TAR_DIR_DATE="${TAR_DIR}${DATE}"
TAR_BAK="mongodb_bak_$DATE.tar.gz"

check_dir(){
	for DIR in ${BACKUP_DIR} ${TAR_DIR_DATE}
	do
		if [ ! -d $DIR ];then
			mkdir -p $DIR
		fi
	done
}
backup_mongodb(){
	$CMD -h ${DB_HOST}:${DB_PORT} -u $DB_USER -p $DB_PWD -d ${DB} -o ${BACKUP_DIR}${DATE} >/dev/null
	if [ $? -eq 0 ];then
		tar -zcf ${TAR_DIR_DATE}/${TAR_BAK} ${BACKUP_DIR}${DATE} && return 0
	fi
}
clean_tar() {
	find ${TAR_DIR} -mtime +7 -exec rm -rf {} \; && return 0
}

main() {
	check_dir
	[ $? -eq 0 ] && backup_mongodb
	[ $? -eq 0 ] && clean_tar
}

main
