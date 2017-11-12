#!/bin/bash

system_os=`bash /root/tools/check_os.sh`

change_source_for_centos(){
	read -p "(1/2)选择镜像源 [1]网易 [2]阿里 [3]自定 [4]恢复默认 :" Select_image_source

	Define_system_version(){
	case "${Select_system_version}" in
		1)
		system_version='5';;
		2)
		system_version='6';;
		3)
		system_version='7';;
		*)
		echo "选项不在范围!";exit 0;;
	esac
	}
	
	Wangyi(){
		read -p "(2/2)选择系统版本 [1]Centos5 [2]Centos6 [3]Centos7 :" Select_system_version;Define_system_version
		wget -O /etc/yum.repos.d/CentOS-Base.repo "http://mirrors.163.com/.help/CentOS${system_version}-Base-163.repo"
		yum clean all;yum makecache;yum -y update
	}
	
	Ali(){
		read -p "(2/2)选择系统版本 [1]Centos5 [2]Centos6 [3]Centos7 :" Select_system_version;Define_system_version
		wget -O /etc/yum.repos.d/CentOS-Base.repo "http://mirrors.aliyun.com/repo/Centos-${system_version}.repo"
		yum clean all;yum makecache;yum -y update
	}
	
	Since_the_set(){
		read -p "请输入repo文件地址:" Customize_the_repo_address
		if [[ ${Customize_the_repo_address} = '' ]];then
			echo "repo文件地址不能为空!";exit 0
		fi
		wget -O /etc/yum.repos.d/CentOS-Base.repo "${Customize_the_repo_address}"
		yum clean all;yum makecache;yum -y update
	}
	
	Restore_default(){
		if [ ! -f /etc/yum.repos.d/CentOS-Base.repo.bak ];then
			echo "CentOS-Base.repo.bak文件不存在,不能恢复至默认源!";exit 0
		fi
		rm -rf /etc/yum.repos.d/CentOS-Base.repo
		mv /etc/yum.repos.d/CentOS-Base.repo.bak /etc/yum.repos.d/CentOS-Base.repo
		yum clean all;yum makecache;yum -y update
	}
	
	case "${Select_image_source}" in
		1)
		Wangyi;;
		2)
		Ali;;
		3)
		Since_the_set;;
		4)
		Restore_default;;
		*)
		echo "选项不在范围!";exit 0;;
	esac
}

change_source_for_debian(){
	Since_the_set(){
		read -p "请输入sources.list文件地址:" Sources_list_file_address
		if [[ ${Sources_list_file_address} = '' ]];then
			echo "sources.list文件地址不能为空!";exit 0
		fi
		wget -O /etc/apt/sources.list "${Sources_list_file_address}"
		apt-get -y update
	}
	
	Restore_default(){
		if [ ! -f /etc/apt/sources.list.bak ];then
			echo "sources.list.bak文件不存在,不能恢复至默认源!";exit 0
		fi
		rm -rf /etc/apt/sources.list;mv /etc/apt/sources.list.bak /etc/apt/sources.list
		apt-get -y update
	}

	apt-get install -y wget
	clear;echo "#############################";lsb_release -a | grep Codename;echo "#############################"
	echo 'Acquire::Check-Valid-Until "0";' > /etc/apt/apt.conf.d/10no--check-valid-until
	
	echo "版本:[1]jessie [2]wheezy [3]squeeze"
	echo "操作:[a]自定 [b]恢复默认"
	read -p "请选择选项:" Debian_version
	
	case "${Debian_version}" in
		1)
		sources_list='jessie'
		wget -O /etc/apt/sources.list "http://mirrors.163.com/.help/sources.list.${sources_list}";apt-get -y update
		;;
		2)
		sources_list='wheezy'
		wget -O /etc/apt/sources.list "http://mirrors.163.com/.help/sources.list.${sources_list}";apt-get -y update
		;;
		3)
		sources_list='squeeze'
		wget -O /etc/apt/sources.list "http://mirrors.163.com/.help/sources.list.${sources_list}";apt-get -y update
		;;
		a)
		Since_the_set;;
		b)
		Restore_default;;
		*)
		echo "选项不在范围!";exit 0;;
	esac
}

Backup_source_file(){
	case "${system_os}" in
		debian)
		if [ ! -f /etc/apt/sources.list.bak ];then
			cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
		fi;;
		centos)
		if [ ! -f /etc/yum.repos.d/CentOS-Base.repo.bak ];then
			cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
		fi;;
		*)
		echo "系统不受支持!请更换Centos/Debian镜像后重试!";exit 0;;
	esac
}

change_source(){
	case "${system_os}" in
		centos)
		change_source_for_centos;;
		debian)
		change_source_for_debian;;
		*)
		echo "系统不受支持!请更换Centos/Debian镜像后重试!";exit 0;;
	esac
}

Backup_source_file
change_source