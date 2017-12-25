#!/bin/bash
#Date 2017/1/20
#mail xuel@51idc.com
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
sed -i "s/SELINUX=enforcing/SELINUX=disabled/"  /etc/selinux/config
setenforce 0
which  ntpdate
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
echo "#       Auto Install zabbix.            ##"
echo "#       Press Ctrl + C to cancel        ##"
echo "#       Any key to continue             ##"
echo "##########################################"
echo "(1) Install zabbix3.0"
echo "(2) Install zabbix3.2"
echo "(3) Install zabbix3.4"
echo "(4) EXIT"
read -p "Please input your choice:" NUM
case $NUM in 
1)
	URL="http://repo.zabbix.com/zabbix/3.0/rhel/6/x86_64/zabbix-release-3.0-1.el6.noarch.rpm"
	VER=zabbix-3.0
;;
2)
	URL="http://repo.zabbix.com/zabbix/3.2/rhel/6/x86_64/zabbix-release-3.2-1.el6.noarch.rpm"
	VER=zabbix-3.2
;;
3)
	URL="http://repo.zabbix.com/zabbix/3.4/rhel/6/x86_64/zabbix-release-3.4-1.el6.noarch.rpm"
	VER=zabbix-3.4
;;
4)
	echo -e "\033[41;37m You choice channel! \033[0m" && exit 0
;;
*)
	echo -e "\033[41;37m Input Error! Place input{1|2|3|4} \033[0m" && exit 1
;;
esac
clear
echo -e "\033[32m You choice install $VER.Install\033[0m"
echo -e "\033[5m Press any key to start install $VER... \033[0m"
read -n 1
TDIR=/tools
IP=`ifconfig eth0 | grep "inet addr" | awk -F"[: ]+" '{print $4}'`
yum remove php* -y
rpm -Uvh http://mirror.webtatic.com/yum/el6/latest.rpm
ls /etc/yum.repos.d/webtatic.repo
if [ $? -eq 0 ];then
	yum -y install `yum list|grep php71w|awk '{printf ("%s ",$1)}'` --skip-broken
fi
if [ $? -eq 0 ];then
	sed -i "s/;date.timezone =/date.timezone = Asia\/Shanghai/g" /etc/php.ini 
	sed -i "s#`grep max_execution_time /etc/php.ini`#max_execution_time = 300#g" /etc/php.ini
	#max_execution_time = 30
	sed -i "s#`grep post_max_size /etc/php.ini`#post_max_size = 32M#g" /etc/php.ini 
	sed -i "s#`grep max_input_time\ = /etc/php.ini`#max_input_time = 300#g" /etc/php.ini 
	sed -i "s#`grep memory_limit /etc/php.ini`#memory_limit = 128M#g" /etc/php.ini
fi
service php-fpm start /tmp/php-install.log 2>&1
STAT=`echo $?`
PORT=`netstat -lntup|grep php-fpm|wc -l`
if [ $STAT -eq 0 ] && [ $PORT -eq 1 ];then
	echo -e "\033[32m PHP is install success! \033[0m"
else
	echo -e "\033[32m PHP install file.please check /tmp/php-install.log \033[0m"
fi
yum install -y ntpdate mailx dos2unix vim zcat wget net-snmp-utils gcc gcc-c++ autoconf httpd libxml* mysql mysql-server  httpd-manual mod_ssl mod_perl mod_auth_mysql mysql-connector-odbc mysql-devel libdbi-dbd-mysql net-snmp-devel curl-devel unixODBC-devel OpenIPMI-devel java-devel fping 
clear
service mysqld start
groupadd zabbix -g 201 
useradd -g zabbix -u 201 -m -s /sbin/nologin zabbix
rpm -ivh  $URL
ls /etc/yum.repos.d/zabbix.repo
ZAB=`echo $?`
if [ ! -d $TDIR ];then
        /bin/mkdir $TDIR && cd $TDIR
fi
if [ "$VER" == "zabbix-3.0" ];then
	yum install -y zabbix-agent.x86_64 zabbix-get.x86_64 zabbix-server-mysql.x86_64 zabbix-web.noarch zabbix-web-mysql.noarch
