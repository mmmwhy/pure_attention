更新日志
---
`2017-08-13` 
- 安装lnmp时可选 lnmp1.3 lnmp1.4 或跳过
- 自动修改站点名称，站点地址，数据库密码
- 前端安装完成后提示默认管理员账户密码
- 修正版权信息 (v2no.com -> 91vps.club)
- 节点端安装完成后提示ssr服务快捷管理命令
- 节点端安装完成后重启服务器需确认
- 增添修改节点端配置文件选项
- 增添安装 Google BBR 选项  
脚本来自：https://github.com/teddysun/across/
- 简化语言

使用帮助
---
1.执行安装脚本
```
wget https://raw.githubusercontent.com/qinghuas/ss-panel-and-ss-py-mu/master/ss-panel-v3-mod.sh;bash ss-panel-v3-mod.sh
```
若提示：`-bash: wget: command not found`，则
Centos：`yum -y install wget `，或
Debian：`apt-get install wget`

2.选择安装选项  
![](https://file.52ll.win/Github/sspanel/pic/install.png)  
- [1] 安装 ss panel v3 前端
- [2] 安装 ssr 后端和 bbr
- [3] 修改 ssr 后端配置
- [4] 安装 ssr 后端
- [5] 安装 bbr

选择选项1后：
---
![](https://file.52ll.win/Github/sspanel/pic/lnmp_info.png)  
选择lnmp版本，可选择安装1.3或1.4或跳过安装，此处推荐选择安装lnmp1.4，选择选项1后将安装lnmp1.3，过程此处省略。选择选项2后将安装lnmp1.4，然后
- 输入：2，回车
- 自定义数据库密码，回车
- 输入：Y，回车
- 输入：5，回车
- 输入：1，回车
- 回车
  
![](https://file.52ll.win/Github/sspanel/pic/lnmp_setting.png)

等待安装完成，30-45min左右  

![](https://file.52ll.win/Github/sspanel/pic/install_ok.png)

选择选项2后
---
需依次设置前端地址、mykey，节点ID，此处回车将使用默认值，依次为：本机地址，mupass，3

![](https://file.52ll.win/Github/sspanel/pic/install_2.png)  
  
节点端安装完成提示  

![](https://file.52ll.win/Github/sspanel/pic/ss_node_ok.png)

然后安装BBR  

![](https://file.52ll.win/Github/sspanel/pic/install_bbr.png)

安装完成后需重启服务器，输入：y，重启服务器，或：n，稍后重启。若选择稍后重启，请务必不要忘记手动重启

![](https://file.52ll.win/Github/sspanel/pic/install_bbr_info.png)

选择选项3后
---
需依次设置新的前端地址、mykey，新的节点ID，此处回车将使用默认值，依次为：本机地址，mupass，3

![](https://file.52ll.win/Github/sspanel/pic/edit_node_info.png)

修改完成后会自动重启ssr服务，最后提示：`Done.`，表面修改成功。

选择选项4后
---
需依次设置前端地址、mykey，节点ID，此处回车将使用默认值，依次为：本机地址，mupass，3

![](https://file.52ll.win/Github/sspanel/pic/install_2.png)

节点端安装完成提示

![](https://file.52ll.win/Github/sspanel/pic/ss_node_ok.png)

选择选项5后
---
回车开始安装，或按Ctrl+C取消安装

![](https://file.52ll.win/Github/sspanel/pic/install_bbr.png)

安装完成后需重启服务器，输入：y，重启服务器，或：n，稍后重启。若选择稍后重启，请务必不要忘记手动重启

![](https://file.52ll.win/Github/sspanel/pic/install_bbr_info.png)
