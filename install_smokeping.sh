#!/bin/bash
#############
#Date 2016/11/11
#mail xuel@51idc.com
#############
echo "##########################################"
echo "Auto Install smokeping-2.6.11           ##"
echo "Press Ctrl + C to cancel                ##"
echo "Any key to continue                     ##"
echo "##########################################"
read -n 1
/etc/init.d/iptables status >/dev/null 2>&1
if [ $? -eq 0 ]
then
iptables -I INPUT -p tcp --dport 80 -j ACCEPT && 
iptables-save >/dev/null 2>&1
else
	echo -e "\033[32m iptables is stopd\033[0m"
fi
IP=`/sbin/ifconfig|sed -n '/inet addr/s/^[^:]*:\([0-9.]\{7,15\}\) .*/\1/1p'|sed -n '1p'`
sed -i "s/SELINUX=enforcing/SELINUX=disabled/"  /etc/selinux/config
setenforce 0
rpm -Uvh http://apt.sw.be/redhat/el6/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm 1>/dev/null
yum -y install perl perl-Net-Telnet perl-Net-DNS perl-LDAP perl-libwww-perl perl-RadiusPerl perl-IO-Socket-SSL perl-Socket6 perl-CGI-SpeedyCGI perl-FCGI perl-CGI-SpeedCGI perl-Time-HiRes perl-ExtUtils-MakeMaker perl-RRD-Simple rrdtool rrdtool-perl curl fping echoping  httpd httpd-devel gcc make  wget libxml2-devel libpng-devel glib pango pango-devel freetype freetype-devel fontconfig cairo cairo-devel libart_lgpl gcc libart_lgpl-devel mod_fastcgi wget wqy-*
if [ -d /opt ];then
    cd /opt
else
    mkdir -p /opt && cd /opt
fi
wget http://oss.oetiker.ch/smokeping/pub/smokeping-2.6.11.tar.gz 
tar -xvf smokeping-2.6.11.tar.gz 1>/dev/null
cd /opt/smokeping-2.6.11
./setup/build-perl-modules.sh /usr/local/smokeping/thirdparty 
./configure -prefix=/usr/local/smokeping 
/usr/bin/gmake install  1>/dev/null
cd /usr/local/smokeping
mkdir cache data var 1>/dev/null
touch /var/log/smokeping.log
chown -R apache:apache cache data var
chown -R apache:apache /var/log/smokeping.log
mv /usr/local/smokeping/htdocs/smokeping.fcgi.dist  /usr/local/smokeping/htdocs/smokeping.fcgi
mv /usr/local/smokeping/etc/config.dist  /usr/local/smokeping/etc/config
cp -f /usr/local/smokeping/etc/config /usr/local/smokeping/etc/config.back
sed -i "s/some.url/IP/g" /usr/local/smokeping/etc/config
chmod 600 /usr/local/smokeping/etc/smokeping_secrets.dist

if [ -d /opt ];then
    cd /opt
else
    mkdir -p /opt && cd /opt
fi
wget -c -O /opt/fping-3.13.tar.gz http://fping.org/dist/fping-3.13.tar.gz
tar zxvf fping-3.13.tar.gz
cd fping-3.13
./configure --prefix=/usr/local/fping
make && make install
sed -i "s#`grep fping /usr/local/smokeping/etc/config`#binary = /usr/local/fping/sbin/fping#g" /usr/local/smokeping/etc/config
sed -i "148i'--font TITLE:20:"WenQuanYi\ Zen\ Hei\ Mono"'\," /usr/local/smokeping/lib/Smokeping/Graphs.pm
cp -rf /etc/httpd/conf/httpd.conf  /etc/httpd/conf/httpd.conf.back
cat >> /etc/httpd/conf/httpd.conf <<'EOF'
Alias /cache "/usr/local/smokeping/cache/"
Alias /cropper "/usr/local/smokeping/htdocs/cropper/"
Alias /smokeping "/usr/local/smokeping/htdocs/smokeping.fcgi"
<Directory "/usr/local/smokeping">
AllowOverride None
Options All
AddHandler cgi-script .fcgi .cgi
Order allow,deny
Allow from all
DirectoryIndex smokeping.fcgi
</Directory>
EOF

