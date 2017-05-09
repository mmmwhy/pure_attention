> 上周接触了ss-panel，发现搭建起来异常的麻烦，对新手来说，到处都是坑，因此搭建了本ss-panel一键安装脚本

---

# 效果
![](http://cdn.mmmxcc.cn/blog/20170509/191015542.png)
![](http://cdn.mmmxcc.cn/blog/20170509/191042466.png)
![](http://cdn.mmmxcc.cn/blog/20170509/191103228.png)
**Github：https://github.com/mmmwhy/ss-panel-and-ss-py-mu**
**示例网站：https://ss.feiyang.li/**
![](http://cdn.mmmxcc.cn/blog/20170509/215724204.png)
# 特点
- 前端使用最新[ss-panel v3](https://github.com/orvice/ss-panel)，稳定性和可管理行都有明显提高。
- 后端使用[**[shadowsocks-py-mu](https://github.com/fsgmhoward/shadowsocks-py-mu)**](https://github.com/fsgmhoward/shadowsocks-py-mu)，多用户，与前端完美对接。
- 过程全自动，所以可能碰到的坑都提前做好处理。
- 被墙掉的资源都换成了墙内资源，不会出现被卡死的情况了。

# 系统要求
理论上：CentOS 6+ / Debian 7+ / Ubuntu 14.04 +  都可以，建议CentOS7 X64，我用的是这个版本，通过测试。

# 一键安装脚本
```
wget -N --no-check-certificate https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/ss-panel_node.sh && chmod +x ss-panel_node.sh && bash ss-panel_node.sh
```
运行脚本后会出现脚本操作菜单，
- 选择并输入 1 就会安装ss-panel和ss-node在此vps上。
- 选择并输入 2 就会单独安装ss-panel
- 选择并输入 2 就会单独安装ss-node

![](http://cdn.mmmxcc.cn/blog/20170509/214909086.png)

## ss-panel + ss-node 一键脚本
直接输入1，之后提示时候再点一下回车，一键到底~

安装结束后，登陆IP即可查看网站
**默认账户：ss@feiyang.li**
**默认密码：feiyang**

## 增加节点
先在网页增加节点信息，特别要记住这里的node_id，长这个样子的
![mark](http://cdn.mmmxcc.cn/blog/20170509/221038086.png)
直接输入2，输入相关信息，注意ip地址和域名都是支持的，但是需要加上**http://或者https://**，注意区分自己域名有没有ssl。否则可能出现用户使用记录无法推送的问题。
![](http://cdn.mmmxcc.cn/blog/20170509/221216262.png)

# 其他补充内容
- mailgun账号需要自己申请，我那个只是举个例子
- 基于[lnmp1.3稳定版](https://lnmp.org/)制作，网络上相关资料很多。
- [常见错误](http://feiyang.li/2017/05/03/ss-panel/index.html#常见错误)在这里查看
- 如果想设置更多的信息，请查看[安装教程全文](http://feiyang.li/2017/05/05/ss-panel-full/index.html)，本脚本和该教程内容完全一致。
- 关于[Google的bbr加速](http://feiyang.li/2017/05/05/ss-panel-full/index.html#谷歌BBR加速)，与本脚本可以通用，但是因为效果不明显(可能因为我们实验室网太烂了吧)，所以我没有加入。

---

第一次写脚本，还请多多指教~
