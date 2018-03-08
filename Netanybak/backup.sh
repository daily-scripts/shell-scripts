#!/bin/bash
read -p "Please input ftp server ipaddress:" FTPIP
read -p "Please input ftp username:" FTPUSER
read -p "Please input ftp password:" FTPPWD
read -p "Please input Receive mailbox:" MAIL
config_file=/scripts/back_conf
backup_dir=/FTP
DATE=$(date +%Y%m%d)
	if [ ! -d $backup_dir ];then
		/bin/mkdir $backup_dir
	fi
cat $config_file | while read ADDRESS NAME IP USER PASSWD PORT FILENAME;do
	if [ ! -d $backup_dir/$ADDRESS/$NAME ];then
		/bin/mkdir -p $backup_dir/$ADDRESS/$NAME
	fi
	./back.sh $IP $USER $PASSWD $PORT $FILENAME $FTPIP $FTPUSER $FTPPWD &>/dev/null
	if [ $? -eq 0 ];then
		/bin/mv $backup_dir/$FILENAME $backup_dir/$ADDRESS/$NAME/$FILENAME"_"$DATE 
		/bin/echo "BACKUP $IP SUCCESS,BACKUP_FILE $backup_dir/$ADDRESS/$NAME/$FILENAME"_"$DATE" | /bin/mail -r "service02@51idc.com" -s "$NAME 防火墙备份_成功！" $MAIL
	else
		/bin/echo "BACKUP $IP SUCCESS,BACKUP_FILE $backup_dir/$ADDRESS/$NAME/$FILENAME"_"$DATE" | /bin/mail -r "service02@51idc.com" -s "$NAME 防火墙备份_失败！" $MAIL
	fi
done	