if [ -f /etc/init.d/smokeping ];then
    echo "/etc/init.d/smokeping is exist"
else
    touch /etc/init.d/smokeping
    cat > /etc/init.d/smokeping <<'EOF'
	#!/bin/bash
	#chkconfig: 2345 80 05
	# Description: Smokeping init.d script
	# Create by : Mox
	# Get function from functions library
	. /etc/init.d/functions
	# Start the service Smokeping
	smokeping=/usr/local/smokeping/bin/smokeping
	prog=smokeping
	pidfile=${PIDFILE-/usr/local/smokeping/var/smokeping.pid}
	lockfile=${LOCKFILE-/var/lock/subsys/smokeping}
	RETVAL=0
	STOP_TIMEOUT=${STOP_TIMEOUT-10}
	LOG=/var/log/smokeping.log

	start() {
        echo -n $"Starting $prog: "
        LANG=$HTTPD_LANG daemon --pidfile=${pidfile} $smokeping $OPTIONS
        RETVAL=$?
        echo
        [ $RETVAL = 0 ] && touch ${lockfile}
        return $RETVAL
	}


	# Restart the service Smokeping
	stop() {
        echo -n $"Stopping $prog: "
        killproc -p ${pidfile} -d ${STOP_TIMEOUT} $smokeping
        RETVAL=$?
        echo
        [ $RETVAL = 0 ] && rm -f ${lockfile} ${pidfile}
	}

	STOP_TIMEOUT=${STOP_TIMEOUT-10}
	LOG=/var/log/smokeping.log

	start() {
        echo -n $"Starting $prog: "
        LANG=$HTTPD_LANG daemon --pidfile=${pidfile} $smokeping $OPTIONS
        RETVAL=$?
        echo
        [ $RETVAL = 0 ] && touch ${lockfile}
        return $RETVAL
	}


	# Restart the service Smokeping
	stop() {
        echo -n $"Stopping $prog: "
        killproc -p ${pidfile} -d ${STOP_TIMEOUT} $smokeping
        RETVAL=$?
        echo
        [ $RETVAL = 0 ] && rm -f ${lockfile} ${pidfile}
	}

	case "$1" in
	start)
        start
	;;
	stop)
        stop
	;;
	status)
        status -p ${pidfile} $httpd
        RETVAL=$?
	;;
	restart)
        stop
        start
        ;;
	*)
        echo $"Usage: $prog {start|stop|restart|status}"
        RETVAL=2

	esac

EOF
fi

cat > /usr/local/smokeping/etc/config <<'EOF'
*** General ***

owner    = Peter Random
contact  = service02@51idc.com
#mailhost = smtp.51idc.com:25
#mailusr  = xuel@51idc
#mailpwd  = anchnet@123.com
#sendmail = /usr/sbin/sendmail
# NOTE: do not put the Image Cache below cgi-bin
# since all files under cgi-bin will be executed ... this is not
# good for images.
imgcache = /usr/local/smokeping/cache
imgurl   = cache
datadir  = /usr/local/smokeping/data
piddir  = /usr/local/smokeping/var
cgiurl   = http://$IP/smokeping.cgi
smokemail = /usr/local/smokeping/etc/smokemail.dist
tmail = /usr/local/smokeping/etc/tmail.dist
# specify this to get syslog logging
syslogfacility = local0
# each probe is now run in its own process
# disable this to revert to the old behaviour
# concurrentprobes = no

*** Alerts ***
to = 13122690827@163.com
from = service02@51idc.com

+someloss
type = loss
# in percent
pattern = >0%,*12*,>0%,*12*,>0%
comment = loss 3 times  in a row

+rttdetect
type = rtt
 #in milli seconds
pattern = <10,<10,<10,<10,<10,<100,>100,>100,>100
edgetrigger = yes
comment = routing messed up again ?

+lossdetect
type = loss
# in percent
pattern = ==0%,==0%,==0%,==0%,>20%,>20%,>20%
edgetrigger = yes
comment = suddenly there is packet loss

