#!/bin/bash
files="/root/s-hell"
PREFIX="/vhs/kangle"
source $files/config
source $files/iver
release=`cat /etc/redhat-release 2>/dev/null | sed 's/.*release\ //' | sed 's/\ .*//' | cut -d '.' -f1 | head -1`;

if test `arch` != "x86_64"; then
	echo "only support arch x86_64..."
	exit 1
fi

if [ "$release" == "9" ]; then
	ARCH="8"
else
	ARCH=$release
fi
ARCH="$ARCH-x64"

#https://www.cdnbest.com/download/cdnbest/cdnbest-4.6.4-8-x64.tar.gz
URL="$DOWNLOAD_FILE_URL/file/completed/cdnbest-$CDNBEST_VERSION-$ARCH.tar.gz"
wget $URL -O cdnbest.tar.gz
if [ $? != 0 ] ; then
	echo "cann't download cdnbest-$CDNBEST_VERSION-$ARCH.tar.gz"
	exit 1
fi
tar xzf cdnbest.tar.gz
service cdnbest stop
killall cdnbest
cd cdnbest
\cp bin $PREFIX -a

if [ "$release" == "9" ]; then
	if [ -f /etc/init.d/cdnbest ] ; then
		rm -f /etc/init.d/cdnbest
		rm -f /etc/rc.d/rc3.d/S67cdnbest
		rm -f /etc/rc.d/rc5.d/S67cdnbest
	fi
	cat > /lib/systemd/system/cdnbest.service <<-EOF
[Unit]
Description=cdnbest
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/vhs/kangle/bin/daemon -l /var/run/cdnbest.pid -o /var/log/cdnbest.log:100m -- /vhs/kangle/bin/cdnbest
ExecStop=/vhs/kangle/bin/daemon -l /var/run/cdnbest.pid -q
ExecReload=/vhs/kangle/bin/daemon -l $pidfile -r

[Install]
WantedBy=multi-user.target
EOF

	systemctl daemon-reload
	systemctl enable cdnbest

else
	if [ ! -f /etc/init.d/cdnbest ] ; then
		\cp init/cdnbest /etc/init.d/
		chmod 700 /etc/init.d/cdnbest
	fi
	if [ ! -f /etc/rc3.d/S67cdnbest ] ;then
		ln -s /etc/init.d/cdnbest /etc/rc3.d/S67cdnbest
		ln -s /etc/init.d/cdnbest /etc/rc5.d/S67cdnbest
	fi
	if [ -f /usr/bin/systemctl ] ; then
		systemctl daemon-reload
	fi
fi

service cdnbest start

cd ..
rm -rf cdnbest cdnbest.tar.gz
echo -e "———————————————————————————————————————
cdnbest-$CDNBEST_VERSION 安装成功！
———————————————————————————————————————"
