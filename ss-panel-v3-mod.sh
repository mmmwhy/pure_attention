#!/bin/bash
#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
install_ss_panel_mod_v3(){
	yum -y remove httpd
	yum install -y unzip zip git
	wget -c https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/lnmp1.3.zip && unzip lnmp1.3.zip && cd lnmp1.3 && chmod +x install.sh && ./install.sh lnmp
	cd /home/wwwroot/default/
	rm -rf index.html
	git clone https://github.com/mmmwhy/mod.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
	cp config/.config.php.example config/.config.php
	chattr -i .user.ini
	mv .user.ini public
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	chattr +i public/.user.ini
	wget -N -P  /usr/local/nginx/conf/ http://home.ustc.edu.cn/~mmmwhy/nginx.conf 
	service nginx restart
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	sed -i "s#103.74.192.11#${IPAddress}#" /home/wwwroot/default/sql/sspanel.sql
	mysql -uroot -proot -e"create database sspanel;" 
	mysql -uroot -proot -e"use sspanel;" 
	mysql -uroot -proot sspanel < /home/wwwroot/default/sql/sspanel.sql
	cd /home/wwwroot/default
	php composer.phar install
	php -n xcat initdownload
	yum -y install vixie-cron crontabs
	rm -rf /var/spool/cron/root
	echo 'SHELL=/bin/bash' >> /var/spool/cron/root
	echo 'PATH=/sbin:/bin:/usr/sbin:/usr/bin' >> /var/spool/cron/root
	echo '*/20 * * * * /usr/sbin/ntpdate pool.ntp.org > /dev/null 2>&1' >> /var/spool/cron/root
	echo '30 22 * * * php /home/wwwroot/default/xcat sendDiaryMail' >> /var/spool/cron/root
	echo '0 0 * * * php /home/wwwroot/default/xcat dailyjob' >> /var/spool/cron/root
	echo '*/1 * * * * php /home/wwwroot/default/xcat checkjob' >> /var/spool/cron/root
	/sbin/service crond restart
}
install_centos_ssr(){
	yum -y update
	yum -y install git 
	yum -y install python-setuptools && easy_install pip 
	yum -y groupinstall "Development Tools" 
	#512M的小鸡增加1G的Swap分区
	dd if=/dev/zero of=/var/swap bs=1024 count=1048576
	mkswap /var/swap
	chmod 0644 /var/swap
	swapon /var/swap
	echo '/var/swap   swap   swap   default 0 0' >> /etc/fstab
	wget https://github.com/jedisct1/libsodium/releases/download/1.0.13/libsodium-1.0.13.tar.gz
	tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	yum -y install python-setuptools
	easy_install supervisor
	#clone shadowsocks
	cd /root
	git clone -b manyuser https://github.com/glzjin/shadowsocks.git "/root/shadowsocks"
	#install devel
	cd /root/shadowsocks
	yum -y install lsof lrzsz
	yum -y install python-devel
	yum -y install libffi-devel
	yum -y install openssl-devel
	yum -y install iptables
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	pip install -r requirements.txt
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
}
install_ubuntu_ssr(){
	apt-get update -y
	apt-get install supervisor lsof -y
	apt-get install build-essential wget -y
	apt-get install iptables git -y
	wget https://github.com/jedisct1/libsodium/releases/download/1.0.13/libsodium-1.0.13.tar.gz
	tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	apt-get install python-pip git -y
	pip install cymysql
	cd /root
	git clone -b manyuser https://github.com/glzjin/shadowsocks.git "/root/shadowsocks"
	cd shadowsocks
	pip install -r requirements.txt
	chmod +x *.sh
	# 配置程序
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
}
install_node(){
	clear
	echo
	echo "#############################################################"
	echo "# One click Install Shadowsocks-Python-Manyuser             #"
	echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
	echo "# Author: 91vps                                             #"
	echo "# https://91vps.us/2017/08/24/ss-panel-v3-mod/              #"
	echo "#############################################################"
	echo
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
	install_ssr_for_each(){
		check_sys
		if [[ ${release} = "centos" ]]; then
			install_centos_ssr
		else
			install_ubuntu_ssr
		fi
	}
	# 取消文件数量限制
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	read -p "Please input your domain(like:https://ss.feiyang.li or http://114.114.114.114): " Userdomain
	read -p "Please input your muKey(like:mupass): " Usermukey
	read -p "Please input your Node_ID(like:1): " UserNODE_ID
	install_ssr_for_each
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	cd /root/shadowsocks
	echo -e "modify Config.py...\n"
	Userdomain=${Userdomain:-"http://${IPAddress}"}
	sed -i "s#https://zhaoj.in#${Userdomain}#" /root/shadowsocks/userapiconfig.py
	Usermukey=${Usermukey:-"mupass"}
	sed -i "s#glzjin#${Usermukey}#" /root/shadowsocks/userapiconfig.py
	UserNODE_ID=${UserNODE_ID:-"3"}
	sed -i '2d' /root/shadowsocks/userapiconfig.py
	sed -i "2a\NODE_ID = ${UserNODE_ID}" /root/shadowsocks/userapiconfig.py
	# 启用supervisord
	echo_supervisord_conf > /etc/supervisord.conf
    sed -i '$a [program:ssr]\ncommand = python /root/shadowsocks/server.py\nuser = root\nautostart = true\nautorestart = true' /etc/supervisord.conf
	supervisord
	#iptables
	iptables -F
	iptables -X  
	iptables -I INPUT -p tcp -m tcp --dport 104 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 104 -j ACCEPT
	iptables -I INPUT -p tcp -m tcp --dport 1024: -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 1024: -j ACCEPT
	iptables-save >/etc/sysconfig/iptables
	echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
	echo "/usr/bin/supervisord -c /etc/supervisord.conf" >> /etc/rc.local
	chmod +x /etc/rc.d/rc.local
	echo "#############################################################"
	echo "# 安装完成，节点即将重启使配置生效                          #"
	echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
	echo "# Author: 91vps                                             #"
	echo "# Blog: https://91vps.us/2017/08/24/ss-panel-v3-mod/        #"
	echo "#############################################################"
	reboot now
}
install_panel_and_node(){
	install_ss_panel_mod_v3
	# 取消文件数量限制
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	install_centos_ssr
	wget -N -P  /root/shadowsocks/ https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/userapiconfig.py
	# 启用supervisord
	echo_supervisord_conf > /etc/supervisord.conf
  sed -i '$a [program:ssr]\ncommand = python /root/shadowsocks/server.py\nuser = root\nautostart = true\nautorestart = true' /etc/supervisord.conf
	supervisord
	#iptables
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	yum install iptables -y
	iptables -F
	iptables -X  
	iptables -I INPUT -p tcp -m tcp --dport 104 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 104 -j ACCEPT
	iptables -I INPUT -p tcp -m tcp --dport 1024: -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 1024: -j ACCEPT
	iptables-save >/etc/sysconfig/iptables
	echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
	echo "/usr/bin/supervisord -c /etc/supervisord.conf" >> /etc/rc.local
	chmod +x /etc/rc.d/rc.local
	echo "#############################################################"
	echo "# 安装完成，登录http://${IPAddress}看看吧~                  #"
	echo "# 安装完成，节点即将重启使配置生效                          #"
	echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
	echo "# Blog: https://91vps.us/2017/08/24/ss-panel-v3-mod/        #"
	echo "#############################################################"
	reboot now
}
echo
echo "#############################################################"
echo "# One click Install SS-panel and Shadowsocks-Py-Mu          #"
echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
echo "# Author: 91vps                                             #"
echo "# Blog: https://91vps.us/2017/08/24/ss-panel-v3-mod/        #"
echo "# Please choose the server you want                         #"
echo "# 1  SS-V3_mod_panel and node One click Install             #"
echo "# 2  SS-node One click Install                              #"
echo "#############################################################"
echo
stty erase '^H' && read -p " 请输入数字 [1-2]:" num
case "$num" in
	1)
	install_panel_and_node
	;;
	2)
	install_node
	;;
	*)
	echo "请输入正确数字 [1-2]"
	;;
esac
