#!/bin/bash
oracle_env() {
    source /home/oracle/.bash_profile  
    export ORACLE_BASE=/home/oracle/app
    export ORACLE_HOME=$ORACLE_BASE/oracle/product/12.1.0/dbhome_1
    export ORACLE_SID=orcl
    export PATH=$PATH:$HOME/bin:$ORACLE_HOME/bin
    oraclecmd="/home/oracle/app/oracle/product/12.1.0/dbhome_1/bin/sqlplus"
    oraclerman="/home/oracle/app/oracle/product/12.1.0/dbhome_1/bin/rman"
}
disk_useper=`/bin/df -Th|grep -v 'Filesystem'|awk '/\/dev\/mapper\/vg00-lv_root/{if ("$(NF)"=="/");print $(NF-1)}'|cut -d% -f1`
 
oracle_clean() {
oracle_env    
${oraclerman} target /<<EOF
DELETE NOPROMPT ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-7';
crosscheck archivelog all;
list expired archivelog all;
delete noprompt expired archivelog all;
exit;
EOF
}
 
main() {
    if [ ${disk_useper} -gt 80 ];then
        oracle_clean
    fi
} 
 
main
