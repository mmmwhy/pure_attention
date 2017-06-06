#!/bin/bash
sleep 3s
yum update -y
#512M的小鸡增加1G的Swap分区
dd if=/dev/zero of=/var/swap bs=1024 count=1048576
mkswap /var/swap
chmod 0644 /var/swap
swapon /var/swap
echo '/var/swap   swap   swap   default 0 0' >> /etc/fstab
#安装cron
yum -y install vixie-cron
chkconfig crond on
service crond start
#安装VNC桌面环境
yum -y groupinstall "Gnome" "Desktop"
chkconfig NetworkManager off
service NetworkManager stop
yum -y install tigervnc
yum -y install tigervnc-server
vncserver
#查询包括关键字xterm所在的行，并替换为#xterm
sed -i '/xterm/s/^/#/' ~/.vnc/xstartup
sed -i '/twm/s/^/#/' ~/.vnc/xstartup
#在最后一行新增gnome-session &
sed -i '$a gnome-session &' ~/.vnc/xstartup
sed -i '$a VNCSERVERS="1:root"' /etc/sysconfig/vncservers
sed -i '$a VNCSERVERARGS[1]="-geometry 1024x768 -alwaysshared -depth 24"' /etc/sysconfig/vncservers
service vncserver restart
chmod +x ~/.vnc/xstartup
chkconfig vncserver on
service vncserver restart
#打开5901端口
iptables -I INPUT -p tcp --dport 5901 -j ACCEPT
service iptables reload
#安装火狐浏览器
yum -y install firefox
yum -y install fonts-chinese
#火狐优化
echo  "15 * * * * rm -rf /root/.vnc/*.log > /dev/null 2>&1"  >> /var/spool/cron/root
echo  "16 * * * * killall -9 firefox > /dev/null 2>&1"  >> /var/spool/cron/root
echo  "17 * * * * export DISPLAY=:1;firefox > /dev/null 2>&1"  >> /var/spool/cron/root
echo  "30 * * * * rm -rf /root/.vnc/*.log > /dev/null 2>&1"  >> /var/spool/cron/root
echo  "31 * * * * killall -9 firefox > /dev/null 2>&1"  >> /var/spool/cron/root
echo  "32 * * * * export DISPLAY=:1;firefox > /dev/null 2>&1"  >> /var/spool/cron/root
echo  "45 * * * * rm -rf /root/.vnc/*.log > /dev/null 2>&1"  >> /var/spool/cron/root
echo  "46 * * * * killall -9 firefox > /dev/null 2>&1"  >> /var/spool/cron/root
echo  "47 * * * * export DISPLAY=:1;firefox > /dev/null 2>&1"  >> /var/spool/cron/root
echo "#############################################################"
echo "# One click Install Vagex                                   #"
echo "# reffer: https://github.com/YouBubedu/ubedu                #"
echo "# Author: Feiyang.li                                        #"
echo "# https://91vps.club/2017/06/06/vagex_vps/                  #"
echo "# Will reboot in 5s                                         #"
echo "#############################################################"
echo
sleep 5s
reboot