elif [ "$VER" == "zabbix-3.2" ];then
	if [ -d $TDIR ];then
		cd $TDIR
	else
        	/bin/mkdir $TDIR && cd $TDIR
	fi
	if [ $? -eq 0 ];then
		for PAG in zabbix-server-mysql-3.2.7-1.el6.x86_64.rpm zabbix-web-3.2.7-1.el6.noarch.rpm zabbix-web-mysql-3.2.7-1.el6.noarch.rpm 
		do
			wget -c --timeout=5 http://repo.zabbix.com/zabbix/3.2/rhel/6/x86_64/deprecated/$PAG
		done
		wget -c --timeout=5 http://repo.zabbix.com/zabbix/3.2/rhel/6/x86_64/zabbix-agent-3.2.7-1.el6.x86_64.rpm
		yum localinstall -y zabbix-server-mysql* zabbix-web-mysql* zabbix-agent zabbix-web*
		if [ $? -eq 0 ];then
			exit 1 && echo "Zabbix Softward install fail,Please check dirname /tools"
		fi
	fi
elif [ "$VER" == "zabbix-3.4" ];then
	if [ -d $TDIR ];then
		cd $TDIR
	else
        	/bin/mkdir $TDIR && cd $TDIR
	fi
	if [ $? -eq 0 ];then
		for PAG in zabbix-server-mysql-3.4.0-1.el6.x86_64.rpm zabbix-web-3.4.0-1.el6.noarch.rpm zabbix-web-mysql-3.4.0-1.el6.noarch.rpm 
		do
			wget -c --timeout=5 --tries=35 --user-agent="Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.16 (KHTML, like Gecko)Chrome/10.0.648.204 Safari/534.16" http://repo.zabbix.com/zabbix/3.4/rhel/6/x86_64/deprecated/$PAG
		done
		wget -c --timeout=5 --tries=35 --user-agent="Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.16 (KHTML, like Gecko)Chrome/10.0.648.204 Safari/534.16" http://repo.zabbix.com/zabbix/3.4/rhel/6/x86_64/zabbix-agent-3.4.0-1.el6.x86_64.rpm
		yum localinstall -y zabbix-*
		if [ $? -ne 0 ];then
			"Zabbix Softward install fail,Please check dirname /tools" && exit 1
		fi
	fi
else
	echo "error zabbixi version"
fi
if [ $? -eq 0 ];then
mysql -uroot -e "create database zabbix character set utf8;" 
mysql -uroot -e "grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';"
mysql -uroot -e "flush privileges;"
fi
cd /usr/share/doc
MYSQLDIR=`ls -l /usr/share/doc/ | grep zabbix-server-mysql* | awk  '{print $9}'`
cd $MYSQLDIR
zcat create.sql.gz | mysql -uroot zabbix
mysqladmin -uroot password "mysqladmin"
cd /usr/share/
cp -r ./zabbix/ /var/www/html/zabbix 
echo "DBPassword=zabbix" >> /etc/zabbix/zabbix_server.conf
service httpd start 
service zabbix-server start 
service zabbix-agent start 
chkconfig httpd on 
chkconfig mysqld on 
chkconfig php-fpm on
chkconfig zabbix-server on 
chkconfig zabbix-agent on
/etc/init.d/iptables status >/dev/null 2>&1
if [ $? -eq 0 ];then
	iptables -I INPUT -p tcp --dport 443 -j ACCEPT &&
	iptables -I INPUT -p tcp --dport 10051 -j ACCEPT &&
	iptables -I INPUT -p tcp --dport 10050 -j ACCEPT &&
	iptables -I INPUT -p tcp --dport 3000 -j ACCEPT &&
#iptables -I INPUT -p tcp --dport 3306 -j ACCEPT && 
	service iptables save >/dev/null 2>&1
	/etc/init.d/iptables restart
else
	echo -e "\033[32m iptables is stopd\033[0m"
fi
clear
STAT=`/bin/ps -ef|grep zabbix_server|grep -v grep|wc -l`
PORT=`/bin/netstat -lntup|grep zabbix_server|wc -l`
if [ $STAT -ne 0 ] && [ $PORT -ne 0 ];then
	echo -e "\033[42;37m Zabbix$VER is Install Success,Username:Admin Password:zabbix \033[0m"
	echo -e "\033[42;37m MySql Username:root Password:mysqladmin \033[0m"
	echo -e "\033[42;37m rul:https://$IP/zabbix \033[0m"
fi
