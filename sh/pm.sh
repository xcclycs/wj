#!/bin/bash
files="/root/s-hell"
source $files/config
source $files/iver
PREFIX="/vhs/kangle/nodewww/dbadmin"
Install_version=$PHPMYADMIN;
if [ ! -f /vhs/kangle/ext/php73/bin/php ]; then
	Install_version=$PHPMYADMIN_OLD;
fi
DFILE="phpMyAdmin-${Install_version}-all-languages"

cd $PREFIX
wget $DOWNLOAD_FILE_URL/file/$DFILE.tar.gz -O $DFILE.tar.gz
tar zxf $DFILE.tar.gz
rm -rf $PREFIX/mysql
mv -f $PREFIX/$DFILE $PREFIX/mysql
rm -f $DFILE.tar.gz

wget -q $DOWNLOAD_URL/config_file/dbadmin.xml -O /vhs/kangle/ext/dbadmin.xml
if [ -f /vhs/kangle/ext/php74/bin/php ] ; then
	sed -i "s/cmd:php56/cmd:php74/" /vhs/kangle/ext/dbadmin.xml
elif [ -f /vhs/kangle/ext/php73/bin/php ] ; then
	sed -i "s/cmd:php56/cmd:php73/" /vhs/kangle/ext/dbadmin.xml
fi

service kangle restart

cd -
echo -e "
————————————————————————————————————————————————————
phpMyAdmin-$Install_version 安装成功!
————————————————————————————————————————————————————"
