#!/bin/bash
#mail:xuel@anchnet.com
#function:auto install python
sys_init() {
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1
sed -i "s/SELINUX=enforcing/SELINUX=disabled/"  /etc/selinux/config
setenforce 0
clear
echo "##########################################"
echo "#       Auto Install Python             ##"
echo "#       Press Ctrl + C to cancel        ##"
echo "#       Any key to continue             ##"
echo "##########################################"
echo "(1) Install Python2.7"
echo "(2) Install zabbix3.6"
echo "(3) Install zabbix3.7"
echo "(4) EXIT"
read -p "Please input your choice:" NUM
case $NUM in 
1)
	URL="https://www.python.org/ftp/python/2.7/Python-2.7.tgz"
	VER=python27
;;
2)
	URL="https://www.python.org/ftp/python/3.6.0/Python-3.6.0.tgz"
	VER=python36
;;
3)
	URL="https://www.python.org/ftp/python/3.7.0/Python-3.7.0b4.tgz"
	VER=python37
;;
4)
	echo -e "\033[41;37m You choice channel! \033[0m" && exit 0
;;
*)
	echo -e "\033[41;37m Input Error! Place input{1|2|3|4} \033[0m" && exit 1
;;
esac
clear
echo -e "\033[41;37m You choice $VER \033[0m"
}

download_software() {
softdir="/software"
if [ ! -d ${softdir} ];then
	mkdir ${softdir} && cd ${softdir}
else
	cd ${softdir}
fi
wget -c ${URL} -O python.tgz
wget -c https://bootstrap.pypa.io/get-pip.py
if [ $? -eq 0 ];then
	tar zxf python.tgz -C /tmp
fi
}

install() { 
yum install -y zlib-devel zlib readline-devel  openssl-devel wget gcc-c++ libffi-devel
if [ ${VER} == "python27" ];then
	dirname="Python-2.7.0"
elif [ ${VER} == "python36" ];then
	dirname="Python-3.6.0"
else
	dirname="Python-3.7.0b4"
fi

cd /tmp/${dirname}
./configure --prefix=/usr/local/${VER}
make && make install
echo "export PATH=$PATH:/usr/local/${VER}/bin">/etc/profile.d/${VER}.sh
source /etc/profile.d/${VER}.sh
#/usr/local/${VER}/bin/python /tmp/get-pip.py
rm -rf /tmp/${VER}
echo "/usr/local/${VER}/lib">/etc/ld.so.conf.d/${VER}.conf
ldconfig
}

main() {
sys_init
download_software
install
}

main
