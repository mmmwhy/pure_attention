#!/bin/bash

#检测root账户
[ $(id -u) != "0" ] && { echo "请切换至root账户执行此脚本."; exit 1; }

#全局变量
server_ip=`curl -s https://app.52ll.win/ip/api.php`

install_lnmp_and_ss_panel(){
	yum -y remove httpd
	yum install -y unzip zip git
	#安装lnmp
	echo "选择lnmp版本: [1]lnmp1.3 [2]lnmp1.4 [3]跳过"
	echo "请输入序号:"
	read lnmp_version
	
	#lnmp安装选项
	if [ ${lnmp_version} = '1' ];then
		wget -c https://raw.githubusercontent.com/qinghuas/ss-panel-and-ss-py-mu/master/lnmp1.3.zip && unzip lnmp1.3.zip && cd lnmp1.3 && chmod +x install.sh && ./install.sh lnmp
	elif [ ${lnmp_version} = '2' ];then
		echo "lnmp1.4安装选项:2,自定义数据库密码,Y,5,1"
		echo "安装完成后,会提示[Install lnmp V1.4 completed! enjoy it],这时按一下Ctrl+C即可,回车继续.";read
		wget -c http://soft.vpser.net/lnmp/lnmp1.4.tar.gz && tar zxf lnmp1.4.tar.gz && cd lnmp1.4 && ./install.sh lnmp
	elif [ ${lnmp_version} = '3' ];then
		echo "已跳过安装lnmp."
	else
		echo "选项不在范围内,安装终止."
		exit
	fi
	
	#获取数据库密码
	if [ ${lnmp_version} = '1' ];then
		mysql_passwd=root
	else
		echo "请输入你设定的数据库密码："
		read mysql_passwd
		if [ ${mysql_passwd} = '' ];then
			mysql_passwd=root
			echo "此项不允许为空.已默认密码为:root"
		fi
	fi
	
	#设定站点名称
	echo "请设置ss_panel站点名称:"
	read ss_panel_name
	if [ ${ss_panel_name} = '' ];then
		ss_panel_name="SS Panel"
		echo "此项不允许为空.已默认名称为:SS Panel"
	fi
	
	#安装ss_panel前端
	cd /home/wwwroot/default/
	rm -rf index.html
	git clone https://github.com/mmmwhy/mod.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
	#修改参数
	wget -P /home/wwwroot/default/config https://raw.githubusercontent.com/qinghuas/ss-panel-and-ss-py-mu/master/.config.php
	#站点地址,站点名称,数据库密码
	sed -i "s/this_is_sspanel_name/${ss_panel_name}/g" /home/wwwroot/default/config/.config.php
	sed -i "s/this_is_sspanel_address/http://${server_ip}/g" /home/wwwroot/default/config/.config.php
	sed -i "s/this_is_the_sspanel_database_password/${mysql_passwd}/g" /home/wwwroot/default/config/.config.php
	#继续
	chattr -i .user.ini
	mv .user.ini public
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	chattr +i public/.user.ini
	wget -N -P  /usr/local/nginx/conf/ http://home.ustc.edu.cn/~mmmwhy/nginx.conf 
	service nginx restart
	sed -i "s#103.74.192.11#${server_ip}#" /home/wwwroot/default/sql/sspanel.sql
	mysql -uroot -p${mysql_passwd} -e"create database sspanel;" 
	mysql -uroot -p${mysql_passwd} -e"use sspanel;" 
	mysql -uroot -p${mysql_passwd} sspanel < /home/wwwroot/default/sql/sspanel.sql
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
	#完成提示
	clear
	echo "lnmp和ss_panel已安装完成
ss_panel地址:http://${server_ip}
账户:ss@feiyang.li 密码:feiyang
" >> /root/install_info.txt
	cat /root/install_info.txt
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
	#libsodium
	wget https://file.52ll.win/libsodium-1.0.13.tar.gz
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
	pip install -r requirements.txt
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
}

