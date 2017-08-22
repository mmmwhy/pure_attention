#!/bin/bash

#检查是否是root账户
Root_account=`id -u`
if [ ${Root_account} != '0' ];then
	echo "请通过命令 sudo -i 切换至root账户，然后在尝试执行此脚本。"
fi

#安装lnmp和ss_panel_v3
install_ss_panel_v3(){
	yum install -y unzip zip git
	clear
	echo -e "################################################################################################################
lnmp1.3已知问题：[1]通过域名访问phpmyadmin文件夹会频繁500错误 [2]用户较多时，加载用户列表较慢(>10s)
lnmp1.4无上述问题，推荐安装lnmp1.4。lnmp1.4安装选项：2,自定义数据库密码,Y,5,1
################################################################################################################
[1] Lnmp1.3
[2] Lnmp1.4
[3] 跳过

请选择安装选项："
	read lnmp_version
	
	if [ ${lnmp_version} = '1' ];then
		wget -c "https://raw.githubusercontent.com/qinghuas/ss-panel-and-ss-py-mu/master/lnmp1.3.zip"
		unzip lnmp1.3.zip && cd lnmp1.3 && chmod +x install.sh && ./install.sh lnmp
		mysql_passwd=root
	elif [ ${lnmp_version} = '2' ];then
		echo -e "\033[31m lnmp1.4安装完成后，若一直停留在【Install lnmp V1.4 completed! enjoy it】，在终端内 Ctrl+C 即可 \033[0m"
		echo -e "\033[31m 安装完成大概需要30分钟，您清楚了么？回车继续... \033[0m"
		read
		#install lnmp1.4
		wget -c http://soft.vpser.net/lnmp/lnmp1.4.tar.gz && tar zxf lnmp1.4.tar.gz && cd lnmp1.4 && ./install.sh lnmp
		clear
		echo "脚本需要你设置的数据库密码进行后续操作，您设置的数据库密码是："
		read mysql_passwd
		if [ ${mysql_passwd} = '' ];then
			echo "您输入的内容为空，默认密码为：root"
			mysql_passwd=root
		else
			echo "您输入的密码为：${mysql_passwd}"
		fi
	elif [ ${lnmp_version} = '3' ];then
		echo "此项仅适用于已安装lnmp的服务器！"
		echo "脚本需要你设置的数据库密码进行后续操作，您设置的数据库密码是："
		read mysql_passwd
		if [ ${mysql_passwd} = '' ];then
			echo "您输入的内容为空，默认密码为：root"
			mysql_passwd=root
		else
			echo "您输入的密码为：${mysql_passwd}"
		fi
	else
		echo "请选择安装选项，您需要重新执行脚本。"
		exit
	fi

	#为站点命名
	clear
	echo "您已完成安装lnmp，为您的 ss panel v3 面板命个名吧："
	read ss_panel_v3_name
	if [ ${ss_panel_v3_name} = '' ];then
		echo "您未命名，默认名称为：ss panel v3"
		ss_panel_v3_name="ss panel v3"
	fi
	
	#配置前端
	cd /home/wwwroot/default/
	rm -rf index.html
	git clone https://git.coding.net/mmmwhy/mod.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
	#cp config/.config.php.example config/.config.php
	wget -P /home/wwwroot/default/config https://raw.githubusercontent.com/qinghuas/ss-panel-and-ss-py-mu/master/.config.php
	#修改站点名称，站点地址，数据库密码
	server_ip=`curl -s https://app.52ll.win/ip/api.php`
	#站点名称
	sed -i "s/this_is_sspanel_name/${ss_panel_v3_name}/g" /home/wwwroot/default/config/.config.php
	#站点地址
	sed -i "s/this_is_sspanel_address/http://${server_ip}/g" /home/wwwroot/default/config/.config.php
	#数据库密码
	sed -i "s/this_is_the_sspanel_database_password/${mysql_passwd}/g" /home/wwwroot/default/config/.config.php

	#继续配置前端
	chattr -i .user.ini
	mv .user.ini public
	#赋权
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	chattr +i public/.user.ini
	#配置nginx
	wget -N -P  /usr/local/nginx/conf/ http://home.ustc.edu.cn/~mmmwhy/nginx.conf 
	service nginx restart
	#配置数据库
	mysql -uroot -p${mysql_passwd} -e"create database sspanel;" 
	mysql -uroot -p${mysql_passwd} -e"use sspanel;" 
	mysql -uroot -p${mysql_passwd} sspanel < /home/wwwroot/default/sql/sspanel.sql
	#其他
	cd /home/wwwroot/default
	php composer.phar install
	php -n xcat initdownload
	#设置定时任务
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
	echo "####################################################################
# GitHub原版：https://github.com/mmmwhy/ss-panel-and-ss-py-mu      #
# GitHub魔改版：https://github.com/qinghuas/ss-panel-and-ss-py-mu  #
# 原作者博客：https://91vps.us/2017/05/27/ss-panel-v3-mod          #
# GitHub版权所有：@mmmwhy @qinghuas                                #
####################################################################
# 安装完成，登录 http://${server_ip} 看看吧~                     #
# 默认账户：ss@feiyang.li 默认密码：feiyang                         #
# 友情提示：登录后请务必修改默认账户与默认密码！                      #
# 更多设置请修改：/home/wwwroot/default/config/.config.php          #
####################################################################" >> /root/ss_panel_info.txt
	cat /root/ss_panel_info.txt
}

