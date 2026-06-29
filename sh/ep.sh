#!/bin/bash
files="/root/s-hell"
source $files/config
source $files/iver
PREFIX="/vhs/kangle"
force_install=$1

ARCH="x86"
if test `arch` = "x86_64"; then
	ARCH="x86_64"
fi
SYSVERSION="6"

function setup_easypanel
{	
	# chmod 700 $PREFIX/etc $PREFIX/var $PREFIX/nodewww/data
	EA_FILE_NAME="easypanel-$EASYPANEL_VERSION-$ARCH-$SYSVERSION.tar.gz"
	rm -rf easypanel-$EASYPANEL_VERSION-$ARCH
	rm -rf $EA_FILE_NAME
	wget $DOWNLOAD_FILE_URL/file/completed/$EA_FILE_NAME -O $EA_FILE_NAME
	if [ $? != 0 ] ; then
        exit $?
	fi
	
	tar xzf $EA_FILE_NAME
	if [ $? != 0 ] ; then
        exit $?
	fi

	\cp -a easypanel-$EASYPANEL_VERSION-$ARCH/* /vhs/kangle/
	if [ -d $PREFIX/nodewww/webftp/dns ] ; then
		rm -rf $PREFIX/nodewww/webftp/dns
	fi
	if [ -d $PREFIX/nodewww/webftp/framework/templates_c/default/ ] ; then
		rm -rf $PREFIX/nodewww/webftp/framework/templates_c/default/*;
	fi
	chmod 700 $PREFIX/nodewww/tmp

	if [ ! -f $PREFIX/etc/server.crt ] && [ ! -f $PREFIX/etc/server.key ]; then
		address=`curl -s http://members.3322.org/dyndns/getip`
		if [ "$address" == "" ];then
			address='Easypanel';
		fi
		openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 -subj "/C=CN/ST=Easypanel/L=Easypanel/O=Easypanel/OU=Easypanel/CN=$address" -keyout $PREFIX/etc/server.key -out $PREFIX/etc/server.crt;
	fi

	service kangle restart

	# 1.6.3 add mysql && mysqldump to /vhs/kangle/bin
	if [ ! -f /vhs/kangle/bin/mysql ] ; then
		ln -s /usr/bin/mysql /vhs/kangle/bin/mysql
	fi
	if [ ! -f /vhs/kangle/bin/mysqldump ] ; then
		ln -s /usr/bin/mysqldump /vhs/kangle/bin/mysqldump
	fi
	if [ ! -f /vhs/kangle/bin/wget ] ; then
		ln -s /usr/bin/wget /vhs/kangle/bin/wget
	fi

	rm -rf easypanel-$EASYPANEL_VERSION-$ARCH $EA_FILE_NAME

	echo -e "————————————————————————————————————————————————————
easypanel-$EASYPANEL_VERSION-$ARCH-$SYSVERSION 安装成功！
————————————————————————————————————————————————————"
}

function setup_webalizer
{
	if [ ! -f /usr/bin/webalizer ] ; then
		yum -y install webalizer
	fi
	chkconfig httpd off
	chkconfig nginx off
	rm -f /vhs/kangle/bin/webalizer
	if [ -f /usr/bin/webalizer ]; then
		ln -s /usr/bin/webalizer /vhs/kangle/bin/webalizer
	fi
}

function setup_7z()
{
	rm -f $PREFIX/bin/7z
	release=`cat /etc/redhat-release 2>/dev/null | sed 's/.*release\ //' | sed 's/\ .*//' | cut -d '.' -f1 | head -1`;
	if [ "$release" = "6" ]; then
		yum -y install p7zip
		ln -s /usr/bin/7za $PREFIX/bin/7z
	else
		FILE7Z="7z${P7ZIP_VERSION}-$ARCH.tar.gz"
		wget $DOWNLOAD_FILE_URL/file/$FILE7Z -O $FILE7Z
		tar xzf $FILE7Z
		mv 7z $PREFIX/bin
		chmod 755 $PREFIX/bin/7z
		rm -f $FILE7Z
	fi
	echo -e "———————————————————————————————————————
7-Zip ${P7ZIP_VERSION} 安装成功！
———————————————————————————————————————"
}

service httpd stop
service nginx stop
setup_easypanel
setup_webalizer
setup_7z

wget  http://localhost:3312/upgrade.php -O /dev/null -q
echo "

"