#!/bin/bash

Install_the_front(){
	bash /root/node/front_end.sh
}

Unfile_number_limit(){
	echo "root soft nofile 65535
root hard nofile 65535" >> /etc/security/limits.conf
	echo "session required pam_limits.so" >> /etc/pam.d/login
}

Add_swap_partition(){
	Memory_size=`cat /proc/meminfo | grep MemTotal | grep -E -o "[1-9][0-9]{4,}"`
	Swap_size=`expr ${Memory_size} \* 2`
	
	dd if=/dev/zero of=/var/swap bs=1024 count=${Swap_size}
	mkswap /var/swap;swapon /var/swap;free -m
	echo '/var/swap swap swap default 0 0' >> /etc/fstab
}

Install_BBR(){
	bash /root/tools/bbr.sh
}

Check_BBR_installation_status(){
	uname -r
	echo -e "\033[31m[↑]查看内核版本,含有4.12或更高即可.\033[0m";echo
	sysctl net.ipv4.tcp_available_congestion_control
	echo -e "\033[31m[↑]返回：net.ipv4.tcp_available_congestion_control = bbr cubic reno 即可.\033[0m";echo
	sysctl net.ipv4.tcp_congestion_control
	echo -e "\033[31m[↑]返回：net.ipv4.tcp_congestion_control = bbr 即可.\033[0m";echo
	sysctl net.core.default_qdisc
	echo -e "\033[31m[↑]返回：net.core.default_qdisc = fq 即可.\033[0m";echo
	lsmod | grep bbr
	echo -e "\033[31m[↑]返回值有 tcp_bbr 模块即说明bbr已启动.\033[0m"
}

Install_fail2ban(){
	if [ ! -f /etc/fail2ban/jail.local ];then
		echo "检测到未安装fail2ban,将先进行安装...";sleep 2.5
		bash /root/tools/fail2ban.sh
	else
		fail2ban-client ping;echo -e "\033[31m[↑]正常返回值:Server replied: pong\033[0m"
		#iptables --list -n;echo -e "\033[31m#当前iptables禁止规则\033[0m"
		fail2ban-client status;echo -e "\033[31m[↑]当前封禁列表\033[0m"
		fail2ban-client status ssh-iptables;echo -e "\033[31m[↑]当前被封禁的IP列表\033[0m"
		sed -n '12,14p' /etc/fail2ban/jail.local;echo -e "\033[31m[↑]当前fail2ban配置\033[0m"
	fi
	
	echo;read -p "输入[n]则退出;输入一个ipv4地址则将为其解除fail2ban封锁:" N_OR_IP
	case "${N_OR_IP}" in
	n)
		echo "退出.";;
	*)
		fail2ban-client set ssh-iptables unbanip ${N_OR_IP};;
	esac
}

Install_Safe_Dog(){
	bash /root/tools/safe_dog.sh
}

Install_Serverspeeder(){
	read -p "请选择选项 [1]安装 [2]卸载 :" Install_Serverspeeder_Options
	
	case "${Install_Serverspeeder_Options}" in
		1)
		wget -N --no-check-certificate "https://github.com/91yun/serverspeeder/raw/master/serverspeeder.sh"
		bash serverspeeder.sh;;
		2)
		chattr -i /serverspeeder/etc/apx*
		/serverspeeder/bin/serverSpeeder.sh uninstall -f;;
		*)
		echo "选项不在范围!";exit 0;;
	esac
}

Uninstall_ali_cloud_shield(){
	echo "请根据阿里云系统镜像安装环境,选项相应选项!"
	echo "选项: [1]系统自控制台重装 [2]系统自快照/镜像恢复 [3]更换内核并安装LotServer"
	read -p "请选择选项:" Uninstall_ali_cloud_shield_options
	
	case "${Uninstall_ali_cloud_shield_options}" in
		1)
		bash /root/tools/alibabacloud/New_installation.sh;;
		2)
		bash /root/tools/alibabacloud/Snapshot_image.sh;;
		3)
		bash /root/tools/alibabacloud/install.sh;;
		*)
		echo "选项不在范围!";exit 0;;
	esac
}

Change_System_Source(){
	bash /root/tools/change_source.sh
}

Routing_track(){
	bash /root/tools/traceroute.sh
}

