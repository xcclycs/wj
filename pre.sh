#!/bin/bash
files="/root/s-hell"
source $files/config
source $files/iver
install_mysql=$1

is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ];then
	echo -e "
————————————————————————————————————————————————————
您的操作系统不是64位 无法安装 请更换系统
————————————————————————————————————————————————————"
	exit 1
fi

centosCheck=$(cat /etc/redhat-release |grep "release [6-9]" -o)
if [ -z "${centosCheck}" ]; then
	echo -e "
————————————————————————————————————————————————————
您的系统不是 CentOS 6/7/8 系列 无法安装 请更换系统
————————————————————————————————————————————————————"
	exit 1
fi

release=`cat /etc/redhat-release 2>/dev/null | sed 's/.*release\ //' | sed 's/\ .*//' | cut -d '.' -f1 | head -1`;

clear
echo -e "————————————————————————————————————————————————————
	\033[1mＫＡＮＧＬＥＳＯＦＴ\033[0m
	\033[32mKangle一键脚本-开始安装\033[0m
————————————————————————————————————————————————————"

#设置MySQL密码
if [ "$install_mysql" != "no" ]; then
	mysql_root_password=""
	read -p "请输入您需要设置的MySQL密码(留空则随机生成):" mysql_root_password
	if [ "$mysql_root_password" = "" ]; then
	mysql_root_password=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 15`
	fi
	echo '[OK] Your MySQL password is:';
	echo $mysql_root_password;
else
	mysql_root_password="no"
fi

echo -e "———————————————————————————
   \033[32mKangle版本选择\033[0m
   （极速安装均为商业版,经典版均不支持CentOS 7&8）
1. 极速安装 Kangle 3.5.21 最新版(推荐)
2. 编译安装 Kangle 3.5.21 开发版
3. 极速安装 Kangle 3.5.14 稳定版
4. 极速安装 Kangle 3.5.10 经典版
5. 极速安装 Kangle 3.4.8 经典版"
read -p "请输入序号并回车:" YORN
if [ "$YORN" = "2" ]; then
kangle_ver="$KANGLE_VERSION";
kangle_completed="0";
elif [ "$YORN" = "3" ]; then
kangle_ver="3.5.14.13";
kangle_completed="1";
elif [ "$YORN" = "4" ]; then
kangle_ver="$KANGLE_ENT_VERSION";
kangle_completed="1";
elif [ "$YORN" = "5" ]; then
kangle_ver="$KANGLE_OLD_VERSION";
kangle_completed="1";
else
kangle_ver="$KANGLE_NEW_VERSION";
kangle_completed="1";
fi

echo -e "———————————————————————————
   \033[32mPHP版本选择\033[0m
1. 极速安装 PHP5.6-8.4(推荐)
2. 极速安装 PHP5.6
3. 编译安装 PHP5.6-8.4
4. 编译安装 PHP5.6"
read -p "请输入序号并回车:" YORN
if [ "$YORN" = "2" ]; then
select_ver="default";
elif [ "$YORN" = "3" ]; then
select_ver="allc";
elif [ "$YORN" = "4" ]; then
select_ver="defaultc";
else
select_ver="all";
fi

if [ "$install_mysql" != "no" ]; then
	echo -e "———————————————————————————
   \033[32mMySQL版本选择\033[0m
1. MySQL 5.6(默认)
2. MySQL 5.7
3. MySQL 8.0"
	read -p "请输入序号并回车:" YORN
	if [ "$YORN" = "2" ]; then
		mysql_ver="7";
	elif [ "$YORN" = "3" ]; then
		mysql_ver="8";
	else
		mysql_ver="6";
	fi
else
	mysql_ver="6";
fi

echo -e "
————————————————————————————————————————————————————
	Kangle一键脚本检测系统！
————————————————————————————————————————————————————
您的系统为 \033[32mCentOS\033[0m $release 系列
正在继续获取YUM组件安装
————————————————————————————————————————————————————"


if [ "$release" = "6" ];then
	yum_repos_s=`ls /etc/yum.repos.d | wc -l`;
	if [ "$yum_repos_s" == '0' ]; then
		wget -q $DOWNLOAD_FILE_URL/repo/Centos-6.repo -O /etc/yum.repos.d/CentOS-Base.repo
	fi;
	epel_repos_s=`ls /etc/yum.repos.d | grep epel -i | wc -l`;
	if [ "$epel_repos_s" == '0' ]; then
		rpm -ivh $DOWNLOAD_FILE_URL/repo/epel-release-latest-6.noarch.rpm --nodeps --force
		wget -q $DOWNLOAD_FILE_URL/repo/epel-6.repo -O /etc/yum.repos.d/epel.repo
	fi;
	rpm -ivh $DOWNLOAD_FILE_URL/repo/mysql-community-release-el6.rpm --nodeps --force
	if [ "$mysql_ver" = "6" ]; then
		wget -q $DOWNLOAD_FILE_URL/repo/mysql-community-6-el6.repo -O /etc/yum.repos.d/mysql-community.repo
	elif [ "$mysql_ver" = "7" ]; then
		wget -q $DOWNLOAD_FILE_URL/repo/mysql-community-7-el6.repo -O /etc/yum.repos.d/mysql-community.repo
	elif [ "$mysql_ver" = "8" ]; then
		wget -q $DOWNLOAD_FILE_URL/repo/mysql-community-8-el6.repo -O /etc/yum.repos.d/mysql-community.repo
	fi
elif [ "$release" = "7" ];then
	yum_repos_s=`ls /etc/yum.repos.d | wc -l`;
	if [ "$yum_repos_s" == '0' ]; then
		wget -q $DOWNLOAD_FILE_URL/repo/Centos-7.repo -O /etc/yum.repos.d/CentOS-Base.repo
	fi;
	epel_repos_s=`ls /etc/yum.repos.d | grep epel -i | wc -l`;
	if [ "$epel_repos_s" == '0' ]; then
		rpm -ivh $DOWNLOAD_FILE_URL/repo/epel-release-latest-7.noarch.rpm --nodeps --force
		wget -q $DOWNLOAD_FILE_URL/repo/epel-7.repo -O /etc/yum.repos.d/epel.repo
	fi;
	rm -rf /etc/yum.repos.d/mysql-community*
	rpm -ivh $DOWNLOAD_FILE_URL/repo/mysql-community-release-el7.rpm --nodeps --force
	if [ "$mysql_ver" = "6" ]; then
		wget -q $DOWNLOAD_FILE_URL/repo/mysql-community-6-el7.repo -O /etc/yum.repos.d/mysql-community.repo
	elif [ "$mysql_ver" = "7" ]; then
		wget -q $DOWNLOAD_FILE_URL/repo/mysql-community-7-el7.repo -O /etc/yum.repos.d/mysql-community.repo
	elif [ "$mysql_ver" = "8" ]; then
		wget -q $DOWNLOAD_FILE_URL/repo/mysql-community-8-el7.repo -O /etc/yum.repos.d/mysql-community.repo
	fi
elif [ "$release" = "8" ];then
	yum_repos_s=`ls /etc/yum.repos.d | wc -l`;
	if [ "$yum_repos_s" == '0' ]; then
		wget -q $DOWNLOAD_FILE_URL/repo/Centos-8.repo -O /etc/yum.repos.d/CentOS-Base.repo
	fi;
	epel_repos_s=`ls /etc/yum.repos.d | grep epel -i | wc -l`;
	if [ "$epel_repos_s" == '0' ]; then
		rpm -ivh $DOWNLOAD_FILE_URL/repo/epel-release-latest-8.noarch.rpm --nodeps --force
	fi;
	yum config-manager --set-enabled PowerTools
	yum config-manager --set-enabled powertools
	rm -rf /etc/yum.repos.d/mysql-community*
	if [ "$install_mysql" != "no" ] && [ "$mysql_ver" = "6" ]; then
		rpm -ivh $DOWNLOAD_FILE_URL/repo/mysql-community-release-el7.rpm --nodeps --force
		wget -q $DOWNLOAD_FILE_URL/repo/mysql-community-6-el7.repo -O /etc/yum.repos.d/mysql-community.repo
	elif [ "$install_mysql" != "no" ] && [ "$mysql_ver" = "7" ]; then
		rpm -ivh $DOWNLOAD_FILE_URL/repo/mysql-community-release-el7.rpm --nodeps --force
		wget -q $DOWNLOAD_FILE_URL/repo/mysql-community-7-el7.repo -O /etc/yum.repos.d/mysql-community.repo
	fi
elif [ "$release" = "9" ];then
	yum_repos_s=`ls /etc/yum.repos.d | wc -l`;
	epel_repos_s=`ls /etc/yum.repos.d | grep epel -i | wc -l`;
	if [ "$epel_repos_s" == '0' ]; then
		rpm -ivh $DOWNLOAD_FILE_URL/repo/epel-release-latest-9.noarch.rpm --nodeps --force
	fi;
	dnf config-manager --set-enabled crb -y
	rm -rf /etc/yum.repos.d/mysql-community*
	if [ "$install_mysql" != "no" ] && [ "$mysql_ver" = "6" ]; then
		rpm -ivh $DOWNLOAD_FILE_URL/repo/mysql-community-release-el7.rpm --nodeps --force
		wget -q $DOWNLOAD_FILE_URL/repo/mysql-community-6-el7.repo -O /etc/yum.repos.d/mysql-community.repo
	elif [ "$install_mysql" != "no" ] && [ "$mysql_ver" = "7" ]; then
		rpm -ivh $DOWNLOAD_FILE_URL/repo/mysql-community-release-el7.rpm --nodeps --force
		wget -q $DOWNLOAD_FILE_URL/repo/mysql-community-7-el7.repo -O /etc/yum.repos.d/mysql-community.repo
	fi
fi

yum clean all
yum makecache
yum -y remove httpd php mysql mysql-server php-mysql mysql-libs mysql-devel mysql-common mariadb-*;
yum -y install yum-fastestmirror
yum -y install nss curl libcurl psmisc net-tools ca-certificates
#yum -y update
yum -y install make automake cmake patch gcc gcc-c++ zip unzip quota autoconf expect bison flex tar bzip2
yum -y install pcre pcre-devel zlib zlib-devel sqlite sqlite-devel mhash mhash-devel bzip2 bzip2-devel gd gd-devel libtool-libs
yum -y install libtool-ltdl libtool-ltdl-devel libjpeg-devel libpng-devel freetype freetype-devel libjpeg-turbo libtiff libpng
yum -y install libxml2-devel curl-devel libxslt-devel readline-devel glibc-devel glib2-devel gettext-devel libcap-devel libicu-devel gmp-devel libevent-devel c-ares-devel
yum -y install mhash libmcrypt libmcrypt-devel openssl openssl-devel libaio-devel libsodium-devel libwebp-devel lksctp-tools-devel brotli-devel libssh2-devel perl-CPAN
yum -y install libvpx-devel glibc-static
yum -y install ntp cron mcrypt db4-devel

if [ "$release" = "6" ];then
	wget $DOWNLOAD_FILE_URL/file/glibc-2.17.el6.tar.gz
	tar zxvf glibc-2.17.el6.tar.gz
	cd glibc-2.17.el6
	rpm -Uvh *-2.17-55.el6.x86_64.rpm --force --nodeps
	cd ..
	rm -rf glibc-2.17.el6 glibc-2.17.el6.tar.gz
fi

clear
echo
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo 'Synchronizing system time...'
whereis ntpdate | grep '/ntpdate' && ntpdate -u pool.ntp.org;
whereis chronyc | grep '/chronyc' && chronyc makestep;
ulimit -n 1048576
echo "* soft nofile 1048576" >> /etc/security/limits.conf
echo "* hard nofile 1048576" >> /etc/security/limits.conf
clear
echo -e "
————————————————————————————————————————————————————
您的系统已完成YUM组件安装.正在继续进行Kangle安装
————————————————————————————————————————————————————"
wget -q $DOWNLOAD_URL/install.sh -O install.sh;sh install.sh $kangle_ver $kangle_completed $select_ver $mysql_ver $mysql_root_password



