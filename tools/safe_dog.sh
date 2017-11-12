#!/bin/bash

Install_safe_dog(){
if [ ! -f /usr/bin/sdui ];then
	echo "检查到您未安装,将先进行安装...";sleep 2
	#Install_safe_dog
	yum -y install wget curl lsof psmisc mlocate net-tools
	wget "http://ssr-1252089354.coshk.myqcloud.com/safedog_linux64.tar.gz"
	tar xzvf safedog_linux64.tar.gz;mv safedog_an_linux64_2.8.19005 safedog
	cd safedog;chmod +x *.py;./install.py
	echo "安全狗安装完成,3s后启动...";sleep 3
	sdui
else
	sdui
fi
}

Install_safe_dog