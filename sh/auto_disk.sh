#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
setup_path=/home

#检测磁盘数量
sysDisk=`cat /proc/partitions|grep -v name|grep -v ram|awk '{print $4}'|grep -v '^$'|grep -v '[0-9]$'|grep -v 'vda'|grep -v 'xvda'|grep -v 'sda'|grep -e 'vd' -e 'sd' -e 'xvd'`
if [ "${sysDisk}" == "" ]; then
	echo -e "ERROR!This server has only one hard drive,exit"
	echo -e "此服务器只有一块磁盘,无法挂载"
	echo -e "Bye-bye"
	exit;
fi
#检测/home目录是否已挂载磁盘
mountDisk=`df -h | awk '{print $6}' |grep home`
if [ "${mountDisk}" != "" ]; then
	echo -e "home directory has been mounted,exit"
	echo -e "home目录已被挂载,不执行任何操作"
	echo -e "Bye-bye"
	exit;
fi
#检测是否有windows分区
winDisk=`fdisk -l |grep "NTFS\|FAT32"`
if [ "${winDisk}" != "" ];then
	echo 'Warning: The Windows partition was detected. For your data security, Mount manually.';
	echo "危险 数据盘为windwos分区，为了你的数据安全，请手动挂载，本脚本不执行任何操作。"
	exit;
fi
echo -e "———————————————————————————
\033[1mＫＡＮＧＬＥＳＯＦＴ\033[0m
\033[32m自动磁盘挂载工具\033[0m
———————————————————————————
即将分区并挂载数据盘到${setup_path}
"


#数据盘自动分区
fdiskP(){
	
	for i in `cat /proc/partitions|grep -v name|grep -v ram|awk '{print $4}'|grep -v '^$'|grep -v '[0-9]$'|grep -v 'vda'|grep -v 'xvda'|grep -v 'sda'|grep -e 'vd' -e 'sd' -e 'xvd'`;
	do
		#判断指定目录是否被挂载
		isR=`df -P|grep $setup_path`
		if [ "$isR" != "" ];then
			echo "Error: The $setup_path directory has been mounted."
			return;
		fi
		
		isM=`df -P|grep '/dev/${i}1'`
		if [ "$isM" != "" ];then
			echo "/dev/${i}1 has been mounted."
			continue;
		fi
			
		#判断是否存在未分区磁盘
		isP=`fdisk -l /dev/$i |grep -v 'bytes'|grep "$i[1-9]*"`
		if [ "$isP" = "" ];then
				#开始分区
				fdisk -S 56 /dev/$i << EOF
n
p
1


wq
EOF

			sleep 5
			#检查是否分区成功
			checkP=`fdisk -l /dev/$i|grep "/dev/${i}1"`
			if [ "$checkP" != "" ];then
				#格式化分区
				mkfs.ext4 /dev/${i}1
				mkdir $setup_path
				#挂载分区
				sed -i "/\/dev\/${i}1/d" /etc/fstab
				echo "/dev/${i}1    $setup_path    ext4    defaults    0 0" >> /etc/fstab
				mount -a
				df -h
			fi
		else
			#判断是否存在Windows磁盘分区
			isN=`fdisk -l /dev/$i|grep -v 'bytes'|grep -v "NTFS"|grep -v "FAT32"`
			if [ "$isN" = "" ];then
				echo 'Warning: The Windows partition was detected. For your data security, Mount manually.';
				return;
			fi
			
			#挂载已有分区
			checkR=`df -P|grep "/dev/$i"`
			if [ "$checkR" = "" ];then
					mkdir $setup_path
					sed -i "/\/dev\/${i}1/d" /etc/fstab
					echo "/dev/${i}1    $setup_path    ext4    defaults    0 0" >> /etc/fstab
					mount -a
					df -h
			fi
			
			#清理不可写分区
			echo 'True' > $setup_path/checkD.pl
			if [ ! -f $setup_path/checkD.pl ];then
					sed -i "/\/dev\/${i}1/d" /etc/fstab
					mount -a
					df -h
			else
					rm -f $setup_path/checkD.pl
			fi
		fi
	done
}
stop_service(){
	/vhs/kangle/bin/kangle -q
	service mysqld stop
	killall kangle
}

start_service()
{
	/vhs/kangle/bin/kangle
	service mysqld start
}

while [ "$go" != 'y' ] && [ "$go" != 'n' ]
do
	read -p "Do you want to try to mount the data disk to the $setup_path directory?(y/n): " go;
done

if [ "$go" = 'n' ];then
	echo -e "Bye-bye"
	exit;
fi

if [ -f "/vhs/kangle/bin/kangle" ] && [ -d "/home/ftp" ]; then
	disk=`cat /proc/partitions|grep -v name|grep -v ram|awk '{print $4}'|grep -v '^$'|grep -v '[0-9]$'|grep -v 'vda'|grep -v 'xvda'|grep -v 'sda'|grep -e 'vd' -e 'sd' -e 'xvd'`
	diskFree=`cat /proc/partitions |grep ${disk}|awk '{print $3}'`
	wwwUse=`du -sh -k /home|awk '{print $1}'`

	if [ "${diskFree}" -lt "${wwwUse}" ]; then
		echo -e "Sorry,your data disk is too small,can't coxpy to the home."
		echo -e "对不起，你的数据盘太小,无法迁移home目录数据到此数据盘"
		exit;
	else
		echo -e ""
		echo -e "stop kangle and mysql"
		echo -e "停止Kangle与MySQL服务"
		echo -e ""
		sleep 3
		stop_service
		echo -e ""
		mv /home /home-backup
		echo -e "disk partition..."
		echo -e "磁盘分区..."
		sleep 2
		echo -e ""
		fdiskP
		echo -e ""
		echo -e "move disk..."
		echo -e "迁移数据中..."
		\cp -r -p -a /home-backup/* /home
		echo -e ""
		echo -e "Done"
		echo -e "迁移完成"
		echo -e ""
		echo -e "start kangle and mysql"
		echo -e "启动Kangle与MySQL服务"
		echo -e ""
		start_service
	fi
else
	fdiskP
	echo -e ""
	echo -e "Done"
	echo -e "挂载成功"
fi

