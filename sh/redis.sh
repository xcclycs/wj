#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8
files="/root/s-hell"
tmpfile="/root/hl-tmp"
source $files/config
source $files/iver
redis_version=$REDIS_VERSION
release=`cat /etc/redhat-release 2>/dev/null | sed 's/.*release\ //' | sed 's/\ .*//' | cut -d '.' -f1 | head -1`;

function Install()
{

if [ -f /usr/local/bin/redis-server ];then
	echo -e "\033[32mRedis已安装过，请勿重复安装！\033[0m"
	exit 1;
fi

yum -y install gcc automake autoconf libtool make

groupadd redis
useradd -g redis -s /sbin/nologin redis

VM_OVERCOMMIT_MEMORY=$(cat /etc/sysctl.conf|grep vm.overcommit_memory)
NET_CORE_SOMAXCONN=$(cat /etc/sysctl.conf|grep net.core.somaxconn)
if [ -z "${VM_OVERCOMMIT_MEMORY}" ] && [ -z "${NET_CORE_SOMAXCONN}" ];then
	echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
	echo "net.core.somaxconn = 1024" >> /etc/sysctl.conf
	sysctl -p
fi

cd $tmpfile
wget -O redis-$redis_version.tar.gz http://download.redis.io/releases/redis-$redis_version.tar.gz
tar zxvf redis-$redis_version.tar.gz
cd redis-$redis_version
make && make install
if test $? != 0; then
	echo -e "————————————————————————————————————————————————————
Redis ${redis_version} 安装失败！
————————————————————————————————————————————————————";
exit 1
fi

if [ ! -d /home/redis ];then
	mkdir -p /home/redis
	chown redis:redis /home/redis
fi

if [ ! -d /var/log/redis ];then
	mkdir -p /var/log/redis
	chown redis:redis /var/log/redis
fi

if [ ! -f /etc/redis/redis.conf ];then
	mkdir -p /etc/redis
	\cp ./redis.conf /etc/redis/redis.conf
	sed -i 's/daemonize no/daemonize yes/' /etc/redis/redis.conf
	sed -i 's/# supervised auto/supervised auto/' /etc/redis/redis.conf
	sed -i 's/logfile ""/logfile "\/var\/log\/redis\/redis.log"/' /etc/redis/redis.conf
	sed -i 's/dir .\//dir \/home\/redis\//' /etc/redis/redis.conf
	chown redis:redis /etc/redis -R
fi

if [ "$release" == "6" ];then
	wget -O /etc/init.d/redis http://f.cccyun.cc/redis/redis.init
	chmod +x /etc/init.d/redis

	chkconfig --add redis
	chkconfig redis on
	service redis start
else
	wget -O /usr/lib/systemd/system/redis.service http://f.cccyun.cc/redis/redis.service

	systemctl daemon-reload
	systemctl enable redis
	systemctl start redis
fi

cd ..
rm -rf redis-$redis_version redis-$redis_version.tar.gz

echo -e "=================================================================="
echo -e "\033[32mRedis ${redis_version} 安装成功！\033[0m"
echo -e "=================================================================="
echo  "连接地址: 127.0.0.1:6379"
echo  "连接命令: redis-cli -h 127.0.0.1 -p 6379"
echo  "配置文件: /etc/redis/redis.conf"
echo -e "=================================================================="

}

function Upgrade()
{

if [ ! -f /usr/local/bin/redis-server ];then
	echo -e "\033[32mRedis未安装，请先执行安装命令！\033[0m"
	exit 1;
fi

cd $tmpfile
wget -O redis-$redis_version.tar.gz http://download.redis.io/releases/redis-$redis_version.tar.gz
tar zxvf redis-$redis_version.tar.gz
cd redis-$redis_version
make
make install
systemctl restart redis

cd ..
rm -rf redis-$redis_version redis-$redis_version.tar.gz

echo -e "=================================================================="
echo -e "\033[32mRedis ${redis_version} 升级成功！\033[0m"
echo -e "=================================================================="

}

function Uninstall()
{

if [ "$release" == "6" ];then
	service redis stop
	chkconfig redis off
	chkconfig --del redis
	rm -f /etc/init.d/redis
else
	systemctl stop redis
	systemctl disable redis
	rm -f /usr/lib/systemd/system/redis.service
fi

rm -f /usr/local/bin/redis-*
rm -rf /home/redis
rm -rf /etc/redis

echo -e "=================================================================="
echo -e "\033[32mRedis ${redis_version} 卸载成功！\033[0m"
echo -e "=================================================================="

}