+miniloss
type = loss
# in percent
pattern = >0%,*12*,>0%,*12*,>0%
edgetrigger = yes
#pattern = >0%,*12*
comment = detected loss 1 times over the last two hours

#+rttdetect
#type = rtt
# in milliseconds
#pattern = <1,<1,<1,<1,<1,<2,>2,>2,>2
#comment = routing messed up again ?

+rttbad
type = rtt
# in milliseconds
edgetrigger = yes
pattern = ==S,>20
comment = route

+rttbadstart
type = rtt
# in milliseconds
edgetrigger = yes
pattern = ==S,==U
comment = offline at startup
*** Database ***

step     = 60
pings    = 20

# consfn mrhb steps total

AVERAGE  0.5   1  1008
AVERAGE  0.5  12  4320
    MIN  0.5  12  4320
    MAX  0.5  12  4320
AVERAGE  0.5 144   720
    MAX  0.5 144   720
    MIN  0.5 144   720

*** Presentation ***
charset = utf-8
template = /usr/local/smokeping/etc/basepage.html.dist

+ charts

menu = 排行榜
title = 排行榜

++ stddev
sorter = StdDev(entries=>4)
title = 综合指数排行
menu = 综合指数排行
format = 综合指数 %f

++ max
sorter = Max(entries=>5)
title = 最大延迟排行
menu = 最大延迟排行
format = 最大延迟时间 %f 秒

++ loss
sorter = Loss(entries=>5)
title = 丢包率排行
menu = 丢包率排行
format = 丢包 %f

++ median
sorter = Median(entries=>5)
title = 平均延迟排行
menu = 平均延迟排行
format = 平均延迟 %f 秒

+ overview 

width = 860
height = 150
range = 10h

+ detail

width = 860
height = 200
unison_tolerance = 2

"Last 3 Hours"    3h
"Last 30 Hours"   30h
"Last 10 Days"    10d
"Last 30 Days"   30d
"Last 90 Days"   90d
#+ hierarchies
#++ owner
#title = Host Owner
#++ location
#title = Location

*** Probes ***

+ FPing

binary = /usr/local/fping/sbin/fping

*** Slaves ***
secrets=/usr/local/smokeping/etc/smokeping_secrets.dist
+boomer
display_name=boomer
color=0000ff

+slave2
display_name=another
color=00ff00

*** Targets ***

probe = FPing

menu = Top
#title = Network Latency Grapher
title = IDC网络节点质量监控
#remark = Welcome to the SmokePing website of xxx Company. \
#         Here you will learn all about the latency of our network.
remark = Smokeping 网络质量监控系统


+ TELCOM

menu = 电信

title = 电信

++ north
menu = 华北区

title = 华北区


+++ beijing
menu = 北京

title = 北京:218.30.25.45

host = 218.30.25.45


+++ tianjin
menu = 天津

title = 天津:219.150.32.132

host = 219.150.32.132


+++ shijiazhuang
menu = 石家庄

title = 石家庄:123.180.0.1

host = 123.180.0.1


+++ huhehaote
menu = 呼和浩特

title = 呼和浩特:219.148.168.218

host = 219.148.168.218

++ northeast
menu = 东北区

title = 东北区


+++ qiqihaer
menu = 齐齐哈尔

title = 齐齐哈尔:222.170.0.61

host = 222.170.0.61


+++ changchun
menu = 长春

title = 长春:222.168.78.1

host = 222.168.78.1


+++ jilin
menu = 吉林

title = 吉林:123.173.127.2

host = 123.173.127.2

++ east
menu = 华东区

title = 华东区


+++ jinan
menu = 济南

title = 济南:58.56.25.4

host = 58.56.25.4


+++ shanghai
menu = 上海

title = 上海:116.228.111.118

host = 116.228.111.118


+++ nanjing
menu = 南京

title = 南京:221.231.191.214

host = 221.231.191.214


+++ hefei
menu = 合肥

title = 合肥:61.190.246.5

host = 61.190.246.5


+++ nanchang
menu = 南昌

title = 南昌:202.101.224.68

host = 202.101.224.68


