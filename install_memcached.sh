#!/bin/bash
#mail:xuel@anchnet.com
#function:auto install memcached
clear
echo "##########################################"
echo "#       Auto Install Memcached-1.4      ##"
echo "#       Press Ctrl + C to cancel        ##"
echo "#       Any key to continue             ##"
echo "##########################################"
read -n 1
softdir="/software"
memcached_url="http://www.danga.com/memcached/dist/memcached-1.4.0.tar.gz"
libevent_url="https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz"
sys_version=$(rpm -q centos-release|cut -d- -f3)

sys_init() {
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
[ ${sys_version} != "6" ] && echo "Please use centos6.x" && exit 1
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1
sed -i "s/SELINUX=enforcing/SELINUX=disabled/"  /etc/selinux/config
setenforce 0
yum install -y gcc gcc-c++ wget
}

download_software() {
if [ ! -d ${softdir} ];then
	mkdir ${softdir} && cd ${softdir}
else
	cd ${softdir}
fi
for software_url in ${memcached_url} ${libevent_url}
do
	wget -c ${software_url}
	if [ $? -eq 0 ];then
		for software in `ls`
		do
			tar zxf $software -C /tmp
		done
	fi
done
}

install() {
cd /tmp/libevent-2.1.8-stable
./configure --prefix=/usr/local/libevent
make && make install
rm -rf /tmp/libevent-2.1.8-stable 
echo "/usr/local/libevent/lib">/etc/ld.so.conf.d/libevent.conf
ldconfig

cd /tmp/memcached-1.4.0
./configure --with-libevent=/usr/local/libevent --prefix=/usr/local/memcached
make && make install
rm -rf /tmp/memcached-1.4.0
echo "export PATH=$PATH:/usr/local/memcached/bin">/etc/profile.d/memcached.sh && source /etc/profile.d/memcached.sh
}

start_server() {
cat >/etc/init.d/memcached-server<<EOF
#!/bin/bash
#auth:kaliarch
# memcached    Startup script for memcached processes
#
# chkconfig: - 90 10
# description: Memcache provides fast memory based storage.
# processname: memcached

. /etc/rc.d/init.d/functions

memcached="/usr/local/memcached/bin/memcached"
prog="memcached"
port=11211
user=nobody
mem=20
lockfile=\${LOCKFILE-/var/lock/subsys/memcached}
pidfile=\${PIDFILE-/tmp/memcached.pid}
getpid=\$(pidof memcached)
start() {
    action $"Starting \$prog: " /bin/true
    # Starting memcached with 64MB memory on port 11211 as deamon and user nobody
    \$memcached -d -m \$mem -p \$port -u \$user -P \${pidfile}

    RETVAL=$?
    [ \$RETVAL = 0 ] && touch \${lockfile}
    return \$RETVAL
}

stop() {
    if test "x\${getpid}" != x; then
        action $"Stopping \$prog " /bin/true
        killall memcached
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
	    status -p \${pidfile} \${memcached}
	    RETVAL=\$?
            ;;

        restart)
            stop
            start
            ;;
        condrestart)
            if test "x\${getpid}" != x; then
                stop
                start
            fi
            ;;

        *)
            echo $"Usage: \$0 {start|status|stop|restart|condrestart}"
            exit 1

esac

exit \${RETVAL}
EOF
cd /
chmod +x /etc/init.d/memcached-server
chkconfig memcached-server on
service memcached-server start
}

main() {
sys_init
download_software
install
start_server
}

main
