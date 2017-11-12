#!/bin/bash

clear
#CheckIfRoot
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

#ReadSSHPort
[ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`

#CheckOS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ];then
	OS=CentOS
	[ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
	[ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
	[ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ];then
	OS=CentOS
	CentOS_RHEL_version=6
elif [ -n "$(grep 'bian' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Debian" ];then
	OS=Debian
	[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
	Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep 'Deepin' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Deepin" ];then
	OS=Debian
	[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
	Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
# kali rolling
elif [ -n "$(grep 'Kali GNU/Linux Rolling' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Kali" ];then
	OS=Debian
	[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
	if [ -n "$(grep 'VERSION="2016.*"' /etc/os-release)" ];then
		Debian_version=8
	else
		echo "${CFAILURE}Does not support this OS, Please contact the author! ${CEND}"
		kill -9 $$
	fi
elif [ -n "$(grep 'Ubuntu' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Ubuntu" -o -n "$(grep 'Linux Mint' /etc/issue)" ];then
	OS=Ubuntu
	[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
	Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
	[ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
elif [ -n "$(grep 'elementary' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'elementary' ];then
	OS=Ubuntu
	[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
	Ubuntu_version=16
else
	echo "${CFAILURE}Does not support this OS, Please contact the author! ${CEND}"
	kill -9 $$
fi
#Read Imformation From The User

while :; do echo
	#read -p "Do you want to change your SSH Port? [y/n]: " IfChangeSSHPort
	IfChangeSSHPort='n'
	if [ ${IfChangeSSHPort} == 'y' ];then
		if [ -e "/etc/ssh/sshd_config" ];then
		[ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`
		while :; do echo
				read -p "Please input SSH port(Default: $ssh_port): " SSH_PORT
				[ -z "$SSH_PORT" ] && SSH_PORT=$ssh_port
				if [ $SSH_PORT -eq 22 >/dev/null 2>&1 -o $SSH_PORT -gt 1024 >/dev/null 2>&1 -a $SSH_PORT -lt 65535 >/dev/null 2>&1 ];then
						break
				else
						echo "${CWARNING}input error! Input range: 22,1025~65534${CEND}"
				fi
		done
		if [ -z "`grep ^Port /etc/ssh/sshd_config`" -a "$SSH_PORT" != '22' ];then
				sed -i "s@^#Port.*@&\nPort $SSH_PORT@" /etc/ssh/sshd_config
		elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ];then
				sed -i "s@^Port.*@Port $SSH_PORT@" /etc/ssh/sshd_config
		fi
		fi
		break
	elif [ ${IfChangeSSHPort} == 'n' ];then
		break
	else
		echo "${CWARNING}Input error! Please only input y or n!${CEND}"
	fi
done
ssh_port=$SSH_PORT
echo ""
	#read -p "Input the maximun times for trying [2-10]:	" maxretry
	maxretry='5'
echo ""
#read -p "Input the lasting time for blocking a IP [hours]:	" bantime
bantime='8760'
if [ ${maxretry} == '' ];then
	maxretry=3
fi
if [ ${bantime} == '' ];then
	bantime=24
fi
((bantime=$bantime*60*60))
#Install
if [ ${OS} == CentOS ];then
	yum -y install epel-release
	yum -y install fail2ban
fi

if [ ${OS} == Ubuntu ] || [ ${OS} == Debian ];then
	apt-get -y update
	apt-get -y install fail2ban
fi

#Configure
rm -rf /etc/fail2ban/jail.local
touch /etc/fail2ban/jail.local
if [ ${OS} == CentOS ];then
cat <<EOF >> /etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1
bantime = 86400
maxretry = 3
findtime = 1800

[ssh-iptables]
enabled = true
filter = sshd
action = iptables[name=SSH, port=ssh, protocol=tcp]
logpath = /var/log/secure
maxretry = $maxretry
findtime = 3600
bantime = $bantime
EOF
else
cat <<EOF >> /etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1
bantime = 86400
maxretry = $maxretry
findtime = 1800

[ssh-iptables]
enabled = true
filter = sshd
action = iptables[name=SSH, port=ssh, protocol=tcp]
logpath = /var/log/auth.log
maxretry = $maxretry
findtime = 3600
bantime = $bantime
EOF
fi

#OS=CentOS
if [ ${OS} == CentOS ];then
	if [ ${CentOS_RHEL_version} == 7 ];then
		systemctl restart fail2ban
		systemctl enable fail2ban
	else
		service fail2ban restart
		chkconfig fail2ban on
	fi
fi

#OS!=CentOS
if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]];then
	service fail2ban restart
fi

#OS=CentOS
if [ ${OS} == CentOS ];then
	if [ ${CentOS_RHEL_version} == 7 ];then
		systemctl restart sshd
	else
		service ssh restart
	fi
fi

#OS!=CentOS
if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]];then
	service ssh restart
fi

echo "###########################################################################
QQ Group:277717865
Github: https://github.com/FunctionClub
Telegram Group: https://t.me/functionclub
Google Puls: https://plus.google.com/communities/113154644036958487268
###########################################################################
Fail2ban is now runing on this server now!"

#END