#!/bin/bash
# mail  xuel@51idc.com
data=`date +%Y-%M-%d" "%H:%m`
netstat -lntup|grep 5432 && ps -ef|grep postmaster
if [ $? -eq 0 ];then
for IP in 172.17.10.188 172.17.10.189
do
/usr/bin/psql -h 172.17.10.190 -p 5432 -U repl -d postgres --command "select * from pg_stat_replication"|grep $IP
if [ "$?" != "0" ];then
echo
 "postgresql master-slave status is error! please login check!"|mail -r 
"xuel@51idc.com" -s "postgresql master-slave status is error" 
xuel@51idc.com \
&& echo "$data postgresql postgresql master-slave status is error!">>/var/log/postgresql-error.log
fi
done
else
echo
 "postgresql master-slave status is error! please login check!"|mail -r 
"xuel@51idc.com" -s "postgresql master-slave status is error" 
xuel@51idc.com \
&& echo "$data postgresql postgresql master-slave status is error!">>/var/log/postgresql-error.log
fi