install_centos_ssr(){
	yum -y update
	yum -y install git 
	yum -y install python-setuptools && easy_install pip 
	yum -y groupinstall "Development Tools" 
	#增加1G的Swap分区
	dd if=/dev/zero of=/var/swap bs=1024 count=1048576
	mkswap /var/swap
	chmod 0644 /var/swap
	swapon /var/swap
	echo '/var/swap   swap   swap   default 0 0' >> /etc/fstab
	#编译libsodium加密库
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
	#检测系统版本
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
	clear
	echo "#########################################################################################
【前端地址填写规范】
[1]填写IP，需包含http://，例如：http://123.123.123.123
[2]填写域名，需包含http:// 或 https://，例如：https://ssr.domain.com
注意：前端地址若为域名且为https站点，请确保https配置正确(浏览器访问不提示错误即可)
【mukey填写规范】
若没有修改过前端的/home/wwwroot/default/.config.php文件中的$System_Config['muKey']项
则设置该项时，回车即可。若您修改了该项，请输入您设置的值
【节点ID填写规范】
前端搭建完成后，访问前端地址，使用默认管理员账户登陆，管理面板，节点列表，点击右下角的+号
设置节点信息，需要注意的是，节点地址可填域名或IP，节点IP只能填节点IP，设置完成后点添加
返回节点列表，就能看到你刚刚添加的节点的节点ID
#########################################################################################"
	read -p "请设置前端地址：" Userdomain
	read -p "请设置muKey：" Usermukey
	read -p "请设置节点ID：" UserNODE_ID
	install_ssr_for_each
	IPAddress=`curl -s https://app.52ll.win/ip/api.php`;
	cd /root/shadowsocks
	#备份userapiconfig.py
	cp /root/shadowsocks/userapiconfig.py /root/shadowsocks/userapiconfig.py.bak
	#修改userapiconfig.py
	echo "修改中..."
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
	echo "####################################################################
# GitHub原版：https://github.com/mmmwhy/ss-panel-and-ss-py-mu      #
# GitHub魔改版：https://github.com/qinghuas/ss-panel-and-ss-py-mu  #
# 原作者博客：https://91vps.us/2017/05/27/ss-panel-v3-mod          #
# GitHub版权所有：@mmmwhy @qinghuas                                #
####################################################################
# 管理SSR：supervisorctl {start|stop|restart} ssr                  #
# 快捷重启SSR服务端命令：srs                                        #
####################################################################" >> /root/ss_node_info.txt
	cat /root/ss_node_info.txt
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
	#检查/root/shadowsocks/userapiconfig.py是否存在
	if [ ! -f /root/shadowsocks/userapiconfig.py ];then
		echo "您还未安装ssr服务端，userapiconfig.py文件不存在，不能执行此选项！"
		exit
	fi
	
	clear
	#获取需要修改成的节点配置
	echo "#########################################################################################
【前端地址填写规范】
[1]填写IP，需包含http://，例如：http://123.123.123.123
[2]填写域名，需包含http:// 或 https://，例如：https://ssr.domain.com
注意：前端地址若为域名且为https站点，请确保https配置正确(浏览器访问不提示错误即可)
【mukey填写规范】
若没有修改过前端的/home/wwwroot/default/.config.php文件中的$System_Config['muKey']项
则设置该项时，回车即可。若您修改了该项，请输入您设置的值
【节点ID填写规范】
前端搭建完成后，访问前端地址，使用默认管理员账户登陆，管理面板，节点列表，点击右下角的+号
设置节点信息，需要注意的是，节点地址可填域名或IP，节点IP只能填节点IP，设置完成后点添加
返回节点列表，就能看到你刚刚添加的节点的节点ID
#########################################################################################"
	read -p "请设置前端地址：" Userdomain
	read -p "请设置muKey：" Usermukey
	read -p "请设置节点ID：" UserNODE_ID
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
	IPAddress=`curl -s https://app.52ll.win/ip/api.php`;
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
	if [ ! -f /root/shadowsocks/userapiconfig.py ];then
		echo "您还未安装ssr服务端，userapiconfig.py文件不存在，不能执行此选项！"
		exit
	else
	#显示当前节点配置
		echo "当前节点配置如下："
		echo "------------------------------------"
		sed -n '3p' /root/shadowsocks/userapiconfig.py
		sed -n '17,18p' /root/shadowsocks/userapiconfig.py
		echo "------------------------------------"
		echo
		#询问是否需要修改节点配置
		echo "您想修改这些信息么？[y/n]"
		read Modify_the_confirmation
		
		if [ ${Modify_the_confirmation} = 'y' ];then
			Modify_Node_Info
		else
			echo "您选择了不修改."
			exit
		fi
	fi
}

