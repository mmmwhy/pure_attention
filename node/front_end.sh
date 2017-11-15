#!/bin/bash

Install_Lnmp_And_The_Front_End(){
	install_lnmp_1_3(){
		wget -c "http://ssr-1252089354.coshk.myqcloud.com/lnmp1.3.zip"
		unzip lnmp1.3.zip;cd lnmp1.3;chmod +x install.sh;./install.sh lnmp
	}
	install_lnmp_1_4(){
		echo "安装选项:[2,自定义数据库密码,Y,7,1],回车继续...";read
		wget -c "http://soft.vpser.net/lnmp/lnmp1.4.tar.gz"
		tar zxf lnmp1.4.tar.gz;cd lnmp1.4;./install.sh lnmp
	}
	get_mysql_passwd(){
		read -p "数据库密码是：" mysql_passwd
		echo;echo "数据库密码正确时,会提示:[Welcome to the MySQL...],此时输入[exit]退出即可."
		echo "数据库密码错误时,会提示:[ERROR 1045 (28000)...],此时请检查数据库密码正误."
		echo -n "脚本将验证数据库密码正误,请回车继续...";read
		echo;mysql -uroot -p${mysql_passwd}
		echo;read -p "数据库密码正确么?[y/n]:" mysql_passwd_right_and_wrong
		
		case "$mysql_passwd_right_and_wrong" in
			y)
			echo;echo "Great！不过还有一些工作要做...";echo;sleep 2.5;;
			n)
			echo "数据库密码错误,请检查.";exit 0;;
			*)
			echo "选项不在范围!";exit 0;;
		esac
	}
	install_ss_panel(){
		cd /home/wwwroot/default;rm -rf index.html
		git clone https://github.com/mmmwhy/mod.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
		wget -O /home/wwwroot/default/config/.config.php "http://ssr-1252089354.coshk.myqcloud.com/config.php"
		sed -i "s/this_is_the_sspanel_database_password/${mysql_passwd}/g" /home/wwwroot/default/config/.config.php
		chattr -i .user.ini;mv .user.ini public;chown -R root:root *;chmod -R 777 *;chown -R www:www storage;chattr +i public/.user.ini
		wget -O /usr/local/nginx/conf/nginx.conf "http://ssr-1252089354.coshk.myqcloud.com/nginx.conf";lnmp nginx restart
		mysql -uroot -p${mysql_passwd} -e "create database sspanel;"
		mysql -uroot -p${mysql_passwd} -e "use sspanel;"
		mysql -uroot -p${mysql_passwd} sspanel < /home/wwwroot/default/sql/glzjin_all.sql
		cd /home/wwwroot/default;php xcat initQQWry;php -n xcat initdownload
		yum -y install vixie-cron crontabs;rm -rf /var/spool/cron/root
		echo 'SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
*/20 * * * * /usr/sbin/ntpdate pool.ntp.org > /dev/null 2>&1
30 22 * * * php /home/wwwroot/default/xcat sendDiaryMail
0 0 * * * php /home/wwwroot/default/xcat dailyjob
*/1 * * * * php /home/wwwroot/default/xcat checkjob' >> /var/spool/cron/root
		/sbin/service crond restart
		clear;echo "只剩最后几步..."
		read -p "(1/3)设置站点名称:" Front_end_name
		sed -i "s/this_is_sspanel_name/${Front_end_name}/g" /home/wwwroot/default/config/.config.php
		read -p "(2/3)设置站点IP或域名:" Front_end_address
		if [[ ${Front_end_address} = '' ]];then
			Front_end_address=`curl -s "https://myip.ipip.net" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
			echo "emm,我们已将站点地址设置为:http://${Front_end_address}"
		fi
		sed -i "s/this_is_sspanel_address/${Front_end_address}/g" /home/wwwroot/default/config/.config.php

		echo "(3/3)创建管理员账户:";echo
		php /home/wwwroot/default/xcat createAdmin;echo
		echo;echo "大功告成了!,访问 http://${Front_end_address} 看看吧~"
	}
	Select_options(){
		yum -y install zip unzip git wget curl
		clear;echo "安装选项：[1]LNMP_1.3 [2]LNMP_1.4 [3]跳过"
		read -p "请选择安装选项:" Install_the_front_options;echo

		case "$Install_the_front_options" in
			1)
			install_lnmp_1_3
			mysql_passwd='root';;
			2)
			install_lnmp_1_4
			#允许system函数
			sed -i "314c disable_functions = passthru,exec,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server" /usr/local/php/etc/php.ini
			get_mysql_passwd;;
			3)
			get_mysql_passwd;;
			*)
			echo "选项不在范围!";exit 0;;
		esac
	}
	
	Select_options
	install_ss_panel
}

Install_Lnmp_And_The_Front_End