install_ubuntu_ssr(){
	apt-get update -y
	apt-get install supervisor lsof -y
	apt-get install build-essential wget -y
	apt-get install iptables git -y
	wget https://file.52ll.win/libsodium-1.0.13.tar.gz
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
	#check os version
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
	#帮助信息
	wget -P /root https://raw.githubusercontent.com/qinghuas/ss-panel-and-ss-py-mu/master/add_node_info.txt
	clear
	cat /root/add_node_info.txt
	#获取节点信息
	read -p "前端地址是:" Userdomain
	read -p "节点ID是:" UserNODE_ID
	read -p "MuKey是:" Usermukey
	install_ssr_for_each
	#配置节点信息
	cd /root/shadowsocks
	#备份
	cp /root/shadowsocks/userapiconfig.py /root/shadowsocks/userapiconfig.py.bak
	#修改
	Userdomain=${Userdomain:-"http://${server_ip}"}
	sed -i "s#https://zhaoj.in#${Userdomain}#" /root/shadowsocks/userapiconfig.py
	Usermukey=${Usermukey:-"mupass"}
	sed -i "s#glzjin#${Usermukey}#" /root/shadowsocks/userapiconfig.py
	UserNODE_ID=${UserNODE_ID:-"3"}
	sed -i '2d' /root/shadowsocks/userapiconfig.py
	sed -i "2a\NODE_ID = ${UserNODE_ID}" /root/shadowsocks/userapiconfig.py
	#启用supervisord
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
	#创建快捷重启命令
	echo "#!/bin/bash" >> /usr/bin/srs
	echo "supervisorctl restart ssr" >> /usr/bin/srs
	chmod 777 /usr/bin/srs
	#完成提示
	echo "ss_node已安装完成
启动SSR：supervisorctl start ssr
停止SSR：supervisorctl stop ssr
重启SSR：supervisorctl restart ssr
或：srs
" >> /root/install_info.txt
	cat /root/install_info.txt
}

reboot_system(){
	read -p "需重启服务器使配置生效,现在重启? [y/n]" is_reboot
	if [ ${is_reboot} = 'y' ];then
		reboot
	else
		echo "需重启服务器使配置生效,稍后请务必手动重启服务器.";exit
	fi
}

install_bbr(){
	wget --no-check-certificate https://raw.githubusercontent.com/teddysun/across/master/bbr.sh
	chmod 777 bbr.sh;bash bbr.sh
}

modify_node_info(){
	#检测
	if [ ! -f /root/shadowsocks/userapiconfig.py ];then
		echo "ssr服务端未安装,不能执行该选项.";exit
	else
		#清屏
		clear
		#输出当前节点配置
		echo "当前节点配置如下:"
		echo "------------------------------------"
		sed -n '3p' /root/shadowsocks/userapiconfig.py
		sed -n '17,18p' /root/shadowsocks/userapiconfig.py
		echo "------------------------------------"
		#获取新节点配置信息
		read -p "新的前端地址是:" Userdomain
		read -p "新的节点ID是:" UserNODE_ID
		read -p "新的MuKey是:" Usermukey
	
			#检查
			if [ ! -f /root/shadowsocks/userapiconfig.py.bak ];then
				wget https://raw.githubusercontent.com/qinghuas/ss-panel-and-ss-py-mu/master/userapiconfig.py
			else
			#还原
				rm -rf /root/shadowsocks/userapiconfig.py
				cp /root/shadowsocks/userapiconfig.py.bak /root/shadowsocks/userapiconfig.py
			fi
	
		#修改
		Userdomain=${Userdomain:-"http://${server_ip}"}
		sed -i "s#https://zhaoj.in#${Userdomain}#" /root/shadowsocks/userapiconfig.py
		Usermukey=${Usermukey:-"mupass"}
		sed -i "s#glzjin#${Usermukey}#" /root/shadowsocks/userapiconfig.py
		UserNODE_ID=${UserNODE_ID:-"3"}
		sed -i '2d' /root/shadowsocks/userapiconfig.py
		sed -i "2a\NODE_ID = ${UserNODE_ID}" /root/shadowsocks/userapiconfig.py
		#完成提示
		echo "Done."
	fi
}

clear
echo "####################################################################
# GitHub原版：https://github.com/mmmwhy/ss-panel-and-ss-py-mu      #
# GitHub修改版：https://github.com/qinghuas/ss-panel-and-ss-py-mu  #
# 原作者博客：https://91vps.us/2017/05/27/ss-panel-v3-mod          #
# GitHub版权：@mmmwhy @qinghuas                                    #
####################################################################
# [1] 安装lnmp与ss panel                                           #
# [2] 安装ssr节点与bbr                                             #
# [3] 修改ssr节点配置                                              #
# [4] 安装ssr节点                                                  #
# [5] 安装bbr                                                      #
# [6] 测试                                                         #
####################################################################"

stty erase '^H' && read -p "请选择安装项[1-6]:" num
clear
case "$num" in
	1)
	install_lnmp_and_ss_panel
	;;
	2)
	install_node
	install_bbr
	;;
	3)
	modify_node_info
	;;
	4)
	install_node
	reboot_system
	;;
	5)
	install_bbr
	;;
	6)
	wget -qO- bench.sh | bash
	;;
	*)
	echo "选项不在范围内,安装终止."
	exit
	;;
esac
