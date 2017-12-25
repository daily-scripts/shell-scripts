#/bin/bash

#author:xuel
#mail:xuel@51idc.com
#data:2016/6/11

DIR=/data/mysqldump/`date +%Y-%m-%d`
MYSQLDB=cacti
MYSQLUSR=root
MYSQLPW=mysqladmin
MYSQLCMD=/usr/bin/mysqldump
if [ $UID -ne 0 ];then
	echo "Must to be use root for exec shell."
	exit
fi

if [ ! -d $DIR ];then
	mkdir -p $DIR
	echo "\033[32mThe $DIR create successfully!"
else
	echo "This $DIR is exists..."
fi

#mysqldump
$MYSQLCMD -u$MYSQLUSR -p$MYSQLPW -d $MYSQLDB >$DIR/$MYSQLDB.sql
if [ $? -eq 0 ];then
	echo -e "\033[32mThe mysql backup $MYSQLDB successfully!\033[0m"
else
	echo -e "\033[32The mysql backup $MYSQLDB failed.Please check!\033[0m"
fi
