#!/bin/bash
#func:scan file
#md5sum -c $SCAN_FILE


SCAN_DIR=`echo $PATH |sed 's/:/ /g'`
SCAN_CMD=`which md5sum`
SCAN_FILE_FAIL="/tmp/scan_$(date +%F%H%m)_fall.txt"
SCAN_FILE_BIN="/tmp/scan_$(date +%F%H%m)_bin.txt"

scan_fall_disk() {
	echo "正在全盘扫描，请稍等！文件路径:$SCAN_FILE_FALL"
	find / -type f ! -path "/proc/*" -exec $SCAN_CMD \{\} \;>> $SCAN_FILE_FAIL 2>/dev/null
	echo "扫描完成,可利用以下命令后期对文件进行校验"
	echo "$SCAN_CMD -c $SCAN_FILE_FAIL |grep -v 'OK$'"
}

scan_bin() {
	echo "正在扫描$PATH可执行文件，请稍等，文件路径：$SCAN_FILE_BIN"
	for file in $SCAN_DIR
	do
		find $file -type f -exec $SCAN_CMD \{\} \;>> $SCAN_FILE_BIN 2>/dev/null
	done
	echo "扫描完成,可利用以下命令后期对文件进行校验"
	echo "$SCAN_CMD -c $SCAN_FILE_BIN |grep -v 'OK$'"
}

clear
echo "##########################################"
echo "#                                        #"
echo "#        利用md5sum对文件进行校验        #"
echo "#                                        #"
echo "##########################################"
echo "1: 全盘扫描"
echo "2: bin path扫描"
echo "3: EXIT"
# 选择扫描方式
read -p "Please input your choice:" method
case $method in 
1)
	scan_fall_disk;;
2)
	scan_bin;;
3)
        echo "you choce channel!" && exit 1;;
*)
	echo "input Error! Place input{1|2|3}" && exit 0;;
esac
        
