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

常见问题
---
Q：节点ID在哪里找？
A：前端搭建完成后，访问前端地址，使用默认管理员账户登陆，管理面板，节点列表，点击右下角的+号，设置节点信息，需要注意的是，节点地址可填域名或IP，节点IP只能填节点IP，设置完成后点添加，返回节点列表，就能看到你刚刚添加的节点的节点ID

Q：搭建SS节点时，`domain`和`muKey`应该填什么？
A：`domain`填你的前端地址，需包含 `http://` 或 `https://` ，例：`https://domain.com` ，回车将获取本机服务器IP作为前端地址
关于`muKey`，若没有修改过前端的`.config.php`的`$System_Config['muKey']`项，则设置该项时，回车即可

Q：远程ssh执行脚本时，出现方块，无法显示汉字，为什么？
A：请使用[Xshell5](https://www.netsarang.com/products/xsh_overview.html "Xshell5")

Q：搭建ss节点端后，使用ss/ssr客户端无法链接，为什么？
A：在该节点端使用命令`srs`重启ssr服务，然后尝试连接。若服务器是阿里云的，请设置安全组为全部放行，若为其他vps服务商，请检查控制面板的安全组设置，或Linux防火墙设置，或检查节点端`domain`，`muKey`，`Node_ID`设置，若均无问题，请尝试在其他设备上使用，排查是否是设备问题

Q：服务器装了BBR，延时还是很高，速度还是很慢，怎么办？
A：世界加钱可及

Q：看了教程，还是不会用，怎么办？
A：你看见浏览器右上角的x了么？

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
选择lnmp版本，可选择安装1.3或1.4或跳过安装，此处推荐选择安装lnmp1.4，选择选项1后将安装lnmp1.3，过程此处省略
若选择选项2后将安装lnmp1.4，然后

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

修改完成后会自动重启ssr服务，最后提示：`Done.`，表明修改成功。

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