+++ hangzhou
menu = 杭州

title = 杭州:60.191.62.31

host = 60.191.62.31


+++ fuzhou
menu = 福州

title = 福州:202.101.98.55

host = 202.101.98.55

++ south
menu = 中南区

title = 中南区


+++ luoyang
menu = 洛阳

title = 洛阳:123.52.130.12

host = 123.52.130.12


+++ wuhan
menu = 武汉

title = 武汉:111.175.233.30

host = 111.175.233.30


+++ changsha
menu = 长沙

title = 长沙:124.232.134.54

host = 124.232.134.54


+++ guangzhou
menu = 广州

title = 广州:58.61.200.1

host = 58.61.200.1


+++ shenzhen
menu = 深圳

title = 深圳:58.60.3.102

host = 58.60.3.102


+++ nanning
menu = 南宁

title = 南宁:222.217.164.38

host = 222.217.164.38


+++ haikou
menu = 海口

title = 海口:218.77.149.238

host = 218.77.149.238

++ southwest
menu = 西南区

title = 西南区


+++ chengdu
menu = 成都

title = 成都:61.157.77.1

host = 61.157.77.1


+++ chongqing
menu = 重庆

title = 重庆:218.70.65.254

host = 218.70.65.254


+++ guiyang
menu = 贵阳

title = 贵阳:59.51.128.31

host = 59.51.128.31


+++ kunming
menu = 昆明

title = 昆明:222.172.200.5
host = 222.172.200.5


+++ lasa
menu = 拉萨

title = 拉萨:124.31.0.1

host = 124.31.0.1

++ northwest
menu = 西北区

title = 西北区


+++ xian
menu = 西安

title = 西安:125.76.191.163
alerts = someloss
host = 125.76.191.163


+++ ningxia
menu = 宁夏

title = 宁夏:124.224.255.54

host = 124.224.255.54


+++ lanzhou
menu = 兰州

title = 兰州:61.178.252.218

host = 61.178.252.218


+++ xining
menu = 西宁

title = 西宁:223.220.241.26

host = 223.220.241.26


+++ wulumuqi
menu = 乌鲁木齐

title = 乌鲁木齐:61.128.96.1

host = 61.128.96.1

+ UNICOM
menu = 联通

title = 联通


++ north
menu = 华北区

title = 华北区


+++ beijing
menu = 北京

title = 北京:61.135.150.3

host = 61.135.150.3


+++ tianjin
menu = 天津

title = 天津:202.99.96.38

host = 202.99.96.38
+++ shijiazhuang
menu= 石家庄

title = 石家庄:221.192.1.221

host = 221.192.1.221


+++ taiyuan
menu = 太原

title = 太原:218.26.171.2

host = 218.26.171.2

++ northeast
menu = 东北区

title = 东北区


+++ changchun
menu = 长春

title = 长春:125.32.127.2

host = 125.32.127.2


+++ shenyang
menu = 沈阳

title = 沈阳:218.60.54.164

host = 218.60.54.164


+++ jilin
menu = 吉林

title = 吉林:218.62.77.121

host = 218.62.77.121

++ east
menu = 华东区

title = 华东区


+++jinan
menu = 济南

title = 济南:221.0.2.41
host = 221.0.2.41


+++ shanghai
menu = 上海

title = 上海:210.22.67.1

host = 210.22.67.1


+++ hangzhou
menu = 杭州

title = 杭州:101.68.92.11

host = 101.68.92.11


+++ nanchang
menu = 南昌

title = 南昌:118.212.189.129

host = 118.212.189.129

++ south
menu = 中南区

title = 中南区


+++ zhengzhou
menu = 郑州

title = 郑州:61.168.254.211

host = 61.168.254.211


+++ wuhan
menu = 武汉

title = 武汉:218.106.115.1

host = 218.106.115.1


+++ guangzhou
menu = 广州

title = 广州:211.95.193.69

host = 211.95.193.69


+++ shenzhen
menu = 深圳

title = 深圳:58.250.0.1

host = 58.250.0.1


+++ nanning
menu = 南宁

title = 南宁:211.97.71.202