Run_Speedtest_And_Bench_sh(){
	read -p "执行SpeedTest?[y/n]:" SpeedTest
	case "${SpeedTest}" in
	y)
		chmod 777 /root/tools/speedtest.py
		cd /root/tools;./speedtest.py;cd /root;;
	*)
		echo "跳过.";echo;;
	esac

	read -p "执行UnixBench?[y/n]:" UnixBench
	case "${UnixBench}" in
	y)
		chmod 777 /root/tools/unixbench.sh
		cd /root/tools;./unixbench.sh;cd /root;;
	*)
		echo "跳过.";echo;;
	esac

	read -p "执行Bench SH?[y/n]:" Bench_SH
	case "${Bench_SH}" in
	y)
		wget -qO- bench.sh | bash;;
	*)
		echo "跳过.";echo;;
	esac
}

Install_ss_node(){
	#Setup_time=`date +"%Y-%m-%d %H:%M:%S"`;Install_the_start_time_stamp=`date +%s`
	system_os=`bash /root/tools/check_os.sh`
	
	case "${system_os}" in
		centos)
		bash /root/node/centos.sh;;
		debian)
		bash /root/node/debian.sh;;
		*)
		echo "系统不受支持!请更换Centos/Debian镜像后重试!";exit 0;;
	esac
	
	Unfile_number_limit
	Add_swap_partition
	Install_fail2ban
	
	#Installation_end_time=`date +"%Y-%m-%d %H:%M:%S"`;Install_end_time_stamp=`date +%s`
	#The_installation_time=`expr ${Install_end_time_stamp} - ${Install_the_start_time_stamp}`
	#clear;echo "安装开始时间:[${Setup_time}],安装结束时间:[${Installation_end_time}],耗时[${The_installation_time}]s."
	echo "安装已完成.但ssr服务尚未启动,请通过[shadowsocks]命令管理服务."
}

Edit_ss_node_info(){
	echo "旧设置如下:"
	sed -n '2p' /root/shadowsocks/userapiconfig.py
	sed -n '17,18p' /root/shadowsocks/userapiconfig.py
	
	echo;read -p "(1/3)请设置新的前端地址:" Front_end_address
	read -p "(2/3)请设置新的节点ID:" Node_ID
	read -p "(3/3)请设置新的Mukey:" Mukey
	
	if [[ ${Mukey} = '' ]];then
		Mukey='mupass';echo "emm,我们已将Mukey设置为:mupass"
	fi
	
	sed -i "17c WEBAPI_URL = \'${Front_end_address}\'" /root/shadowsocks/userapiconfig.py
	sed -i "2c NODE_ID = ${Node_ID}" /root/shadowsocks/userapiconfig.py
	sed -i "18c WEBAPI_TOKEN = \'${Mukey}\'" /root/shadowsocks/userapiconfig.py
	
	bash /root/shadowsocks/stop.sh
	bash /root/shadowsocks/run.sh
	echo "新设置已生效."
}

Nginx_Administration_Script(){
	if [ ! -f /usr/bin/nas ];then
		wget "https://raw.githubusercontent.com/qinghuas/Nginx-administration-script/master/nas.sh"
		cp /root/nas.sh /usr/bin/nas;chmod 777 /usr/bin/nas;nas
	else
		nas
	fi
}

Installation_Of_Pure_System(){
	bash /root/tools/reinstall.sh
}

GET_SERVER_IP(){
	if [ ! -f /root/.ip.txt ];then
		curl -s 'https://myip.ipip.net' > /root/.ip.txt
		Number_of_file_characters=`cat .ip.txt | wc -L`
		if [ ${Number_of_file_characters} -gt '100' ];then
			curl -s 'http://ip.cn' > /root/.ip.txt
		fi
	fi
	SERVER_IP_INFO=`sed -n '1p' /root/.ip.txt`
}

Install_Aria2(){
	if [ ! -f /root/aria2.sh ];then
		wget -N --no-check-certificate "https://softs.fun/Bash/aria2.sh"
		chmod +x aria2.sh
	fi
	
	bash aria2.sh
}

Install_Server_Status(){
	if [ ! -f /root/status.sh ];then
		wget "https://softs.fun/Bash/status.sh"
		chmod 777 status.sh
	fi
	
	read -p "为服务端/客户端?[s/c]:" server_or_client
	case "${server_or_client}" in
		s)
		bash status.sh s;;
		c)
		bash status.sh c;;
		*)
		echo "选项不在范围.";;
	esac
}

Install_Socks5(){
	if [ ! -f /root/ss5.sh ];then
		wget "https://raw.githubusercontent.com/qinghuas/socks5-install/master/ss5.sh"
		chmod 777 ss5.sh
	fi
		bash ss5.sh
}

