#!/usr/bin/env bash
clear
echo
echo "#############################################################"
echo "# One click Install Shadowsocks-Python-Manyuser             #"
echo "# Github: https://github.com/mmmwhy/ss-panel-ss-py-mu       #"
echo "# Author: Feiyang.li                                        #"
echo "# Blog: https://feiyang.li/                                 #"
echo "#############################################################"
echo
#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
read -p "Please input your domain(like:https://ss.feiyang.li or http://114.114.114.114): " Userdomain
read -p "Please input your mukey(like:mupass): " Usermukey
read -p "Please input your Node_ID(like:1): " UserNODE_ID
#check OS version
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
install_soft_for_each(){
	check_sys
	if [[ ${release} = "centos" ]]; then
		echo "Will install below software on your centos system:"
		yum install git -y
		yum install python-setuptools -y 
		yum -y groupinstall "Development Tools" -y
		wget https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/libsodium-1.0.11.tar.gz
		tar xf libsodium-1.0.11.tar.gz && cd libsodium-1.0.11
		./configure && make -j2 && make install
		echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
		ldconfig
		yum install python-setuptools
		easy_install supervisor
	else
	apt-get update -y
	apt-get install supervisor -y
	apt-get install git -y
	apt-get install build-essential -y
	wget https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/libsodium-1.0.11.tar.gz
	tar xf libsodium-1.0.11.tar.gz && cd libsodium-1.0.11
	./configure && make -j2 && make install
	ldconfig
	fi
}

install_soft_for_each
echo "Let's setup your ssnode/root"
git clone https://github.com/mmmwhy/shadowsocks-py-mu.git "/root/shadowsocks-py-mu"
#modify Config.py
echo -e "modify Config.py...\n"
Userdomain=${Userdomain:-"https://ss.feiyang.li"}
sed -i "s#http://domain#${Userdomain}#" /root/shadowsocks-py-mu/shadowsocks/config.py
Usermukey=${Usermukey:-"mupass"}
sed -i "s#mupass#${Usermukey}#" /root/shadowsocks-py-mu/shadowsocks/config.py
UserNODE_ID=${UserNODE_ID:-"1"}
sed -i "s#'1'#'${UserNODE_ID}'#" /root/shadowsocks-py-mu/shadowsocks/config.py
echo_supervisord_conf > /etc/supervisord.conf
sed -i '$a [program:ss-manyuser]\ncommand = python /root/shadowsocks-py-mu/shadowsocks/servers.py\nuser = root\nautostart = true\nautorestart = true' /etc/supervisord.conf
supervisord
iptables -I INPUT -p tcp -m tcp --dport 104 -j ACCEPT
iptables -I INPUT -p tcp -m tcp --dport 1024: -j ACCEPT
iptables-save
sleep 4
cat shadowsocks.log