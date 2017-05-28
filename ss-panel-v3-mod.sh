#!/bin/bash
#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
install_ss_panel_mod_v3(){
	yum install -y unzip zip
	wget -c https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/lnmp1.3.zip && unzip lnmp1.3.zip && cd lnmp1.3 && chmod +x install.sh && ./install.sh lnmp
	cd /home/wwwroot/default/
	yum install git -y
	rm -rf index.html
	wget https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/ss.panel_mod.zip && unzip ss.panel_mod.zip
	chattr -i .user.ini
	mv .user.ini public
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	chattr +i public/.user.ini
	wget -N -P  /usr/local/nginx/conf/ http://home.ustc.edu.cn/~mmmwhy/nginx.conf 
	service nginx restart
	yum install perl-DBI freeradius freeradius-mysql freeradius-utils -y
	mysql -uroot -proot -e"CREATE USER 'radius'@'%' IDENTIFIED BY 'root';" 
	mysql -uroot -proot -e"GRANT ALL ON *.* TO 'radius'@'%';" 
	mysql -uroot -proot -e"create database radius;" 
	mysql -uroot -proot -e"use radius;" 
	mysql -uroot -proot radius < /home/wwwroot/default/sql/all.sql
	mysql -uroot -proot -e"CREATE USER 'ss-panel-radius'@'%' IDENTIFIED BY 'root';" 
	mysql -uroot -proot -e"GRANT ALL ON *.* TO 'ss-panel-radius'@'%';" 
	mysql -uroot -proot -e"CREATE USER 'sspanel'@'%' IDENTIFIED BY 'root';" 
	mysql -uroot -proot -e"GRANT ALL ON *.* TO 'sspanel'@'%';" 
	mysql -uroot -proot -e"create database sspanel;" 
	mysql -uroot -proot -e"use sspanel;" 
	mysql -uroot -proot sspanel < /home/wwwroot/default/sql/sspanel.sql
	\cp /home/wwwroot/default/sql/sql.conf /etc/raddb/sql.conf
	wget https://github.com/glzjin/Radius-install/raw/master/radiusd.conf -O /etc/raddb/radiusd.conf
	wget https://github.com/glzjin/Radius-install/raw/master/default -O /etc/raddb/sites-enabled/default
	wget https://github.com/glzjin/Radius-install/raw/master/dialup.conf -O /etc/raddb/sql/mysql/dialup.conf
	wget https://github.com/glzjin/Radius-install/raw/master/dictionary -O /etc/raddb/dictionary
	wget https://github.com/glzjin/Radius-install/raw/master/counter.conf -O /etc/raddb/sql/mysql/counter.conf
	service radiusd start && chkconfig radiusd on
	cd /home/wwwroot/default
	php composer.phar install
	yum -y install vixie-cron
	yum -y install crontabs
	crontab –e 30 22 * * * php /home/wwwroot/ss.panel/xcat sendDiaryMail
	crontab –e */1 * * * * php /home/wwwroot/ss.panel/xcat synclogin
	crontab –e */1 * * * * php /home/wwwroot/ss.panel/xcat syncvpn
	crontab –e 0 0 * * * php -n /home/wwwroot/ss.panel/xcat dailyjob
	crontab –e */1 * * * * php /home/wwwroot/ss.panel/xcat checkjob    
	crontab –e */1 * * * * php -n /home/wwwroot/ss.panel/xcat syncnas
	echo "#############################################################"
	echo "# 安装成功，登录http://${IPAddress}看看吧~                  #"
	echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
	echo "# Author: Feiyang.li                                        #"
	echo "# Blog: https://91vps.club/2017/05/27/ss-panel-v3-mod/      #"
	echo "#############################################################"
}
install_ssr(){
	yum -y update
	yum -y install git -y
	yum -y install git -y
	yum -y install python-setuptools && easy_install pip -y
	yum -y groupinstall "Development Tools" -y
	wget https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/libsodium-1.0.11.tar.gz
	tar xf libsodium-1.0.11.tar.gz && cd libsodium-1.0.10
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	#clone shadowsocks
	cd /root
	git clone -b manyuser https://github.com/glzjin/shadowsocks.git "/root/shadowsocks"
	#install devel
	cd /root/shadowsocks
	yum -y install python-devel
	yum -y install libffi-devel
	yum -y install openssl-devel
	pip install -r requirements.txt
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
	#iptables
	iptables -I INPUT -p tcp -m tcp --dport 104 -j ACCEPT
	iptables -I INPUT -p tcp -m tcp --dport 1024: -j ACCEPT
	iptables-save
}
install_node(){
	clear
	echo
	echo "#############################################################"
	echo "# One click Install Shadowsocks-Python-Manyuser             #"
	echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
	echo "# Author: 91VPS.CLUB                                        #"
	echo "# https://91vps.club/2017/05/27/ss-panel-v3-mod/            #"
	echo "#############################################################"
	echo
	#Check Root
	[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
	read -p "Please input your domain(like:https://ss.feiyang.li or http://114.114.114.114): " Userdomain
	read -p "Please input your muKey(like:mupass): " Usermukey
	read -p "Please input your Node_ID(like:1): " UserNODE_ID
	install_ssr
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
	cd /root/shadowsocks
	./logrun.sh
}
echo
echo "#############################################################"
echo "# One click Install SS-panel and Shadowsocks-Py-Mu          #"
echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
echo "# Author: 91VPS.club                                        #"
echo "# Blog: https://91vps.club/2017/05/27/ss-panel-v3-mod/      #"
echo "# Please choose the server you want                         #"
echo "# 1  SS-V3_mod_panel One click Install                      #"
echo "# 2  SS-node One click Install                              #"
echo "#############################################################"
echo
stty erase '^H' && read -p " 请输入数字 [1-3]:" num
case "$num" in
	1)
	install_ss_panel_mod_v3
	;;
	2)
	install_node
	;;
	*)
	echo "请输入正确数字 [1-3]"
	;;
esac