host = 211.97.71.202

++ southwest
menu = 西南区

title = 西南区


+++ chongqing
menu = 重庆

title = 重庆:221.5.255.1

host = 221.5.255.1
++ northwest
menu = 西北区

title = 西北区


+++ xining
menu = 西宁

title = 西宁:221.207.27.1

host = 221.207.27.1

++ ceshiqu
menu = 测试区1

title = 测试区1


+++ test1
menu = 长春联通

title = 长春联通:119.48.221.29

host = 119.48.221.29



+++ test2
menu = 广东网通

title = 广东网通:120.84.0.1

host = 120.84.0.1


+++ test3
menu = 上海网通

title = 上海网通:210.22.67.1

host = 210.22.67.1


+++ test4
menu = 海南网通

title = 海南网通:221.11.132.2

host = 221.11.132.2


+++ test5
menu = 贵州联通

title = 贵州联通:221.13.21.194

host = 221.13.21.194


+++ test6
menu = 广西联通

title = 广西联通:221.7.136.68

host = 221.7.136.68


+++ test7
menu = 北京联通

title = 北京联通:60.30.128.1

host = 60.30.128.1



+++ test8
menu = 北京移动

title = 北京移动:218.205.128.1

host = 218.205.128.1



+++ test9
menu = 海口移动

title = 海口移动:221.182.227.1

host = 221.182.227.1


+++ test10
menu = 武汉铁通

title = 武汉铁通:61.232.206.1

host = 61.232.206.1

+ CMCC
menu = 移动

title = 移动


++ north
menu = 华北区

title = 华北区


+++ beijing
menu = 北京

title = 北京:221.130.33.1

host = 221.130.33.1


+++ tianjin
menu = 天津

title = 天津:211.137.160.1

host = 211.137.160.1


+++ qinhuangdao
menu = 秦皇岛

title = 秦皇岛:211.143.111.14

host = 211.143.111.14


+++ shijiazhuang
menu = 石家庄

title = 石家庄:111.11.64.142

host = 111.11.64.142


++ northeast
menu = 东北区

title = 东北区


+++ dalian
menu = 大连

title = 大连:211.140.192.4

host = 211.140.192.4


++ east
menu = 华东区

title = 华东区


+++ hefei
menu = 合肥

title = 合肥:211.138.191.65

host = 211.138.191.65


+++ nanjing
menu = 南京

title = 南京:120.195.118.1

host = 120.195.118.1


+++ jinan
menu = 济南

title = 济南:120.192.97.186

host = 120.192.97.186


+++ hangzhou
menu = 杭州

title = 杭州:111.1.33.222

host = 111.1.33.222


+++ nanchang
menu = 南昌

title = 南昌:218.204.68.41

host = 218.204.68.41


+++ jiangsu
menu = 江苏

title = 江苏:112.22.15.226

host = 112.22.15.226


++ south
menu = 中南区

title = 中南区


+++ zhengzhou
menu = 郑州

title = 郑州:211.142.127.33

host = 211.142.127.33


+++ guangzhou
menu = 广州

title = 广州:211.139.145.254

host = 211.139.145.254


+++ wuhan
menu = 武汉

title = 武汉:211.137.79.134

host = 211.137.79.134


+++ nanning
menu = 南宁

title = 南宁:218.204.21.10

host = 218.204.21.10


++ southwest
menu = 西南区

title = 西南区


+++ chengdu
menu = 成都

title = 成都:111.9.16.23

host = 111.9.16.23


+++ chongqing
menu = 重庆

title = 重庆:218.206.10.211

host = 218.206.10.211


++ northwest
menu = 西北区

title = 西北区

+ IDC
menu = IDC线路
title = IDC线路

++ wuxiIDC
menu = 无锡IDC
title = 无锡IDC

+++ wuxiIDCdianxin
menu = 无锡电信
title = 无锡电信:221.228.82.70
host = 221.228.82.70

+++ wuxiIDCBGP
menu = 无锡AC_BGP
title = 无锡AC_BGP:103.21.119.48
host = 103.21.119.48

