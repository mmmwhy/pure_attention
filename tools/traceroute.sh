#!/bin/bash

check_purpose_ip(){
	if [[ ${purpose_ip} = '' ]];then
		echo "目标IP不能为空!";exit 0
	fi
}

check_test_times(){
	if [[ ${test_times} = '' ]];then
		echo "测试次数不能为空!";exit 0
	fi
}

nali_test(){
	read -p "请输入目标IP:" purpose_ip
	check_purpose_ip;nali-traceroute -q 1 ${purpose_ip}
}

besttrace_test(){
	read -p "请输入目标IP:" purpose_ip
	check_purpose_ip;cd /root/besttrace;./besttrace -q 1 ${purpose_ip};cd /root
}

mtr_test(){
	read -p "请输入目标IP:" purpose_ip;check_purpose_ip
	read -p "请输入测试次数:" test_times
	mtr -c ${test_times} --report ${purpose_ip}
}

Install_check(){
	if [ ! -f /root/nali-ipip/configure ];then
		Nali_Install_check='未安装'
	else
		Nali_Install_check='已安装'
	fi

	if [ ! -f /root/besttrace/besttrace ];then
		BestTrace_Install_check='未安装'
	else
		BestTrace_Install_check='已安装'
	fi
	
	if [ ! -f /usr/sbin/mtr ];then
		MTR_Install_check='未安装'
	else
		MTR_Install_check='已安装'
	fi
}

Install_Nali(){
	echo "检查到您未安装,将先进行安装...";sleep 2
	yum -y install git gcc make wget curl traceroute
	git clone https://github.com/dzxx36gyy/nali-ipip.git
	cd nali-ipip;./configure;make;make install;cd /root
	clear;nali_test
}

Install_BestTrace(){
	echo "检查到您未安装,将先进行安装...";sleep 2
	yum -y install git gcc make wget curl traceroute
	wget "http://ssr-1252089354.coshk.myqcloud.com/besttrace.tar.gz"
	tar -xzf besttrace.tar.gz;cd besttrace;chmod +x *;clear;besttrace_test
}

Install_MTR(){
	echo "检查到您未安装,将先进行安装...";sleep 2
	yum -y install mtr;clear;mtr_test
}

Install_All(){
	#nali-ipip
	yum -y install git gcc make wget curl traceroute
	git clone https://github.com/dzxx36gyy/nali-ipip.git
	cd nali-ipip;./configure;make;make install;cd /root
	#besttrace
	yum -y install git gcc make wget curl traceroute
	wget "http://ssr-1252089354.coshk.myqcloud.com/besttrace.tar.gz"
	tar -xzf besttrace.tar.gz;cd besttrace;chmod +x *;cd /root
	#mtr
	yum -y install mtr
}

Installation_and_execution(){
	echo "安装状态: [Nali:${Nali_Install_check}] [BestTrace:${BestTrace_Install_check}] [MTR:${MTR_Install_check}]"
	echo;echo "选项:[1]Nali [2]BestTrace [3]MTR [4]全部安装"
	echo;read -p "请选择选项:" traceroute_options;echo
	
	case "${traceroute_options}" in
	1)
	if [ ! -f /root/nali-ipip/configure ];then
		Install_Nali
	else
		nali_test
	fi;;
	2)
	if [ ! -f /root/besttrace/besttrace ];then
		Install_BestTrace
	else
		besttrace_test
	fi;;
	3)
	if [ ! -f /usr/sbin/mtr ];then
		Install_MTR
	else
		mtr_test
	fi;;
	4)
	Install_All;;
	*)
	echo "选项不在范围!";exit 0;;
esac
}

Install_check
Installation_and_execution
