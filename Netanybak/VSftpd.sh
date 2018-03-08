#!/bin/bash
vsftpd=/etc/vsftpd/vsftpd.conf
ftppasswd=`cat /dev/urandom | head -n 10 | md5sum | head -c 10`
yum install -y vsftpd &> /tmp/vsftp_install
mv $vsftpd $vsftpd.bak
cat > $vsftpd <<EOF
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
ascii_upload_enable=YES
ascii_download_enable=YES
ftpd_banner=Welcome to blah FTP service.
chroot_local_user=YES
#chroot_list_enable=YES
# (default follows)
#chroot_list_file=/etc/vsftpd/chroot_list
listen=YES
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
EOF
chmod 600 $vsftpd
service vsftpd start
chkconfig vsftpd on
service iptables stop
#Add firewall rules
#iptables -A INPUT -p tcp --dport 22 -j ACCEPT
#iptables -A INPUT -p tcp --dport 21 -j ACCEPT
#iptables -A INPUT -p tcp --dport 20 -j ACCEPT
#/etc/init.d/iptables save
#Disabled SELINUX
sed -i "s/SELINUX=enforcing/SELINUX=disabled/"  /etc/selinux/config
setenforce 0
mkdir  -p /FTP
useradd  -d /FTP -s /sbin/nologin ftpadmin 
echo "ftpadmin:$ftppasswd" | chpasswd
echo "The username is  ftpadmin, the initial password is $ftppasswd" > /root/ftppasswd.txt
chown -R ftpadmin /FTP
chmod 755  /FTP
exit 0