+++ wuxiliantong
menu = 无锡联通
title = 无锡联通:122.192.69.117
host = 122.192.69.117

++ hulanIDC
menu = 呼兰IDC
title = 呼兰IDC

+++ hulanIDCdianxin
menu = 呼兰电信
title = 呼兰电信:101.227.69.37
host = 101.227.69.37

+++ hulanIDCBGP
menu = 呼兰AC_BGP
title = 呼兰AC_BGP:103.20.251.7
host = 103.20.251.7

+++ hulandianxinBGP
menu = 呼兰电信BGP
title = 呼兰电信BGP:114.141.133.146
host = 114.141.133.146

++ nanhuiIDC
menu = 南汇IDC
title = 南汇IDC

+++ nanhuiIDCdianxin
menu = 南汇电信
title = 南汇电信:222.73.124.239
host = 222.73.124.239

+++ nanhuiIDCliantong
menu = 南汇联通线路
title = 南汇联通:140.207.216.89
host = 140.207.216.89

+++ nanhuiIDCBGP
menu = 南汇电信BGP线路
title = 南汇电信BGP:114.141.132.115
host = 114.141.132.115

++ jinhaiIDC
menu = 金海IDC
title = 金海IDC

+++ jinhaiIDCdianxin
menu = 金海电信线路
title = 金海电信:114.80.200.47
host = 114.80.200.47

+++ jinhaiIDCliantong
menu = 金海联通线路
title = 金海联通:140.207.213.59
host = 140.207.213.59

++ beiaiIDC
menu = 北艾IDC
title = 北艾IDC

+++ beiaiIDCdianxin
menu = 北艾电信线路
title = 北艾电信:114.80.88.51
host = 114.80.88.51

+++ beiaiIDCliantong
menu = 北艾联通线路
title = 北艾联通:112.65.240.161
host = 112.65.240.161

++ kunshanIDC
menu = 昆山IDC
title = 昆山IDC

+++ kunshanIDCdianxin
menu = 昆山电线线路
title = 昆山电信:180.97.81.242
host = 180.97.81.242

+++ kunshanIDCliantong
menu = 昆山联通线路
title = 昆山联通:112.80.41.244
host = 112.80.41.244

++ jinqiaoIDC
menu = 金桥IDC
title = 金桥IDC

+++ jinqiaoIDCdianxin
menu = 金桥电信线路
title = 金桥电信:180.153.240.38
host = 180.153.240.38

+++ jinqiaoIDCliantong
menu = 金桥联通线路
title = 金桥联通:112.65.234.34
host = 112.65.234.34

++ luguIDC
menu = 鲁谷IDC
title = 鲁谷IDC

+++ luguIDCBGP
menu = 鲁谷BGP线路
title = 鲁谷BGP:24.202.141.142
host = 124.202.141.142

++ nujiangIDC
menu = 怒江IDC
title = 怒江IDC

+++ nujiangIDCyidong
menu = 怒江移动线路
title = 怒江移动:221.181.64.2
host = 221.181.64.2

++ changshaIDC
menu = 长沙IDC
title = 长沙IDC

+++ changshaIDCdianxin
menu = 长沙电信线路
title = 长沙电信:124.232.151.250
host = 124.232.151.250

++ yizhangIDC
menu = 亦庄IDC
title = 亦庄IDC

+++ yizhuangIDCBGP
menu = 亦庄BGP线路
title = 亦庄BGP:43.240.245.247
host = 43.240.245.247

++ xianggangIDC
menu = 香港IDC
title = 香港IDC

+++ xianggangIDCBGP
menu = 香港BGP线路
title = 香港BGP:118.193.128.4
host = 118.193.128.4

+++ wuxiMPLS
menu = 无锡AC_BGP
title = 无锡MPLS:10.234.1.254
host = 10.234.1.254

EOF
chmod +x /etc/init.d/smokeping
chkconfig smokeping on
chkconfig httpd on
/etc/init.d/httpd start
/etc/init.d/smokeping start
if [ $? -eq 0 ];then
echo -e "\\033[32m smokeping setup successfull URR：http://$IP/smokeping\\033[0m"
fi
