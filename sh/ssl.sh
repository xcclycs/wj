#!/bin/bash
files="/root/s-hell"
source $files/config
source $files/iver

VHS_DB="/vhs/kangle/etc/vhs.db";
VhostName="";
VhostDir="";
VhostSubDir="";
SubDir="";
Domain="";
DomainCmd="";

clear;
echo -e "———————————————————————————
\033[1mＫＡＮＧＬＥＳＯＦＴ\033[0m
\033[32mLet's Encrypt申请ssl工具\033[0m
———————————————————————————
"
if [ ! -f $VHS_DB ]; then
	echo -e "\033[33m[Error] 未安装Kangle+Easypanel\033[0m";
	exit 1;
fi

function Install_acme()
{
	if [ ! -f "/usr/bin/acme.sh" ]; then
		wget -O acme.sh $DOWNLOAD_FILE_URL/file/acme.sh
		mv -f acme.sh /usr/bin
		chmod +x /usr/bin/acme.sh
	else
		CUR_VER=`head -5 /usr/bin/acme.sh | grep 'VER=' | cut -d '=' -f2`
		if [ "$CUR_VER" != "$ACME_VERSION" ]; then
			wget -O acme.sh $DOWNLOAD_FILE_URL/file/acme.sh
			mv -f acme.sh /usr/bin
			chmod +x /usr/bin/acme.sh
		fi
	fi;
}

function Input_Vhost()
{
	echo "";
	read -p "请输入EP网站用户名: " VhostName;
	[ "$VhostName" == '' ] && Input_Vhost;
	vhost_name=`sqlite3 $VHS_DB "select name from vhost where name='$VhostName';"`
	if [ -z "$vhost_name" ]; then
		echo -e "\033[33m[Error] 网站用户名不存在\033[0m";
		Input_Vhost;
	fi
	vhost_status=`sqlite3 $VHS_DB "select status from vhost where name='$VhostName';"`
	if [ "$vhost_status" != "0" ]; then
		echo -e "\033[33m[Error] 当前网站非正常状态\033[0m";
		Input_Vhost;
	fi
	vhost_port=`sqlite3 $VHS_DB "select port from vhost where name='$VhostName';"`
	if [ "$(echo $vhost_port | grep '443s')" == "" ]; then
		echo -e "\033[33m[Error] 网站端口未添加443s\033[0m";
		Input_Vhost;
	fi
}

function Input_Dir()
{
	dir_list=(`sqlite3 $VHS_DB "select distinct value from vhost_info where vhost='$VhostName' and type=0;"`)
	if [ "${#dir_list[@]}" == "0" ]; then
		echo -e "\033[33m[Error] $VhostName网站未绑定任何域名\033[0m";
		exit 1;
	fi
	if [ "${#dir_list[@]}" == "1" ]; then
		SubDir=${dir_list[0]}
	else
		echo "";
		echo "$VhostName网站绑定了多个目录，请选择要申请SSL的目录: ";
		select SubDir in ${dir_list[@]}; do break; done;
	fi

	VhostNamePre=`echo $VhostName | cut -c1`;
	VhostDir="/home/ftp/$VhostNamePre/$VhostName";
	VhostSubDir="/home/ftp/$VhostNamePre/$VhostName/$SubDir";
	if [ ! -d $VhostSubDir ]; then
		echo -e "\033[33m[Error] $VhostSubDir 目录不存在\033[0m";
		exit 1;
	fi
}

function Confirm_Domain()
{
	domain_list=(`sqlite3 $VHS_DB "select name from vhost_info where vhost='$VhostName' and type=0 and value='$SubDir' limit 5;"`)
	if [ "${#domain_list[@]}" == "0" ]; then
		echo -e "\033[33m[Error] $VhostName网站的$SubDir目录未找到域名\033[0m";
		exit 1;
	fi
	echo "";
	echo ${domain_list[@]};
	echo "";
	read -p "确认申请为以上域名申请SSL证书吗(y/N): " confirm;
	if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
		exit;
	fi
	Domain=${domain_list[0]};
	DomainCmd=""
	for domain in ${domain_list[@]}; do
		DomainCmd="$DomainCmd -d $domain"
	done
}

function GetSSLCert()
{
	/usr/bin/acme.sh --issue $DomainCmd -w $VhostSubDir --server letsencrypt --force;
	if [ $? != 0 ] ; then
		echo -e "\033[33m[Error] acme申请SSL证书失败\033[0m";
		exit $?
	fi
	SSLDir="/home/ssl/$Domain";
	if [ ! -d $SSLDir ]; then
		SSLDir="/home/ssl/${Domain}_ecc";
	fi
	if [ ! -d $SSLDir ]; then
		echo "———————————————————————————";
		echo -e "\033[32m证书申请成功！请手动将 /home/ssl/ 下面的证书文件配置到网站。\033[0m";
		echo "———————————————————————————";
		exit;
	fi
	\cp -f $SSLDir/$Domain.key $VhostDir/ssl.key;
	\cp -f $SSLDir/fullchain.cer $VhostDir/ssl.crt;
	dir_uid=$(stat --format=%u $VhostDir)
	dir_gid=$(stat --format=%g $VhostDir)
	chown $dir_uid:$dir_gid $VhostDir/ssl.key $VhostDir/ssl.crt
	sqlite3 /vhs/kangle/etc/vhs.db "UPDATE vhost SET certificate = 'ssl.crt', certificate_key = 'ssl.key' WHERE name='$VhostName';"
	service kangle reload
	echo "———————————————————————————";
	echo -e "\033[32m证书申请成功！已自动将证书配置到网站。\033[0m";
	echo "———————————————————————————";
}

mkdir -p /home/ssl;
Install_acme
echo "最多支持一次性申请5个域名的SSL证书";
Input_Vhost
Input_Dir
Confirm_Domain
GetSSLCert
