---
title: elementary os
date: 2018-12-03 10:06:39
categories: ["Linux"]
tags: ["Linux"]
toc: true
---

Elementary OS作为Ubuntu的扩展分之，号称是最美的Linux发行版。系统不仅主题美而且对Ubuntu进行了大幅精简，系统结构显得轻巧不少，运行效率也不错，官方甚至打出了“A fast and open replacement for Windows and macOS”的口号，其野心可见一班。

<!-- more -->

## 安装操作系统

从官网[https://elementary.io/zh_CN/](https://elementary.io/zh_CN/)中下载iso文件，下载时输入金额为0即可。用Universal-USB-Installer.exe刻录成U盘进行安装。

## 系统配置

### 安装基础包

### docker缩放
```bash
sudo add-apt-repository ppa:ricotz/docky
sudo apt update
sudo apt upgrade
killall plank
```

先更新应用中心，再通过应用中心下载：Eddy与GNOME Tweaks，GNOME Tweaks可以设置屏幕缩放。

```bash
sudo apt-get update
sudo apt-get install vim
sudo apt install software-properties-common
```



### electron-ssr

从[https://github.com/erguotou520/electron-ssr](https://github.com/erguotou520/electron-ssr)
中下载最新的版本安装。

安装privoxy：
electron-ssr的http暂时不能用，可能使用privoxy将socks转为http。
```bash
sudo apt-get install privoxy
```

配置：
vim /etc/privoxy/config
```bash
listen-address  0.0.0.0:1082
# shadowsocks 的本地端口
forward-socks5t / 127.0.0.1:1081 .
```

启动：
```bash
sudo systemctl restart privoxy
```

配置环境变量：
vim ~/.bashrc
```conf
alias ll='ls -l'
export LANG=zh_CN.UTF-8
#alias proxy_on="export ALL_PROXY=socks5://127.0.0.1:1081"
#alias proxy_off="unset ALL_PROXY"
#alias ip="curl -i http://ip.cn"
#alias no_proxy="export NO_PROXY=127.0.0.1,localhost,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
alias cnpm="npm --registry=https://registry.npm.taobao.org \
--cache=$HOME/.npm/.cache/cnpm \
--disturl=https://npm.taobao.org/dist \
--userconfig=$HOME/.cnpmrc"

function proxy_off(){
    unset http_proxy
    unset https_proxy
    echo -e "已关闭代理"
}
function proxy_on() {
    export no_proxy="127.0.0.1,localhost,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
    export http_proxy="socks5://127.0.0.1:1081"
    export https_proxy=$http_proxy
    echo -e "已开启代理"
}
```

使配置生效：
```bash
. ~/.bashrc
```

### 安装git
```bash
sudo apt-get install git
git config --global user.name "dave.zhao"
git config --global user.email dave.zhao@zerofinance.cn
git config --global core.autocrlf false
git config --global core.safecrlf warn
git config --global core.filemode false
git config --global core.whitespace cr-at-eol
git config --global credential.helper store
```

### 安装输入法
```bash
sudo apt-get update
sudo apt-get install im-config fcitx fcitx-config-gtk fcitx-table-wbpy
#重启系统后
fcitx-config-gtk3
```

### 安装Tweaks
```bash
sudo add-apt-repository ppa:philip.scott/elementary-tweaks
sudo apt-get update
sudo apt-get install elementary-tweaks
#sudo apt-get install dconf-editor
sudo apt-get install dconf-tools
```

### theme

#### 皮肤
```bash
#sudo apt-get install docky
#https://mega.nz/#!9wJC1KJC!KdcjjV1HIOjaU1nbMsUT5nnHl8ahmuYjcQiv4KmhoMI
unzip Elementary-Pack.zip
cd Elementary-Pack
cp -r Icons/* ~/.icons
cp -r Themes/* ~/.themes
#cp -r  Plank/* ~/.local/share/plank/themes
```

macOS High Sierra:
```bash
#https://b00merang.weebly.com/macos-mojave.html
#https://github.com/B00merang-Project/macOS
mkdir ~/.themes/
cd ~/.themes/
git clone https://github.com/B00merang-Project/macOS
mv macOS macOS-High-Sierra
gsettings set org.gnome.desktop.interface gtk-theme "macOS-High-Sierra"
gsettings set org.gnome.desktop.wm.preferences theme "macOS-High-Sierra"
```

macOS Dark Sierra:
```
#https://github.com/B00merang-Project/macOS-Dark
cd ~/.themes/
git clone https://github.com/B00merang-Project/macOS-Dark
mv macOS-Dark macOS-Dark-Sierra
gsettings set org.gnome.desktop.interface gtk-theme "macOS-Dark-Sierra"
gsettings set org.gnome.desktop.wm.preferences theme "macOS-Dark-Sierra"
```

la-capitaine-icon-theme:
```bash
#https://github.com/keeferrourke/la-capitaine-icon-theme.git
mkdir ~/.icons
cd ~/.icons
git clone https://github.com/keeferrourke/la-capitaine-icon-theme.git
```

#### 字体
```bash
wget "https://dl-sh-ctc-2.pchome.net/25/rm/YosemiteSanFranciscoFont-master.zip?key=undefined&tmp=1543759995331"
mv YosemiteSanFranciscoFont-master SanFranciscoFont
sudo cp -a SanFranciscoFont /usr/share/fonts/
```
San Francisco Text Medium

### 系统托盘

安装stalonetray：
```bash
sudo apt-get install stalonetray
```

配置：
vim ~/.stalonetrayrc
```conf
geometry 1x1+1825+990
transparent true
window_layer top
slot_size 24
icon_size 16
```

在系统设置-->启动应用程序中添加/usr/bin/stalonetray即可

### wingpanel
好像是要安装elementary-indicators，不是wingpanel。待验证。

系统默认的顶部状态条不能显示已经安装的程序图标，需要安装wingpanel:
```bash
#https://github.com/elementary/wingpanel
git clone https://github.com/elementary/wingpanel.git
cd wingpanel
sudo apt-get install libgala-dev libgee-0.8-dev libglib2.0-dev libgranite-dev libgtk-3-dev meson libmutter-2-dev valac
meson build --prefix=/usr
cd build
ninja
sudo ninja install
wingpanel
```

https://github.com/mdh34/elementary-indicators


### Cerbere
好像不用安装。待验证。
```bash
git clone https://github.com/elementary/cerbere.git
cd cerbere
meson build --prefix=/usr
cd build
ninja
#To install, use ninja install, then execute with io.elementary.cerbere
sudo ninja install
io.elementary.cerbere
```
### deepin-wine-for-ubuntu
deepin优化了很多wine的包，可以直接拿来使用：
```bash
#https://github.com/wszqkzqk/deepin-wine-ubuntu
wget -qO- https://raw.githubusercontent.com/wszqkzqk/deepin-wine-ubuntu/master/online_install.sh | bash -e
```

### weixin
```bash
wget http://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.wechat/deepin.com.wechat_2.6.2.31deepin0_i386.deb
sudo dpkg -i deepin.com.wechat_2.6.2.31deepin0_i386.deb
#配置
WINEPREFIX=~/.deepinwine/Deepin-WeChat deepin-wine winecfg
```

### RTX
```bash
wget http://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.qq.rtx2015/deepin.com.qq.rtx2015_8.3.649.1deepin0_i386.deb
sudo dpkg -i deepin.com.qq.rtx2015_8.3.649.1deepin0_i386.deb
#配置
WINEPREFIX=~/.deepinwine/Deepin-RTX2015 deepin-wine winecfg
#修改idle时间，只能直接修改文件内容，不然会启动不了
#vim "/home/dave/文档/RTXC File List/c_Program Files_Tencent_RTXC/Accounts/User.cfg"
reply_page_nTimeCount=30
```

如果启动不了，直接删除Accounts目录即可。

### QQ
```bash
wget http://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.qq.im/deepin.com.qq.im_8.9.19983deepin23_i386.deb
sudo dpkg -i deepin.com.qq.im_8.9.19983deepin23_i386.deb
#配置
WINEPREFIX=~/.deepinwine/Deepin-QQ deepin-wine winecfg
```

### 安装slingscold启动器
```bash
sudo add-apt-repository ppa:noobslab/macbuntu
sudo apt-get update
sudo apt-get install slingscold
```

### vscode
安装以下插件：
```bash
XML Tools
Debugger for Chrome
Java Extension Pack
Local History
Spring Boot Tools
Spring Initializr Java Support
Vetur
Java Code Generators
Vue VSCode Snippets
```