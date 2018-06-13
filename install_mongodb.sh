#!/bin/bash
#mail:xuel@anchnet.com
#function:auto install mongodb
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1
logfile="/var/log/mongod_install.log"
softdir="/software"
installdir="/usr/local"
sys_version=$(rpm -q centos-release|cut -d- -f3)
clear
echo "##########################################"
echo "#  Auto Install mongodb for centos6/7.x ##"
echo "#       Press Ctrl + C to cancel        ##"
echo "#       Any key to continue             ##"
echo "##########################################"
echo "(1) Install Mongodb-3.2"
echo "(2) Install Mongodb-3.4"
echo "(3) Install Mongodb-3.6"
echo "(4) EXIT"
read -p "Please input your choice:" NUM
if [ ${sys_version} == "6" ];then
	case $NUM in 
	1)
	       mongodb_url="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.2.20.tgz"	
	       software_version="mongodb-3.2"
	;;
	2)
	       mongodb_url="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.4.10.tgz"
	       software_version="mongodb-3.4"
	;;
	3)
	       mongodb_url="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.6.5.tgz"
	       software_version="mongodb-3.6"
	;;
	4)
	       echo -e "\033[41;37m You choice channel! \033[0m" && exit 0
	;;
	*)
	       echo -e "\033[41;37m Input Error! Place input{1|2|3|4} \033[0m" && exit 1
	;;
	esac
elif [ ${sys_version} == "7" ];then
	case $NUM in 
	1)
	       mongodb_url="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.2.20.tgz"	
	       software_version="mongodb-3.2"
	;;
	2)
	       mongodb_url="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.4.10.tgz"
	       software_version="mongodb-3.4"
	;;
	3)
	       mongodb_url="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.6.5.tgz"
	       software_version="mongodb-3.6"
	;;
	4)
	       echo -e "\033[41;37m You choice channel! \033[0m" && exit 0
	;;
	*)
	       echo -e "\033[41;37m Input Error! Place input{1|2|3|4} \033[0m" && exit 1
	;;
	esac
else
	echo "system must user centos6/7.x." >>${logfile} 2>&1
fi

sys_init() {
clear
echo -e "\033[42;5m initialization system... \033[0m"
sleep 2
sed -i "s/SELINUX=enforcing/SELINUX=disabled/"  /etc/selinux/config
if [ ${sys_version} == "6" ];then
/etc/init.d/iptables status >/dev/null
[ $? -eq 0 ] && iptables -I INPUT -p tcp --dport 27017 -j ACCEPT
[ $? -eq 0 ] && /etc/init.d/iptables save >${logfile} 2>&1
elif [ ${sys_version} == "7" ];then
systemctl stop firewalld && systemctl disable firewalld
else
echo "system must user centos6/7.x." >>${logfile} 2>&1
fi
yum -y install wget >/dev/null
setenforce 0
echo "sys_init complate!">> ${logfile} 
}


download_software() {
clear
echo -e "\033[42;5m download software... \033[0m"
sleep 2
if [ ! -d ${softdir} ];then
    mkdir ${softdir} && cd ${softdir}
else
    cd ${softdir}
fi
for software_url in ${mongodb_url}
do
    wget -c ${software_url} --tries=5
    if [ $? -eq 0 ];then
        for software in `ls`
        do
            tar zxf $software -C $installdir
        done
    else
	echo "download software error!" >> ${logfile} 2>&1 && exit 1
    fi
done
echo "download_software" >>${logfile}
}

install_software() {
clear
echo -e "\033[42;5m install server... \033[0m"
sleep 2
mongodbdir=$(ls ${installdir}|grep "mongodb-linux-x86_64")
ln -s ${installdir}/${mongodbdir} ${installdir}/mongodb
mkdir ${installdir}/mongodb/{conf,mongoData,mongoLog}
touch ${installdir}/mongodb/mongoLog/mongodb.log
echo "export PATH=\$PATH:${installdir}/mongodb/bin">/etc/profile.d/mongodb.sh
source /etc/profile.d/mongodb.sh
cat >${installdir}/mongodb/conf/mongodb.conf <<EOF
dbpath=${installdir}/mongodb/mongoData
logpath=${installdir}/mongodb/mongoLog/mongodb.log
logappend=true
journal=true
quiet=true
port=27017
pidfilepath=/var/run/mongod.pid
#replSet =RS
maxConns=20000
#httpinterface=true
fork=true
#auth=true
EOF
echo "install_software complate!" >>${logfile}
}

start_server() {
clear
echo -e "\033[42;5m configuration server... \033[0m"
if [ ${sys_version} == "6" ];then
cat >/etc/init.d/mongodb-server<<EOF
#!/bin/bash
#auth:kaliarch
# mongodb    Startup script for mongodb processes
#
# chkconfig: - 90 10
# description: Mongodb provides fast memory based storage.
# processname: Mongodb

. /etc/rc.d/init.d/functions
bash_dir="/usr/local/mongodb"
mongod="\${bash_dir}/bin/mongod"
config="\${bash_dir}/conf/mongodb.conf"
getpid=\$(pidof mongod)
lockfile="\${bash_dir}/mongodb.lock"
pidfile="/var/run/mongod.pid"
#user=nobody
start() {
    action $"Starting \$prog: " /bin/true
    # Starting mongodb on port 27017 as deamon and user nobody
    \$mongod -f \${config} >/dev/null

    RETVAL=$?
    [ \$RETVAL = 0 ] && touch \${lockfile}
    return \$RETVAL
}

stop() {
    if test "x\${getpid}" != x; then
        action $"Stopping \$prog " /bin/true
        killall mongod 
    fi
    RETVAL=\$?
    [ \$RETVAL = 0 ] && rm -rf \${lockfile} \${pidfile}
    return \$RETVAL
}

case "\$1" in
        start)
            start
            ;;

        stop)
            stop
            ;;

        status)
        status -p \${pidfile} \${mongod}
        RETVAL=\$?
            ;;

        restart)
            stop
            start
            ;;

        *)
            echo $"Usage: \$0 {start|status|stop|restart}"
            exit 1

esac

exit \${RETVAL}
EOF
cd /
chmod +x /etc/init.d/mongodb-server
chkconfig mongodb-server on
service mongodb-server start
elif [ ${sys_version} == "7" ];then
cat >/usr/lib/systemd/system/mongod.service<<EOF
[Unit]
Description=The Mongodb Server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/local/mongodb/bin/mongod -f /usr/local/mongodb/conf/mongodb.conf
ExecStop=/usr/local/mongodb/bin/mongod --shutdown --dbpath /usr/local/mongodb/mongoData

[Install]
WantedBy=multi-user.target
EOF
systemctl start mongod
systemctl enable mongod >>${logfile} 2>&1
else
	echo "install occer error,please see ${logfile}" && exit 1
fi
}


check_server() {
clear
echo -e "\033[42;5m check server status... \033[0m"
server_port=$(netstat -lntup|grep mongod|wc -l)
server_proc=$(ps -ef |grep mongodb.conf|grep -v grep|wc -l)
if [ ${server_port} -gt 0 -a ${server_port} -gt 0 ];then
	echo -e "\033[42;37m mongodb-server install successful! \033[0m"
	echo -e "\033[42;37m version:${software_version}  \033[0m"
	echo -e "\033[42;37m bashpath:${installdir}/mongodb  \033[0m"
else
	echo "install occer error,please see ${logfile}" && exit 1
fi
}

main() {
sys_init
download_software
install_software
start_server
check_server
}

main
