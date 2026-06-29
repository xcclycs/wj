#!/bin/bash
files="/root/s-hell"
source $files/config
source $files/iver
release=`cat /etc/redhat-release 2>/dev/null | sed 's/.*release\ //' | sed 's/\ .*//' | cut -d '.' -f1 | head -1`;
pureftpd_file="pure-ftpd-$PUREFTP_VERSION"
force_install=$1

function setup_pureftpd
{
	if [ -f /vhs/pure-ftpd/sbin/pure-ftpd ] && [ "$force_install" != "force" ]; then
		echo "pure-ftpd is installed!"
		return;
	fi
	if [ ! -f /vhs/kangle/bin/pureftp_auth ] ; then
		echo "/vhs/kangle/bin/pureftp_auth not found"
		exit;
	fi
	del_proftpd

	wget $DOWNLOAD_FILE_URL/file/$pureftpd_file.tar.gz -O $pureftpd_file.tar.gz
	tar xzf $pureftpd_file.tar.gz
	cd $pureftpd_file
	./configure --prefix=/vhs/pure-ftpd CFLAGS=-O2 --with-cookie --with-extauth --with-throttling --with-ratios --with-peruserlimits --with-tls --with-ftpwho
	if [ $? != 0 ] ; then
		echo "$pureftpd_file 生成编译脚本失败!"
		exit $?
	fi
	make
	if [ $? != 0 ] ; then
		echo "$pureftpd_file 编译失败!"
		exit $?
	fi
	make install
	cd ..
	rm -rf $pureftpd_file $pureftpd_file.tar.gz

	if [ "$release" == "9" ]; then
		if [ -f /etc/init.d/pureftpd ] ; then
			rm -f /etc/init.d/pureftpd
			rm -f /etc/rc.d/rc3.d/S96pureftpd
			rm -f /etc/rc.d/rc5.d/S96pureftpd
		fi
		wget -O /vhs/pure-ftpd/sbin/pureftpd.sh $DOWNLOAD_URL/config_file/pureftpd.init
		chmod +x /vhs/pure-ftpd/sbin/pureftpd.sh
		cat > /lib/systemd/system/pureftpd.service <<-EOF
[Unit]
Description=Pure-FTPd FTP Server
After=syslog.target

[Service]
Type=forking
ExecStart=/vhs/pure-ftpd/sbin/pureftpd.sh start

[Install]
WantedBy=multi-user.target
EOF

		systemctl daemon-reload
		systemctl enable pureftpd

	else
		wget -O /etc/init.d/pureftpd $DOWNLOAD_URL/config_file/pureftpd.init
		chmod +x /etc/init.d/pureftpd
		if [ ! -f /etc/rc.d/rc3.d/S96pureftpd ] ; then
			ln -s /etc/init.d/pureftpd /etc/rc.d/rc3.d/S96pureftpd
			ln -s /etc/init.d/pureftpd /etc/rc.d/rc5.d/S96pureftpd
		fi
		if [ -f /usr/bin/systemctl ] ; then
			systemctl daemon-reload
		fi
	fi

	wget -O /vhs/pure-ftpd/etc/pure-ftpd.conf $DOWNLOAD_URL/config_file/pure-ftpd.conf

	address=`curl -s http://members.3322.org/dyndns/getip`
	if [ "$address" == "" ];then
		address='www.kangleweb.com';
	fi
	mkdir -p /etc/ssl/private
	openssl dhparam -out /etc/ssl/private/pure-ftpd-dhparams.pem 2048
	openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 -subj "/C=CN/ST=Kangle/L=Kangle/O=Kangle/OU=Kangle/CN=$address" -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
	if [ -f '/etc/ssl/private/pure-ftpd.pem' ];then
		chmod 600 /etc/ssl/private/*.pem
		sed -i "s/# TLS/TLS/" /vhs/pure-ftpd/etc/pure-ftpd.conf
	fi

	service pureftpd start
}

function del_proftpd
{
	if [ -f /usr/sbin/proftpd ]; then
		chkconfig proftpd off
		service proftpd stop
	fi
	killall proftpd
	killall pure-authd
	killall pure-ftpd
}

setup_pureftpd
