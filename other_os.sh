#!/bin/bash

#全局变量
server_ip=`curl -s https://app.52ll.win/ip/api.php`

#修改配置
modify_node_info(){
	#检测
	if [ ! -f /root/shadowsocks/userapiconfig.py ];then
		echo "ssr服务端未安装,不能执行该选项.";exit 0
	else
		#输出当前节点配置
		clear;echo "当前节点配置如下:"
		echo "------------------------------------"
		sed -n '3p' /root/shadowsocks/userapiconfig.py
		sed -n '17,18p' /root/shadowsocks/userapiconfig.py
		echo "------------------------------------"
		#获取新节点配置信息
		echo -n "新的前端地址是:";read Userdomain
		echo -n "新的节点ID是:";read UserNODE_ID
		echo -n "新的MuKey是:";read Usermukey
		#检查
		if [ ! -f /root/shadowsocks/userapiconfig.py.bak ];then
			wget -O /root/shadowsocks/userapiconfig.py.bak "http://sspanel-1252089354.coshk.myqcloud.com/userapiconfig.py"
		fi
		#还原
		rm -rf /root/shadowsocks/userapiconfig.py
		cp /root/shadowsocks/userapiconfig.py.bak /root/shadowsocks/userapiconfig.py
		#修改
		Userdomain=${Userdomain:-"http://${server_ip}"}
		sed -i "s#https://zhaoj.in#${Userdomain}#" /root/shadowsocks/userapiconfig.py
		Usermukey=${Usermukey:-"mupass"}
		sed -i "s#glzjin#${Usermukey}#" /root/shadowsocks/userapiconfig.py
		UserNODE_ID=${UserNODE_ID:-"3"}
		sed -i '2d' /root/shadowsocks/userapiconfig.py
		sed -i "2a\NODE_ID = ${UserNODE_ID}" /root/shadowsocks/userapiconfig.py
	fi
}

debian_os_install_ssr_node(){
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
	echo -e "\033[31m已完成安装ssr节点端,您可以使用[ssr]命令来启动/停止ssr服务端,或是查看ssr服务器进程.
经测试,在部分OS上,脚本没有要求设置节点端信息,这时您应执行[ssr]命令后选项选项4填写
没有填写节点配置/填写错误的节点配置会无法使用.配置正确的节点配置后,记得通过[ssr]命令启动ssr服务端.\033[0m"
}

#执行
debian_os_install_ssr_node

#END @qinghuas 2017-10-29 11:43