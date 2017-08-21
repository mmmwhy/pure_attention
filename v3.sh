#!/bin/bash

#Check Root
[ $(id -u) != "0" ] && { echo -e "\033[31m 请切换至root账户执行脚本 \033[0m"; exit 1; }

install_ss_panel_mod_v3(){
	yum install -y unzip zip git
	clear
	echo -e "################################################################################################################
Lnmp1.3已知问题：通过 lnmp vhost add 命令添加域名对本机 phpmyadmin 文件夹访问会频繁500错误，后台加载用户列表慢(>10s)
Lnmp1.4无上述两个问题，\033[31m lnmp1.4安装完成后，若一直停留在【Install lnmp V1.4 completed! enjoy it】，Ctrl+C 一下即可 \033[0m
Lnmp1.4安装选项：2,自定义您的数据库密码,Y,5,1
推荐选择安装Lnmp1.4
#######################################################################################################
请选择选项：
[1] Lnmp1.3
[2] Lnmp1.4
[3] 跳过

请输入选项："
	read lnmp_version
	
	if [ ${lnmp_version} = '1' ];then
		wget -c https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/lnmp1.3.zip && unzip lnmp1.3.zip && cd lnmp1.3 && chmod +x install.sh && ./install.sh lnmp
		mysql_passwd=root
	elif [ ${lnmp_version} = '2' ];then
		echo -e "\033[31m lnmp1.4安装完成后，若一直停留在【Install lnmp V1.4 completed! enjoy it】，Ctrl+C 一下即可 \033[0m"
		echo -e "\033[31m 安装完成大概需要30分钟，您清楚了么？回车继续... \033[0m"
		read
		#install lnmp1.4
		wget -c http://soft.vpser.net/lnmp/lnmp1.4.tar.gz && tar zxf lnmp1.4.tar.gz && cd lnmp1.4 && ./install.sh lnmp
		clear
		echo "我们需要你设置的数据库密码进行后续操作，您设置的数据库密码是："
		read mysql_passwd
		if [ ${mysql_passwd} = '' ];then
			echo "您输入的内容为空，默认密码为：root"
			mysql_passwd=root
		else
			echo "您输入的密码为：${mysql_passwd}"
			echo "确认这个密码么？如果有误，请按Ctrl+C停止操作，然后重新执行脚本"
			read
		fi
	elif [ ${lnmp_version} = '3' ];then
		echo "此选项适用于已安装lnmp的用户！"
		echo "我们需要你设置的数据库密码进行后续操作，您设置的数据库密码是："
		read mysql_passwd
		if [ ${mysql_passwd} = '' ];then
			echo "您输入的内容为空，默认密码为：root"
			mysql_passwd=root
		else
			echo "您输入的密码为：${mysql_passwd}"
			echo "确认这个密码么？如果有误，请按Ctrl+C停止操作，然后重新执行脚本"
			read
		fi
		echo "将在3秒后安装 SS Panel V3 前端..."
		sleep 3
	elif [ ${lnmp_version} = '' ];then
		echo "回车默认安装lnmp1.3，3秒后开始安装..."
		sleep 3
		wget -c https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/lnmp1.3.zip && unzip lnmp1.3.zip && cd lnmp1.3 && chmod +x install.sh && ./install.sh lnmp
		mysql_passwd=root
	else
		echo "不在范围的选项，请重新执行脚本."
		exit
	fi

	#配置前端
	cd /home/wwwroot/default/
	rm -rf index.html
	git clone https://git.coding.net/mmmwhy/mod.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
	#cp config/.config.php.example config/.config.php
	wget -P /home/wwwroot/default/config https://raw.githubusercontent.com/qinghuas/ss-panel-and-ss-py-mu/master/.config.php
	#修改站点名称，站点地址，数据库密码
	server_ip=`curl -s https://app.52ll.win/ip/api.php`
	sed -i 's/this_is_sspanel_name/SS Panel V3/g' /home/wwwroot/default/config/.config.php
	sed -i "s/this_is_sspanel_address/http://${server_ip}/g" /home/wwwroot/default/config/.config.php
	
	if [ ${mysql_passwd} != 'root' ];then
		sed -i "s/this_is_the_sspanel_database_password/${mysql_passwd}/g" /home/wwwroot/default/config/.config.php
	else
		sed -i 's/this_is_the_sspanel_database_password/root/g' /home/wwwroot/default/config/.config.php
	fi
	
	#继续配置前端
	chattr -i .user.ini
	mv .user.ini public
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	chattr +i public/.user.ini
	wget -N -P  /usr/local/nginx/conf/ http://home.ustc.edu.cn/~mmmwhy/nginx.conf 
	service nginx restart
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
	echo "#############################################################"
	echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
	echo "# Blog: https://91vps.us/2017/05/27/ss-panel-v3-mod/        #"
	echo "# Author: 91vps.us                                          #"
	echo "#############################################################"
	echo "# 安装完成，登录 http://${server_ip} 看看吧~                #"
	echo "# 默认账户：ss@feiyang.li 默认密码：feiyang                 #"
	echo "#############################################################"
	echo "# 更多设置请修改/home/wwwroot/default/config/.config.php    #"
	echo "#############################################################"
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
	#取消文件数量限制
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	#获取节点信息
	read -p "Please input your domain：" Userdomain
	read -p "Please input your muKey：" Usermukey
	read -p "Please input your Node_ID：" UserNODE_ID
	install_ssr_for_each
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	cd /root/shadowsocks
	#备份userapiconfig.py
	cp /root/shadowsocks/userapiconfig.py /root/shadowsocks/userapiconfig.py.bak
	#修改userapiconfig.py
	echo -e "modify Config.py...\n"
	Userdomain=${Userdomain:-"http://${IPAddress}"}
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
	iptables -I INPUT -p tcp -m tcp --dport 104 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 104 -j ACCEPT
	iptables -I INPUT -p tcp -m tcp --dport 1024: -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 1024: -j ACCEPT
	iptables-save >/etc/sysconfig/iptables
	echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
	echo "/usr/bin/supervisord -c /etc/supervisord.conf" >> /etc/rc.local
	chmod +x /etc/rc.d/rc.local
	#创建快捷重启命令
	echo "#!/bin/bash
supervisorctl restart ssr" > /usr/bin/srs
	chmod 777 /usr/bin/srs
	#安装完成提示
	echo "#############################################################"
	echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
	echo "# Blog: https://91vps.us/2017/05/27/ss-panel-v3-mod/        #"
	echo "# Author: 91vps.us                                          #"
	echo "#############################################################"
	echo "# 安装完成，该节点需重启使配置生效                          #"
	echo "#############################################################"
	echo "# 管理SSR：supervisorctl {start|stop|restart} ssr           #"
	echo "#############################################################"
	echo
}

reboot_system(){
	read -p "需重启服务器使配置生效，现在重启么？ [y/n]" is_reboot
	if [[ ${is_reboot} == "y" || ${is_reboot} == "Y" ]]; then
		reboot
	else
		echo "需重启服务器使配置生效，稍后请务必手动重启服务器."
		exit
	fi
}

install_bbr(){
	wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh;chmod +x bbr.sh;./bbr.sh
}

Modify_Node_Info(){
	clear
	#获取需要修改成的节点配置
	read -p "Please input new Domain：" Userdomain
	read -p "Please input new MuKey：" Usermukey
	read -p "Please input new Node_ID：" UserNODE_ID
	#检查userapiconfig.py.bak是否存在
	if [ ! -f /root/shadowsocks/userapiconfig.py.bak ];then
		wget https://raw.githubusercontent.com/qinghuas/ss-panel-and-ss-py-mu/master/userapiconfig.py
	else
	#还原
		rm -rf /root/shadowsocks/userapiconfig.py
		cp /root/shadowsocks/userapiconfig.py.bak /root/shadowsocks/userapiconfig.py
	fi
	#修改
	echo
	echo "请稍等..."
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	Userdomain=${Userdomain:-"http://${IPAddress}"}
	sed -i "s#https://zhaoj.in#${Userdomain}#" /root/shadowsocks/userapiconfig.py
	Usermukey=${Usermukey:-"mupass"}
	sed -i "s#glzjin#${Usermukey}#" /root/shadowsocks/userapiconfig.py
	UserNODE_ID=${UserNODE_ID:-"3"}
	sed -i '2d' /root/shadowsocks/userapiconfig.py
	sed -i "2a\NODE_ID = ${UserNODE_ID}" /root/shadowsocks/userapiconfig.py
	#重启
	echo "修改完成，需要重启ssr服务端么？[y/n]"
	read restart_ssr
	
	if [ ${restart_ssr} = 'y' ];then
		supervisorctl restart ssr
	else
		echo "稍后您可手动重启ssr服务端."
	fi
}

current_node_configuration(){
	#显示当前节点配置
	echo "当前节点配置如下："
	echo "------------------------------------"
	sed -n '3p' /root/shadowsocks/userapiconfig.py
	sed -n '17,18p' /root/shadowsocks/userapiconfig.py
	echo "------------------------------------"
	echo
}

clear
echo "#############################################################"
echo "# One click Install SS-panel and Shadowsocks-Py-Mu          #"
echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
echo "# Blog: https://91vps.us/2017/05/27/ss-panel-v3-mod/        #"
echo "# Author: 91vps.us                                          #"
echo "#############################################################"
echo "# Please choose the server you want                         #"
echo "# [1] Install SS Panel V3 Mod                               #"
echo "# [2] Intsall SS Node And BBR                               #"
echo "# [3] Modify Node Info                                      #"
echo "# [4] Display Node Info                                     #"
echo "# [5] Intsall SS Node                                       #"
echo "# [6] Intsall BBR                                           #"
echo "# [7] Test This Server                                      #"
echo "#############################################################"
echo

stty erase '^H' && read -p "Please enter the number [1-6]:" num
clear
case "$num" in
	1)
	install_ss_panel_mod_v3
	;;
	2)
	install_node
	install_bbr
	;;
	3)
	current_node_configuration
	Modify_Node_Info
	;;
	4)
	current_node_configuration
	;;
	5)
	install_node
	reboot_system
	;;
	6)
	install_bbr
	;;
	7)
	clear
	wget -qO- bench.sh | bash
	;;
	*)
	echo "请输入正确的范围 [1-6]"
	;;
esac
