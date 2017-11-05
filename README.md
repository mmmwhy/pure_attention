Debian 使用帮助
---
```
wget -qO- https://raw.githubusercontent.com/qinghuas/ss-panel-and-ss-py-mu/master/debian.sh | bash
```
-适用于`Debian7/8/9`，已通过`Vultr`全`Debian`系列镜像测试。脚本安装完成后，您需通过使用`ssr`命令,并选择选项`1`启动ssr服务
-部分`Debian OS`可能未要求您填写节点信息,您需通过使用`ssr`命令,并选择选项`5`填写

Centos 使用帮助
---
1.执行安装脚本
```
wget https://raw.githubusercontent.com/qinghuas/ss-panel-and-ss-py-mu/master/v3.sh;chmod 777 v3.sh;bash v3.sh
```
若提示：`-bash: wget: command not found`，则
Centos：`yum -y install wget`
Debian/Ubuntu：`apt-get -y install wget`  

2.选项安装选项  
![](https://file.52ll.win/option_6.png)  

其他帮助
---
1.执行命令`supervisorctl restart ssr`/`srs`，提示`unix:///tmp/supervisor.sock no such file`  
答：执行修复选项
