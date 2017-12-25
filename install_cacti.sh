#!/bin/bash
#Date 2017/2/14
#mail xuel@51idc.com
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
sed -i "s/SELINUX=enforcing/SELINUX=disabled/"  /etc/selinux/config
setenforce 0
which  ntpdate
yum install wget -y
if [ $? -eq 0 ];then
	/usr/sbin/ntpdate time1.aliyun.com
	echo "*/5 * * * * /usr/sbin/ntpdate -s time1.aliyun.com">>/var/spool/cron/root	
else
	yum install ntpdate -y
	/usr/sbin/ntpdate time1.aliyun.com
	echo "*/5 * * * * /usr/sbin/ntpdate -s time1.aliyun.com">>/var/spool/cron/root	
fi
clear
echo "##########################################"
echo "#       Auto Install Cacti.             ##"
echo "#       Press Ctrl + C to cancel        ##"
echo "#       Any key to continue             ##"
echo "##########################################"
echo "(1) Install Cacti-1.0.1"
echo "(2) Install Cacti-1.0.2"
echo "(3) Install Cacti-1.0.3"
echo "(4) EXIT"
read -p "Please input your choice:" NUM
case $NUM in 
1)
	URL="http://www.cacti.net/downloads/cacti-1.0.1.tar.gz"
	VER=cacti-1.0.1
;;
2)
	URL="http://www.cacti.net/downloads/cacti-1.0.2.tar.gz"
	VER=cacti-1.0.2
;;
3)
	URL="http://www.cacti.net/downloads/cacti-1.0.3.tar.gz"
	VER=cacti-1.0.3
;;
4)
	echo -e "\033[41;37m You choice channel! \033[0m" && exit 0
;;
*)
	echo -e "\033[41;37m Input Error! Place input{1|2|3} \033[0m" && exit 1
;;
esac
clear
echo -e "\033[32m You choice install $VER.Install\033[0m"
echo -e "\033[5m Press any key to start install $VER... \033[0m"
read -n 1
################################################################
TDIR=/tools
IP=`ifconfig eth0 | grep "inet addr" | awk -F"[: ]+" '{print $4}'`
yum remove php* -y
rpm -Uvh http://mirror.webtatic.com/yum/el6/latest.rpm
ls /etc/yum.repos.d/webtatic.repo
if [ $? -eq 0 ];then
	yum -y install `yum list|grep php55w|awk '{printf ("%s ",$1)}'` --skip-broken
fi
PHPCONF="/etc/php.ini"
if [ -f $PHPCONF ];then
	echo "date.timezone = Asia/Shanghai" >>$PHPCONF
fi
service php-fpm start /tmp/php-install.log 2>&1
STAT=`echo $?`
PORT=`netstat -lntup|grep php-fpm|wc -l`
if [ $STAT -eq 0 ] && [ $PORT -eq 1 ];then
	echo -e "\033[32m PHP is install success! \033[0m"
else
	echo -e "\033[32m PHP install file.please check /tmp/php-install.log \033[0m"
fi
############################################################
yum install httpd net-snmp net-snmp-devel net-snmp-utils rrdtool -y
RRDTVER=`yum list|grep ^rrdtool.x86_64|awk -F" " '{print $2}'`
WEBVER=`yum list|grep ^httpd.x86_64|awk -F" " '{print $2}'|cut -d- -f1`
if [ -d /var/www/html ];then
    cd /var/www/html
else
    mkdir -p /var/www/html && cd /var/www/html
fi
wget -c -O /var/www/html/$VER.tar.gz  http://www.cacti.net/downloads/$VER.tar.gz
tar -zxvf $VER.tar.gz
mv $VER cacti
cd cacti
chown -R apache.root *
useradd cacti
echo "cacti" | passwd --stdin cacti
echo "*/1 * * * * /usr/bin/php /var/www/html/cacti/poller.php >/dev/null 2>&1">>/var/spool/cron/root
service httpd start 
chkconfig httpd on 
###################################################################
SNMPFILE=/etc/snmp/snmpd.conf
if [ -f "$SNMPFILE" ]
        then
        cp $SNMPFILE /etc/snmp/snmpd.conf.bak
fi
cat > $SNMPFILE << EOF
com2sec notConfigUser  default       public
group   notConfigGroup v1           notConfigUser
group   notConfigGroup v2c           notConfigUser
view    systemview    included   .1
view    systemview    included   .1.3.6.1.2.1.1
view    systemview    included   .1.3.6.1.2.1.25.1.1
access  notConfigGroup ""      any       noauth    exact  all  none none
view all    included  .1                               80
syslocation Unknown (edit /etc/snmp/snmpd.conf)
syscontact Root <root@localhost> (configure /etc/snmp/snmp.local.conf)
dontLogTCPWrappersConnects yes
proc mountd
proc ntalkd 4
net-snmp-utils rrdtoolproc senmail 10 1
exec echotest /bin/echo hello world
disk / 10000
EOF
service snmpd start
chkconfig snmpd on
###############################################################
SQLNEW="WWW.51idc.com"
yum install mysql-server mysql -y
service mysqld start
mysqladmin -uroot password "$SQLNEW"
mysql -uroot "-p$SQLNEW" -e "create database cacti character set utf8;"
mysql -uroot "-p$SQLNEW" cacti</var/www/html/cacti/cacti.sql
mysql -uroot "-p$SQLNEW" -e "CREATE USER 'cacti'@'localhost' IDENTIFIEDBY \""$SQLNEW"\";"
mysql -uroot "-p$SQLNEW" -e "grant all privileges on cacti.* to cacti@'localhost' identified by \""$SQLNEW"\";"
mysql -uroot "-p$SQLNEW" -e "grant select on mysql.time_zone_name to 'cacti'@'localhost';"
mysql -uroot "-p$SQLNEW" -e "flush privileges;"
/usr/bin/mysql_tzinfo_to_sql /usr/share/zoneinfo|mysql -uroot -p"$SQLNEW" mysql
cat>>/etc/my.cnf<<EOF
max_heap_table_size=100M
max_allowed_packet=16777216
tmp_table_size=64M
join_buffer_size=64M
innodb_buffer_pool_size=458M
innodb_doublewrite=OFF
innodb_flush_log_at_timeout=4
innodb_read_io_threads=32
innodb_write_io_threads=16
EOF
PHPCONF=/var/www/html/cacti/include/config.php
if [ -f $PHPCONF ];then
cat >$PHPCONF<<EOF
<?php
\$database_type = "mysql";
\$database_default = "cacti";
\$database_hostname = "localhost";
\$database_username = "cacti";
\$database_password = "$SQLNEW";
\$database_port = "3306";
?>
EOF
fi
clear
service mysqld restart
#############################################################
/etc/init.d/iptables status >/dev/null 2>&1
if [ $? -eq 0 ];then
	iptables -I INPUT -p tcp --dport 80 -j ACCEPT &&
#iptables -I INPUT -p tcp --dport 3306 -j ACCEPT && 
	service iptables save >/dev/null 2>&1
	/etc/init.d/iptables restart
else
	echo -e "\033[32m iptables is stopd\033[0m"
fi
clear
echo -e "\033[42;37m Mysql:5.7 rrdtool:$RRDTVER PHP:5.5 apche:$WEBVER\033[0m"
echo -e "\033[42;37m MySql Username:root Password:$SQLNEW \033[0m"
echo -e "\033[42;37m URL:http://$IP/cacti \033[0m"
echo -e "\033[42;37m $VER is Install Success,Username:Admin Password:admin \033[0m"
