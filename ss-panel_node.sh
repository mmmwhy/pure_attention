#!/bin/bash
#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
#check OS version
install_ss_panel(){
	wget -c http://home.ustc.edu.cn/~mmmwhy/lnmp1.3.zip && unzip lnmp1.3.zip && cd lnmp1.3 && chmod +x install.sh && ./install.sh lnmp
	chattr -i /home/wwwroot/default/.user.ini
	rm -rf /home/wwwroot/default
	git clone https://github.com/mmmwhy/ss-panel.git "/home/wwwroot/default"
	cd /home/wwwroot/default
	curl -sS https://install.phpcomposer.com/installer | php
	chmod +x composer.phar
	php composer.phar install
	chmod -R 777 storage
	mysql -uroot -proot -e"create database ss;" 
	mysql -uroot -proot -e"use ss;" 
	mysql -uroot -proot ss < /home/wwwroot/default/db.sql
	wget -N -P  /usr/local/nginx/conf/ http://home.ustc.edu.cn/~mmmwhy/nginx.conf 
	lnmp nginx restart
}


install_ss_py_mu(){
	clear
	echo
	echo "#############################################################"
	echo "# One click Install Shadowsocks-Python-Manyuser             #"
	echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
	echo "# Author: Feiyang.li                                        #"
	echo "# http://feiyang.li/2017/05/09/ss-shell/index.html          #"
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
}

one_click_all(){
	install_ss_panel
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	#Check Root
	[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
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
	sed -i "s#domain#${IPAddress}#" /root/shadowsocks-py-mu/shadowsocks/config.py
	echo_supervisord_conf > /etc/supervisord.conf
	sed -i '$a [program:ss-manyuser]\ncommand = python /root/shadowsocks-py-mu/shadowsocks/servers.py\nuser = root\nautostart = true\nautorestart = true' /etc/supervisord.conf
	supervisord
	iptables -I INPUT -p tcp -m tcp --dport 104 -j ACCEPT
	iptables -I INPUT -p tcp -m tcp --dport 1024: -j ACCEPT
	iptables-save
	sleep 4
	cat shadowsocks.log
	echo ""
	echo "#############################################################"
	echo "# 安装成功，登录http://${IPAddress}看看吧~                  #"
	echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
	echo "# Author: Feiyang.li                                        #"
	echo "# Blog: http://feiyang.li/2017/05/09/ss-shell/index.html    #"
	echo "#############################################################"
}


echo
echo "#############################################################"
echo "# One click Install SS-panel and Shadowsocks-Py-Mu          #"
echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
echo "# Author: Feiyang.li                                        #"
echo "# http://feiyang.li/2017/05/09/ss-shell/index.html          #"
echo "# Please choose the server you want                         #"
echo "# 1  SS-panel + SS-node One click Install                   #"
echo "# 2  SS-panel One click Install                             #"
echo "# 3  SS-node One click Install                              #"
echo "#############################################################"
echo
stty erase '^H' && read -p " 请输入数字 [1-3]:" num
case "$num" in
	1)
	one_click_all
	;;
	2)
	install_ss_panel
	;;
	3)
	install_ss_py_mu
	;;
	*)
	echo "请输入正确数字 [1-3]"
	;;
esac