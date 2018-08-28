#!/bin/bash
#auth:kaliarch

# ping可执行路径
PINGCMD=/usr/bin/ping
# zabbix_sender可执行文件路径
SENDCMD=/usr/bin/zabbix_sender
# ping测主机ip地址
CHECKHOST=baidu.com11
# zabbix服务器ip地址
ZABBIXSERVER=43.254.55.225
# zabbix服务器监听端口
ZABBIXPORT=10051
# zabbix添加这条监控主机名
LOCALHOST=checkping_monitor
# ping包的数量
PAG_NUM=1
# 添加监控项的键值
ZAX_KEY=ping_response


# 获取ping响应时间
check_ping() {
   $PINGCMD -c $PAG_NUM $CHECKHOST >/dev/null 2>&1
   if [ $? -eq 0 ];then
        RESPONSE_TIME=`$PINGCMD -c $PAG_NUM -w 1 $CHECKHOST |head -2 |tail -1|awk '{print $(NF-1)}'|cut -d= -f2`
        echo $RESPONSE_TIME
   else
        echo 0
   fi
}

# 发送数据到zabbixserver
send_data() {
  DATA=`check_ping`
  $SENDCMD -z $ZABBIXSERVER -s $LOCALHOST -k $ZAX_KEY -o $DATA
}

while true
do
        send_data
        sleep 0.5
done
