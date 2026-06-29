#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8
files="/root/s-hell"
tmpfile="/root/hl-tmp"
source $files/config
source $files/iver
ssh2Ver="1.4.1"

function Install()
{
	PHP_VER=$1
	if [ ! -z "$PHP_VER" ]; then
		selected="PHP ${PHP_VER:0:1}.${PHP_VER:1:1}"
		PHP_VER_D="php${PHP_VER}"
	else
		echo -e "———————————————————————————"
		echo -e "\033[32m[Notice]\033[0m 请选择要安装ssh2扩展的PHP版本："
		select selected in 'PHP 7.0' 'PHP 7.1' 'PHP 7.2' 'PHP 7.3' 'PHP 7.4' 'PHP 8.0' 'PHP 8.1' 'PHP 8.2' 'PHP 8.3' 'PHP 8.4' 'PHP 8.5'; do break; done;

		PHP_VER_D=$(echo $selected | awk '{print tolower($0)}' | sed 's/[ .]//g')
		PHP_VER=$(echo $selected | awk '{print $2}' | sed 's/[ .]//g')
	fi

	echo -e "\033[32m[OK]\033[0m You Selected: ${selected}";

	if [ ! -d /vhs/kangle/ext/$PHP_VER_D ]; then
		echo "$selected 未安装！";Install;exit 0;
	fi
	if [ ! -z `/vhs/kangle/ext/$PHP_VER_D/bin/php -m|grep ssh2` ]; then
		echo "$selected 已安装ssh2扩展！";Install;exit 0;
	fi

	if [ "${PHP_VER}" -ge "80" ]; then
		ssh2Ver="1.5.0"
	fi

	cd $tmpfile
	wget -O ssh2-${ssh2Ver}.tgz $DOWNLOAD_FILE_URL/file/ssh2-${ssh2Ver}.tgz
	tar -xvf ssh2-${ssh2Ver}.tgz
	cd ssh2-${ssh2Ver}
	/vhs/kangle/ext/$PHP_VER_D/bin/phpize
	./configure --with-php-config=/vhs/kangle/ext/$PHP_VER_D/bin/php-config
	make && make install
	if test $? != 0; then
		echo -e "=================================================================="
		echo -e "\033[33m${selected} 安装 ssh2-${ssh2Ver} 扩展失败！\033[0m"
		echo -e "=================================================================="
		exit 1
	fi
	PHP_INI_FILE=/vhs/kangle/ext/$PHP_VER_D/lib/php.ini
	if [ `grep -c "extension=ssh2.so" $PHP_INI_FILE` -eq '0' ];then
		sed -i '/\[PHP\]/i extension=ssh2.so' $PHP_INI_FILE;
	fi
	cd ..
	rm -rf ssh2-${ssh2Ver} package.xml ssh2-${ssh2Ver}.tgz
	service kangle restart
	echo -e "=================================================================="
	echo -e "\033[32m${selected} 安装 ssh2-${ssh2Ver} 扩展成功！\033[0m"
	echo -e "=================================================================="

}

function Uninstall()
{
    echo -e "———————————————————————————
	\033[32m[Notice]\033[0m 请选择要卸载ssh2扩展的PHP版本："
	select selected in 'PHP 7.0' 'PHP 7.1' 'PHP 7.2' 'PHP 7.3' 'PHP 7.4' 'PHP 8.0' 'PHP 8.1' 'PHP 8.2' 'PHP 8.3' 'PHP 8.4' 'PHP 8.5'; do break; done;

	PHP_VER_D=$(echo $selected | awk '{print tolower($0)}' | sed 's/[ .]//g')

	echo -e "\033[32m[OK]\033[0m You Selected: ${selected}";

	if [ ! -d /vhs/kangle/ext/$PHP_VER_D ]; then
		echo "$selected 未安装！";Install;exit 0;
	fi

	PHP_INI_FILE=/vhs/kangle/ext/$PHP_VER_D/lib/php.ini
	sed -i '/extension=ssh2.so/d' $PHP_INI_FILE;

	echo -e "=================================================================="
	echo -e "\033[32m${selected} 卸载 ssh2 扩展成功！\033[0m"
	echo -e "=================================================================="
}

function Init(){
clear
echo -e "==================================================================
	\033[32mssh2扩展安装菜单\033[0m
	请输入以下数字继续操作
==================================================================
1. ◎ 安装 ssh2 扩展
2. ◎ 卸载 ssh2 扩展
0. ◎ 退出安装"
read -p "请输入序号并回车：" num
case "$num" in
[1] ) (Install);;
[2] ) (Uninstall);;
[0] ) (exit);;
*) (Init);;
esac
}

PHP_VER=$1
if [ ! -z "$PHP_VER" ]; then
	Install "$PHP_VER"
else
	Init
fi