Multi_open_ssr_node_end(){
	echo "我们并不赞成这种行为，您确定要继续么？[y/n]"
	read To_confirm_more
	if [ ${To_confirm_more} = 'y'];then
		echo "我们假设有前端A，B，请确保前端A，B分配的是不同的端口段，您可在前端A，B的
/home/wwwroot/default/config/.config.php文件中设置不同的端口段。您这样做了么？回车继续"
		read
		clear
		#多开节点信息
		read -p "请设置前端地址：" Userdomain
		read -p "请设置muKey：" Usermukey
		read -p "请设置节点ID：" UserNODE_ID
}

clear
echo "####################################################################
# GitHub原版：https://github.com/mmmwhy/ss-panel-and-ss-py-mu      #
# GitHub魔改版：https://github.com/qinghuas/ss-panel-and-ss-py-mu  #
# 原作者博客：https://91vps.us/2017/05/27/ss-panel-v3-mod          #
# GitHub版权所有：@mmmwhy @qinghuas                                #
####################################################################
# [1] 安装lnmp与ss panel v3前端                                    #
# [2] 安装ssr节点端与Google BBR                                    #
# [3] 修改ssr节点端配置                                            #
# [4] 查看ssr节点端配置                                            #
# [5] 安装ssr节点端                                                #
# [6] 安装Google BBR                                              #
# [7] 执行测试脚本                                                 #
# [8] 多开ssr节点端(未完成)                                        #
####################################################################"

stty erase '^H' && read -p "Please enter the number [1-8]:" num
clear
case "$num" in
	1)
	install_ss_panel_v3
	;;
	2)
	install_node
	install_bbr
	;;
	3)
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
	8)
	echo "未完成该项设定."
	exit
	;;
	*)
	echo "请输入正确的范围 [1-8]"
	;;
esac