function Install_EXT()
{
	echo -e "———————————————————————————
\033[32m[Notice]\033[0m 请选择要安装Redis扩展的PHP版本："
	select selected in 'PHP 5.3' 'PHP 5.4' 'PHP 5.5' 'PHP 5.6' 'PHP 7.1' 'PHP 7.2' 'PHP 7.3' 'PHP 7.4' 'PHP 8.0' 'PHP 8.1' 'PHP 8.2' 'PHP 8.3' 'PHP 8.4'; do break; done;

	PHP_VER_D=$(echo $selected | awk '{print tolower($0)}' | sed 's/[ .]//g')

	echo -e "\033[32m[OK]\033[0m You Selected: ${selected}";

	if [ ! -d /vhs/kangle/ext/$PHP_VER_D ]; then
		echo "$selected 未安装！";Install_EXT;exit 0;
	fi

	cd $tmpfile
	wget -O phpredis-${PHP_REDIS_VERSION}.zip $DOWNLOAD_FILE_URL/file/phpredis-${PHP_REDIS_VERSION}.zip
	rm -rf phpredis-${PHP_REDIS_VERSION}
	unzip -o phpredis-${PHP_REDIS_VERSION}.zip
	cd phpredis-${PHP_REDIS_VERSION}
	/vhs/kangle/ext/$PHP_VER_D/bin/phpize
	./configure --with-php-config=/vhs/kangle/ext/$PHP_VER_D/bin/php-config
	if test $? != 0; then
		echo -e "=================================================================="
		echo -e "\033[33m为 ${selected} 安装 PHP-Redis 扩展失败！\033[0m"
		echo -e "=================================================================="
		exit 1
	fi
	make
	make install
	#PHP_INI_FILE=/vhs/kangle/ext/$PHP_VER_D/php-templete.ini
	#if [ `grep -c "extension=redis.so" $PHP_INI_FILE` -eq '0' ];then
	#	sed -i '/\[PHP\]/i extension=redis.so' $PHP_INI_FILE;
	#fi
	PHP_INI_FILE=/vhs/kangle/ext/$PHP_VER_D/lib/php.ini
	if [ `grep -c "extension=redis.so" $PHP_INI_FILE` -eq '0' ];then
		sed -i '/\[PHP\]/i extension=redis.so' $PHP_INI_FILE;
	fi
	cd ..
	rm -rf phpredis-${PHP_REDIS_VERSION} phpredis-${PHP_REDIS_VERSION}.zip
	service kangle restart
	echo -e "=================================================================="
	echo -e "\033[32m为 ${selected} 安装 PHP-Redis 扩展成功！\033[0m"
	echo -e "=================================================================="
}

function Install_Admin()
{
	PREFIX="/vhs/kangle/nodewww/dbadmin"
	cd $PREFIX
	wget -O phpRedisAdmin-${PHP_REDIS_ADMIN}.zip $DOWNLOAD_FILE_URL/file/phpRedisAdmin-${PHP_REDIS_ADMIN}.zip
	rm -rf phpRedisAdmin
	unzip -o phpRedisAdmin-${PHP_REDIS_ADMIN}.zip
	rm -rf $PREFIX/redis
	mv -f $PREFIX/phpRedisAdmin $PREFIX/redis
	rm -f phpRedisAdmin-${PHP_REDIS_ADMIN}.zip

	passwd=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 15`
	sed -i "s/adminpassword/"$passwd"/" $PREFIX/redis/includes/config.inc.php

	IP=`curl -s http://members.3322.org/dyndns/getip`;
	echo -e "=================================================================="
	echo -e "\033[32mphpRedisAdmin 安装成功！\033[0m"
	echo -e "访问地址: http://"$IP":3313/redis/"
	echo -e "用户名: admin"
	echo -e "密码: "$passwd""
	echo -e "=================================================================="
}

function Init(){
clear
echo -e "==================================================================
	\033[32mRedis ${redis_version} 安装菜单\033[0m
	请输入以下数字继续操作
==================================================================
1. ◎ 安装 Redis ${redis_version}
2. ◎ 升级 Redis ${redis_version}
3. ◎ 卸载 Redis
4. ◎ 安装 PHP-Redis 扩展
5. ◎ 安装 phpRedisAdmin
0. ◎ 退出安装"
read -p "请输入序号并回车：" num
case "$num" in
[1] ) (Install);;
[2] ) (Upgrade);;
[3] ) (Uninstall);;
[4] ) (Install_EXT);;
[5] ) (Install_Admin);;
[0] ) (exit);;
*) (Init);;
esac
}

Init
