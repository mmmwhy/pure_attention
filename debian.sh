#!/bin/bash

#准备环境
apt-get install -y curl wget screen

#全局变量
server_ip=`curl -s https://app.52ll.win/ip/api.php`

modify_node_info(){
	#修改配置
	if [ ! -f /root/shadowsocks/userapiconfig.py.bak ];then
		wget -O /root/shadowsocks/userapiconfig.py.bak "http://sspanel-1252089354.coshk.myqcloud.com/userapiconfig.py"
	fi
	#还原
	rm -rf /root/shadowsocks/userapiconfig.py
	cp /root/shadowsocks/userapiconfig.py.bak /root/shadowsocks/userapiconfig.py
	#修改 前端地址
	#Userdomain=${Userdomain:-"http://${server_ip}"}
	sed -i "s#https://zhaoj.in#${Userdomain}#" /root/shadowsocks/userapiconfig.py
	#修改 Mukey
	#Usermukey=${Usermukey:-"mupass"}
	sed -i "s#glzjin#${Usermukey}#" /root/shadowsocks/userapiconfig.py
	#修改 Node ID
	#UserNODE_ID=${UserNODE_ID:-"3"}
	sed -i '2d' /root/shadowsocks/userapiconfig.py
	sed -i "2a\NODE_ID = ${UserNODE_ID}" /root/shadowsocks/userapiconfig.py
}

install_ssr_node(){
	#更新与安装
	apt-get update -y
	apt-get install git wget lsof python-pip build-essential -y
	#libsodium
	cd /root;wget "http://sspanel-1252089354.coshk.myqcloud.com/libsodium-1.0.13.tar.gz"
	tar xf /root/libsodium-1.0.13.tar.gz;cd /root/libsodium-1.0.13;./configure;make -j2;make install;cd /root
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf;ldconfig
	#cymysql
	pip install cymysql requests -i https://pypi.org/simple/
	#shadowsocks
	git clone -b manyuser https://github.com/glzjin/shadowsocks.git "/root/shadowsocks"
	wget -O /usr/bin/ssr "https://file.52ll.win/ssr";chmod 777 /usr/bin/ssr
	cd shadowsocks;pip install -r requirements.txt -i https://pypi.org/simple/
	chmod +x *.sh
	#配置
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
	#服务端配置
	modify_node_info
	clear;echo "已安装完成,您可通过[ssr]命令来管理服务."
	echo -e "\033[31m目前ssr节点尚未启动,您需通过使用[ssr]命令,并选择选项[1]启动\033[0m"
	echo -e "\033[31m部分Debian OS可能未要求您填写节点信息,您需通过使用[ssr]命令,并选择选项[5]填写\033[0m"
}

installation_tips(){
	clear;echo "-------------------------"
	echo "简介:部署SSR服务端"
	echo "适配:Debian7/8/9"
	echo "版本:v1.1 17-11-05"
	echo "-------------------------"
	echo -n "回车继续,或按Ctrl+C中止...";read
}

set_node_information(){
	clear;echo -e "\033[31m您需先设置节点信息,其中[MuKey]项可留空:\033[0m"
	echo -n "[1]前端地址:";read Userdomain
	echo -n "[2]节点ID:";read UserNODE_ID
	echo -n "[3]MuKey:";read Usermukey
	#若Usermukey为空值
	if [ ${Usermukey} = '' ];then
		Usermukey='mupass'
	fi
	#二次确认
	echo;echo -n "已保存这些设置,回车开始安装...";read
}

#执行
installation_tips
set_node_information
install_ssr_node

#END @qinghuas 2017-10-29 11:43