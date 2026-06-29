#!/bin/bash
cronfile="/etc/cron.d/vhms_auto_cron"

read -p "请输入VHMS所在主机用户名:" VHOST

if [ ! -f /home/ftp/${VHOST:0:1}/$VHOST/wwwroot/framework/shell.php ]; then
echo "文件不存在，请重新输入！
"
sh vhms.sh
exit
fi;

cat>$cronfile<<EOF
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
HOME=/
0 */1 * * * root /vhs/kangle/ext/php56/bin/php -c /vhs/kangle/ext/php56/etc/php-node.ini -f /home/ftp/${VHOST:0:1}/$VHOST/wwwroot/framework/shell.php cron
EOF

service crond restart
echo "--------------------
VHMS计划任务设置成功"