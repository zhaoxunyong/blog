---
title: elementary os
date: 2018-12-03 10:06:39
categories: ["Linux"]
tags: ["Linux"]
toc: true
---

Elementary OS作为Ubuntu的扩展分支，号称是最美的Linux发行版。系统不仅主题美而且对Ubuntu进行了大幅精简，系统结构显得轻巧不少，运行效率也不错，官方甚至打出了“A fast and open replacement for Windows and macOS”的口号，其野心可见一班。

<!-- more -->

## 安装操作系统

从官网[https://elementary.io/zh_CN/](https://elementary.io/zh_CN/)中下载iso文件，下载时输入金额为0即可。用Universal-USB-Installer.exe刻录成U盘进行安装。

## 系统配置

### 修改操作系统配置
```bash
cat /proc/sys/fs/inotify/max_user_watches
#sudo vim /etc/sysctl.conf
fs.inotify.max_user_watches=524288
sudo sysctl -p
```

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
#sudo apt-get update
#sudo apt-get install im-config fcitx fcitx-config-gtk fcitx-table-wbpy
#重启系统后
#fcitx-config-gtk3
#https://www.beizigen.com/1934.html
wget http://ys-o.ys168.com/244626558/o4I4J7G3N5JMVjsSLVU/yong-lin-2.4.0-0.7z
sudo /opt/yong/yong-tool.sh --install
/opt/yong/yong-tool.sh --select
#重启系统后
#如果希望五笔拼音一起打的话，修改五笔的配置为：mb/pinyin.ini
#快捷键：CTRL_LSHIFT LSHIFT CTRL_SPACE
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
#可以用docky替换掉plank
sudo apt-get install docky
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

### Cerbere
```bash
#https://www.omgubuntu.co.uk/2018/01/elementary-desktop-icons-files-app
#https://elementaryos.stackexchange.com/questions/1951/how-to-disable-plank
git clone https://github.com/elementary/cerbere.git
cd cerbere
meson build --prefix=/usr
cd build
ninja
#To install, use ninja install, then execute with io.elementary.cerbere
sudo ninja install
io.elementary.cerbere
```

禁止plank自动启动：
通过dconf搜索monitored-processes关键字，把其中的plank删除即可。
需要删除：io.elementary.desktop.cerbere中的plank才行。

### 系统托盘

安装stalonetray：
```bash
sudo apt-get install stalonetray
```

配置：
vim ~/.stalonetrayrc
```conf
#geometry 1x1+1700+1040
#transparent true
#window_layer top
#slot_size 14
#icon_size 30
#http://stalonetray.sourceforge.net/manpage.html
geometry  1x1+1890-0
transparent true
window_layer top
grow_gravity SE
icon_gravity SE 
slot_size 14
icon_size 30
```

### 桌面图标
```bash
#https://github.com/spheras/desktopfolder
#download file from https://github.com/spheras/desktopfolder/releases
sudo apt install ./com.github.spheras.desktopfolder_[version]_amd64.deb
# logout and login
```

在系统设置-->启动应用程序中添加/usr/bin/stalonetray即可。
也可以在dconf中添加：io.elementary.desktop.cerbere中添加stalonetray。如果被kill会自动启动。

### deepin-wine-for-ubuntu
deepin优化了很多wine的包，可以直接拿来使用：
```bash
#https://github.com/wszqkzqk/deepin-wine-ubuntu
#克隆 (git clone https://github.com/wszqkzqk/deepin-wine-ubuntu.git) 或下载到本地。
git clone https://github.com/wszqkzqk/deepin-wine-ubuntu.git
#在中国推荐用下面的地址，速度更快： (git clone https://gitee.com/wszqkzqk/deepin-wine-for-ubuntu.git)
cd deepin-wine-ubuntu
sudo ./install.sh
```

### 截图
可以在应用中心搜索"深度截图"。

### 常用快捷键
```bash
xdg-open . -> Win+E
deepin-screenshot -> ctrl+alt+Q
deepin-terminal -> ctrl+alt+T
```

### weixin
```bash
wget http://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.wechat/deepin.com.wechat_2.6.2.31deepin0_i386.deb
sudo dpkg -i deepin.com.wechat_2.6.2.31deepin0_i386.deb
#配置，修改显示为160
WINEPREFIX=~/.deepinwine/Deepin-WeChat deepin-wine winecfg
```

### RTX
```bash
wget http://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.qq.rtx2015/deepin.com.qq.rtx2015_8.3.649.1deepin0_i386.deb
sudo dpkg -i deepin.com.qq.rtx2015_8.3.649.1deepin0_i386.deb
#如果安装报错，先执行一下sudo apt-get install -f，再重新安装即可。
#配置
WINEPREFIX=~/.deepinwine/Deepin-RTX2015 deepin-wine winecfg
#修改idle时间，只能直接修改文件内容，不然会启动不了
#vim "/home/dave/文档/RTXC File List/c_Program Files_Tencent_RTXC/Accounts/dave.zhao/User.cfg"
reply_page_bAutoChangeState=0
reply_page_nTimeCount=30
```

如果启动不了，直接删除Accounts目录即可。如果组织架构出不来，可以把好的机器中的Accounts目录下除User.cfg外所有的文件copy覆盖掉。

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
Eclipse Keymap
```

### WPS字体
```bash
#https://blog.huzhifeng.com/2017/01/15/WPS/
#https://www.dropbox.com/s/q6rhaorhsbxbylk/wps_symbol_fonts.zip?dl=0
sudo mkdir -p /usr/share/fonts/wps_symbol_fonts
sudo unzip wps_symbol_fonts.zip -d /usr/share/fonts/wps_symbol_fonts
sudo chmod 755 /usr/share/fonts/wps_symbol_fonts
```

### VPN
```bash
sudo apt-get install network-manager-openconnect-gnome
sudo mkdir -p /etc/vpn
cd /etc/vpn
sudo wget http://git.infradead.org/users/dwmw2/vpnc-scripts.git/blob_plain/HEAD:/vpnc-script
sudo chmod +x /etc/vpn/vpnc-script 
# execute
sudo openconnect -u aaa --script=/etc/vpn/vpnc-script --no-dtls x.x.x.x
```

### java

sudo vim /etc/profile.d/java.sh
```bash
export JAVA_HOME=/Developer/java/jdk1.8.0_152
export M2_HOME=/Developer/apache-maven-3.3.9
export PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH
```
使配置生效：
```bash
source /etc/profile
```

### 其它一些常用工具
```bash
#https://www.jianshu.com/p/1e104090ffaa
sudo apt-get install keepassx
sudo apt-get install vlc
#yahei
wget -qO- https://raw.githubusercontent.com/yakumioto/YaHei-Consolas-Hybrid-1.12/master/install.sh | sudo sh

```

### 添加打印机
```bash
cd /media/dave/DATA/os/LinuxPackages/FS-6525MFP series/64bit/Global/English
sudo ./install.sh
sudo apt install system-config-printer
system-config-printer
#输入URI
socket://192.168.101.2:9100
#选择Kyocera FS-6525MFP驱动即可。
```