INSTALL(){
	if [ ! -f /usr/bin/ssr ];then
		wget -O /root/ssr_file.zip "https://github.com/qinghuas/ss-panel-and-ss-py-mu/archive/master.zip"
		unzip /root/ssr_file.zip -d /root;mv /root/ss-panel-and-ss-py-mu-master/* /root
		cp /root/ssr.sh /usr/bin/ssr;chmod 777 /usr/bin/ssr
		rm -rf ssr_file.zip /root/ss-panel-and-ss-py-mu-master /root/picture /root/README.md /root/ssr.sh
		clear;echo "INSTALL DONE,Hellow.";sleep 1
	fi
}

UPDATE_SHADOWSOCKS_COMMAND(){
	if [ -f /usr/bin/shadowsocks ];then
		wget -O /usr/bin/shadowsocks "https://raw.githubusercontent.com/qinghuas/ss-panel-and-ss-py-mu/master/node/ss"
		chmod 777 /usr/bin/shadowsocks
	fi
}

UNINSTALL(){
	rm -rf /usr/bin/ssr /root/tools /root/node /root/.ip.txt
	clear;echo "UNINSTALL DONE,Bye."
}

REINSTALL(){
	UNINSTALL
	INSTALL
	UPDATE_SHADOWSOCKS_COMMAND
	clear;echo "REINSTALL DONE,Meet Again."
}

GET_NODE_SH_FILE(){
	if [ ! -f /root/node.sh ];then
		wget "https://dl.52ll.org/node.sh";chmod 777 node.sh
	else
		echo "node.sh 已存在."
	fi
}

INSTALL
GET_SERVER_IP

echo "####################################################################
# GitHub  #  https://github.com/mmmwhy/ss-panel-and-ss-py-mu       #
# GitHub  #  https://github.com/qinghuas/ss-panel-and-ss-py-mu     #
# Edition #  V.3.1.6 2017-12-13                                    #
# From    #  @mmmwhy @qinghuas                                     #
####################################################################
# [ID]  [TYPE]  # [DESCRIBE]                                       #
####################################################################
# [1] [Install] # [LNMP] AND [SS PANEL V3]                         #
# [2] [Install] # [SS NODE] AND [BBR]                              #
# [3] [Change]  # [SS NODE INOF]                                   #
# [4] [Install] # [SS NODE]                                        #
# [5] [Install] # [BBR]                                            #
####################################################################
# [a]检查BBR状态 [b]安装/执行路由追踪 [c]Speedtest/UnixBench/bench #
# [d]更换镜像源 [e]安装/检查 Fail2ban [f]安装/执行 安全狗          #   
# [g]卸载阿里云云盾 [h]安装/卸载 锐速 [i]Nginx 管理脚本            #
# [j]安装纯净系统 [k]安装Aria2 [l]安装Server Status [m]安装Socks5  #
####################################################################
# [x]重新加载 [y]更新脚本 [z]删除脚本 [about]关于脚本              #
# ${SERVER_IP_INFO}
####################################################################"
read -p "PLEASE SELECT OPTIONS:" SSR_OPTIONS

clear;case "${SSR_OPTIONS}" in
	1)
	Install_the_front;;
	2)
	Install_ss_node
	Install_BBR;;
	3)
	Edit_ss_node_info;;
	4)
	Install_ss_node;;
	5)
	Install_BBR;;
	a)
	Check_BBR_installation_status;;
	b)
	Routing_track;;
	c)
	Run_Speedtest_And_Bench_sh;;
	d)
	Change_System_Source;;
	e)
	Install_fail2ban;;
	f)
	Install_Safe_Dog;;
	g)
	Uninstall_ali_cloud_shield;;
	h)
	Install_Serverspeeder;;
	i)
	Nginx_Administration_Script;;
	j)
	Installation_Of_Pure_System;;
	k)
	Install_Aria2;;
	l)
	Install_Server_Status;;
	m)
	Install_Socks5;;
	x)
	/usr/bin/ssr;;
	y)
	REINSTALL;;
	z)
	UNINSTALL;;
	about)
	cat /root/tools/about.txt;;
	node)
	GET_NODE_SH_FILE;;
	*)
	echo "选项不在范围内,2s后将重新加载,请注意选择...";sleep 2
	/usr/bin/ssr;;
esac

#END 2018-01-02 13:24
