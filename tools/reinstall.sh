#!/bin/bash

Check_the_system(){
	system_os=`bash /root/tools/check_os.sh`
	
	case "${system_os}" in
		centos)
		#yum -y update
		yum -y install sed gawk grep;;
		debian)
		#apt-get -y update
		apt-get -y install sed gawk grep;;
		ubuntu)
		#apt-get -y update
		apt-get -y install sed gawk grep;;
		*)
		echo "系统不受支持!请更换Centos/Debian/Ubuntu镜像后重试!";exit 0;;
	esac
}

Options_and_execution_options(){
	wget --no-check-certificate "https://moeclub.org/attachment/LinuxShell/DebianNET.sh"
	chmod 777 DebianNET.sh

	clear;echo -n "请选择目标系统：
-----------------------
默认密码：Vicer
-----------------------
[1]  Debian 7 x32
[2]  Debian 7 x64
[3]  Debian 8 x32
[4]  Debian 8 x64
[5]  Debian 9 x32
[6]  Debian 9 x64
-----------------------
[7]  Ubuntu 14.04 x32
[8]  Ubuntu 14.04 x64
[9]  Ubuntu 16.04 x32
[10] Ubuntu 16.04 x64
[11] Ubuntu 17.04 x32
[12] Ubuntu 17.04 x64
-----------------------
[13] Centos 6.9
-----------------------
请输入序号："
	read target_system_id

	case "$target_system_id" in
	1)
		bash DebianNET.sh -d wheezy -v i386 -a;;
	2)
		bash DebianNET.sh -d wheezy -v amd64 -a;;
	3)
		bash DebianNET.sh -d jessie -v i386 -a;;
	4)
		bash DebianNET.sh -d jessie -v amd64 -a;;
	5)
		bash DebianNET.sh -d stretch -v i386 -a;;
	6)
		bash DebianNET.sh -d stretch -v amd64 -a;;
	7)
		bash DebianNET.sh -d trusty -v 32 -a;;
	8)
		bash DebianNET.sh -d trusty -v 64 -a;;
	9)
		bash DebianNET.sh -d xenial -v 32 -a;;
	10)
		bash DebianNET.sh -d xenial -v 64 -a;;
	11)
		bash DebianNET.sh -d zesty -v 32 -a;;
	12)
		bash DebianNET.sh -d zesty -v 32 -a;;
	13)
		echo -n "该系统默认账户信息：[root] [xiaofd.win],已知晓的,回车继续.";read
		wget xiaofd.github.io/centos.sh && bash centos.sh;;
	*)
		echo "选项不在范围！";exit 0;;
	esac
}

Check_the_system
Options_and_execution_options