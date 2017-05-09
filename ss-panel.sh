#!/bin/bash
#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
#check OS version
#wget -c http://home.ustc.edu.cn/~mmmwhy/lnmp1.3.zip && unzip lnmp1.3.zip && cd lnmp1.3 && chmod +x install.sh && ./install.sh lnmp
install_ss_panel(){
	clear
	echo
	echo "#############################################################"
	echo "# One click Install Shadowsocks-Python-Manyuser             #"
	echo "# Github: https://github.com/mmmwhy/ss-panel-ss-py-mu       #"
	echo "# Author: Feiyang.li                                        #"
	echo "# Blog: https://feiyang.li/                                 #"
	echo "#############################################################"
	echo
	rm -rf /home/wwwroot/default/index.html	
	wget http://home.ustc.edu.cn/~mmmwhy/ss-panel-master.zip
	unzip ss-panel-master.zip -d /home/wwwroot/defaultcd /home/wwwroot/default/
	curl -sS https://install.phpcomposer.com/installer | php
	chmod +x /composer.phar
	composer config repo.packagist composer https://packagist.phpcomposer.com
	php composer.phar install
	chmod -R 777 storage
	mysql -uroot -pmysql -e"create database ss;" 
	mysql -uroot -pmysql -e"use ss;" 
	mysql -uroot -pmysql ss < /home/wwwroot/default/db.sql
	wget -N -P  /usr/local/nginx/conf/ http://home.ustc.edu.cn/~mmmwhy/nginx.conf 
	lnmp nginx restart
}