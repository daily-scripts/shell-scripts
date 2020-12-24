#!/bin/bash
# func: 配合定时任务，linux系统监控自动释放内存

#内存使用超过阀值
WARN_LINE=70
# 日志记录文件
LOG_DIR=/var/log/memfree/
[ ! -d ${LOG_DIR} ] && mkdir -p ${LOG_DIR}
LOG_FILE=$(date +%F)-memefree.log
LOG_TOTLE=${LOG_DIR}${LOG_FILE}

# 内存总量
MEM_TOTLE=$(free  -m | awk 'NR==2{print $2}')

# 内存使用量
MEM_USE=$(free  -m | awk 'NR==2{print $3}')

# 已使用百分比
#USE_PERCENT=$(printf "%5f" `echo "scale=5;${MEM_USE}/${MEM_TOTLE}"|bc`)
USE_PERCENT=$(awk -v use=${MEM_USE} -v totle=${MEM_TOTLE} 'BEGIN{printf "%0.0f",use/totle*100}')

echo ${USE_PERCENT}
if [[ ${USE_PERCENT} -ge ${WARN_LINE} ]];then
        echo "---------$(date +%F" "%T) mem free begin---------" >> ${LOG_TOTLE}
        echo "内存释放前，使用情况如下:" >> ${LOG_TOTLE}
        free -m &>>${LOG_TOTLE}
        sync
        echo 1 > /proc/sys/vm/drop_caches
        echo 2 > /proc/sys/vm/drop_caches
        echo 3 > /proc/sys/vm/drop_caches
        echo "内存释放结束后，使用情况如下:" >> ${LOG_TOTLE}
        free -m &>>${LOG_TOTLE}
        echo "---------$(date +%F" "%T) mem free end---------" >> ${LOG_TOTLE}
fi
