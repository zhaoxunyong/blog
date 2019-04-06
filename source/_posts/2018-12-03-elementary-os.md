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

## docker缩放
```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository ppa:ricotz/docky
sudo apt upgrade
killall plank
```

## 安装基础包

```bash
sudo apt-get install vim
sudo apt-get install unrar
#sudo apt install google-chrome-stable
#sudo apt install electron-ssr
sudo apt install aria2
```

## 安装Tweaks
```bash
sudo add-apt-repository ppa:philip.scott/elementary-tweaks
sudo apt-get update
sudo apt-get install elementary-tweaks
#sudo apt-get install dconf-editor
sudo apt-get install dconf-tools
#sudo apt install nautilus
```

## 修改操作系统配置
```bash
cat /proc/sys/fs/inotify/max_user_watches
#sudo vim /etc/sysctl.conf
fs.inotify.max_user_watches=524288
vm.overcommit_memory=1
sudo sysctl -p
```

重启系统，然后再通过应用中心下载：Eddy与GNOME Tweaks，GNOME Tweaks可以设置屏幕缩放。

## 系统托盘

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
background "#110e0e"
transparent true
window_layer bottom
grow_gravity SE
icon_gravity SE 
slot_size 25
icon_size 40
```

删除多余的网络图标：

```bash
sudo mv /etc/xdg/autostart/nm-applet.desktop ~/
```

~~cat /Developer/stalonetray.sh~~

~~#/bin/sh~~

~~sleep 1~~

~~/usr/bin/stalonetray~~

## electron-ssr

不需要翻墙的不需要安装。另外翻墙需要有相应的账户才行。

从[https://github.com/erguotou520/electron-ssr](https://github.com/erguotou520/electron-ssr)
中下载最新的版本安装。

如果是chrome浏览器，参考其他教程：安装个SwitchyOmega插件就行。具体可参考[SwitchyOmega.zip](/files/SwitchyOmega.zip)

配置环境变量：
vim ~/.bashrc
```conf
alias ll='ls -l'
export LANG=zh_CN.UTF-8

function proxy_off(){
    unset http_proxy
    unset https_proxy
    echo -e "The proxy has been closed!"
}
function proxy_on() {
    export no_proxy="127.0.0.1,localhost,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
    export http_proxy="http://127.0.0.1:1082"
    export https_proxy=$http_proxy
    echo -e "The proxy has been opened!"
}
```

使配置生效：
```bash
. ~/.bashrc
```

## 安装git
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

gui:

```bash
#https://www.gitkraken.com/
wget https://release.gitkraken.com/linux/gitkraken-amd64.deb
sudo dpkg -i gitkraken-amd64.deb
```

## 安装输入法

以下是五笔的输入法，如果是拼音的话可以直接搜索搜狗拼音并下载安装即可。

```bash
#sudo apt-get update
#sudo apt-get install im-config fcitx fcitx-config-gtk fcitx-table-wbpy
#重启系统后
#fcitx-config-gtk3
#https://www.beizigen.com/1934.html
#http://yongim.ys168.com/
wget http://ys-c.ys168.com/244626543/TJRtkVk4K465F3K6KM6/yong-lin-2.5.0-0.7z
cp -a yong /opt/
sudo /opt/yong/yong-tool.sh --install
/opt/yong/yong-tool.sh --select
#重启系统后
#如果希望五笔拼音一起打的话，修改五笔的配置为：mb/wbpy.ini
#快捷键：CTRL_LSHIFT LSHIFT CTRL_SPACE
```

## theme

### docky

不用安装。

```bash
#可以用docky替换掉plank
sudo apt-get install docky
```

禁止plank自动启动：
通过dconf搜索monitored-processes关键字，把其中的plank删除即可。
需要把：io.elementary.desktop.cerbere中的plank替换为docky。

### 皮肤

参考[https://vinceliuice.github.io/](https://vinceliuice.github.io/)
https://github.com/vinceliuice/Canta-theme

推荐几个漂亮的皮肤：

#### eOS-Sierra-Gtk

[eOS-Sierra-Gtk](https://github.com/btd1337/eOS-Sierra-Gtk)

```bash
git clone https://github.com/btd1337/eOS-Sierra-Gtk ~/.local/share/themes/eOS-Sierra-Gtk
gsettings set org.gnome.desktop.interface gtk-theme 'eOS-Sierra-Gtk'
```

最终效果：
![](/images/elementary_theme.png)

#### vimix-gtk-themes

[vimix-gtk-themes](https://github.com/vinceliuice/vimix-gtk-themes)

```bash
git clone https://github.com/vinceliuice/vimix-gtk-themes
cd vimix-gtk-themes
./Install
cd ..
git clone https://github.com/vinceliuice/vimix-icon-theme
cd vimix-icon-theme
./Installer.sh
```

最终效果：
![](/images/vimix-gtk-themes.png)

#### Sierra-gtk-theme

```bash
#https://github.com/vinceliuice/Sierra-gtk-theme
git clone https://github.com/vinceliuice/Sierra-gtk-theme.git
cd Sierra-gtk-theme
./install.sh
```

#### Macos-sierra-CT

```bash
git clone https://github.com/zayronxio/Macos-sierra-CT.git ~/.local/share/icons/Macos-sierra-CT
```

#### la-capitaine-icon-theme

```bash
#https://github.com/btd1337/La-Sierra-Icon-Theme
#https://github.com/keeferrourke/la-capitaine-icon-theme.git
mkdir ~/.local/share/icons
git clone https://github.com/btd1337/La-Sierra-Icon-Theme ~/.local/share/icons/La-Sierra 
#or
git clone https://github.com/keeferrourke/la-capitaine-icon-theme.git ~/.local/share/icons/la-capitaine-icon-theme
```

## 字体
```bash
#wget "https://dl-sh-ctc-2.pchome.net/25/rm/YosemiteSanFranciscoFont-master.zip"
#mv YosemiteSanFranciscoFont-master SanFranciscoFont
#sudo cp -a SanFranciscoFont /usr/share/fonts/
sudo git clone https://github.com/AppleDesignResources/SanFranciscoFont /usr/share/fonts/SanFranciscoFont
```
San Francisco Text Medium

## 添加application菜单

```bash
#https://elementaryos.stackexchange.com/questions/2883/how-can-i-change-the-icon-of-an-application-in-the-elementary-os
sudo apt-get install alacarte
#Icon=/home/dave/.local/share/icons/hicolor/512x512/apps/appimagekit-balena-etcher-electron.png
#rm ~/.config/menus/gnome-applications.menu
#打开主菜单就可以进行添加与修改了
```

## wingpanel-indicator-sys-monitor

```bash
#https://www.linuxslaves.com/2018/10/install-wingpanel-system-monitor-indicator-elementary-os-juno.html
#https://github.com/PlugaruT/wingpanel-indicator-sys-monitor
sudo apt-get install git libglib2.0-dev libgtop2-dev libgranite-dev libgtk-3-dev libwingpanel-2.0-dev meson valac
git clone https://github.com/PlugaruT/wingpanel-indicator-sys-monitor.git && cd wingpanel-indicator-sys-monitor
meson build --prefix=/usr && cd build/ && ninja
sudo ninja install
```

## 桌面图标
```bash
#https://github.com/spheras/desktopfolder
#download file from https://github.com/spheras/desktopfolder/releases
sudo dpkg -i com.github.spheras.desktopfolder_1.0.10_amd64.deb
# logout and login
```

## 修改开机启动画面

可选。如果不想修改开机启动画面的话，可以不用安装。

```bash
#https://tianyijian.github.io/2018/04/05/ubuntu-boot-animation/
#https://www.gnome-look.org/browse/cat/109/ord/latest/
#https://www.gnome-look.org/p/1237117/
unzip Griffin-Grub-Remix.zip
cd Griffin-Grub-Remix/
sudo ./Install.sh
#reboot
```

在系统设置-->启动应用程序中添加/usr/bin/stalonetray即可。
也可以在dconf中添加：io.elementary.desktop.cerbere中添加stalonetray。如果被kill会自动启动。

## deepin-wine-for-ubuntu
deepin优化了很多wine的包，可以直接拿来使用：
```bash
#https://github.com/wszqkzqk/deepin-wine-ubuntu
#克隆 (git clone https://github.com/wszqkzqk/deepin-wine-ubuntu.git) 或下载到本地。
git clone https://github.com/wszqkzqk/deepin-wine-ubuntu.git
#在中国推荐用下面的地址，速度更快： (git clone https://gitee.com/wszqkzqk/deepin-wine-for-ubuntu.git)
cd deepin-wine-ubuntu
sudo ./install.sh
```

## 截图
可以在应用中心搜索"深度截图"。

## 常用快捷键
```bash
xdg-open . -> Win+E
deepin-screenshot -> ctrl+alt+Q
#deepin-terminal -> ctrl+alt+T
io.elementary.terminal -> ctrl+alt+T
```

## weixin
```bash
wget http://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.wechat/deepin.com.wechat_2.6.2.31deepin0_i386.deb
sudo dpkg -i deepin.com.wechat_2.6.2.31deepin0_i386.deb
#配置，修改显示为160dpi
WINEPREFIX=~/.deepinwine/Deepin-WeChat deepin-wine winecfg
```

## RTX
```bash
wget http://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.qq.rtx2015/deepin.com.qq.rtx2015_8.3.649.1deepin0_i386.deb
sudo dpkg -i deepin.com.qq.rtx2015_8.3.649.1deepin0_i386.deb
#如果安装报错，先执行一下sudo apt-get install -f，再重新安装即可。
#配置，修改显示为120dpi
WINEPREFIX=~/.deepinwine/Deepin-RTX2015 deepin-wine winecfg
#修改idle时间，只能直接修改文件内容，不然会启动不了
#vim "/home/dave/文档/RTXC File List/c_Program Files_Tencent_RTXC/Accounts/dave.zhao/User.cfg"
reply_page_bAutoChangeState=0
reply_page_nTimeCount=30
```

英文操作系统不能输入中文解决, 参考[https://blog.csdn.net/deccmtd/article/details/5529736](https://blog.csdn.net/deccmtd/article/details/5529736)

把下面的代码保存为winefont.reg 
REGEDIT4 
[HKEY_LOCAL_MACHINE/Software/Microsoft/Windows NT/CurrentVersion/FontSubstitutes] 
"Arial"="simsun" 
"Arial CE,238"="simsun" 
"Arial CYR,204"="simsun" 
"Arial Greek,161"="simsun" 
"Arial TUR,162"="simsun" 
"Courier New"="simsun" 
"Courier New CE,238"="simsun" 
"Courier New CYR,204"="simsun" 
"Courier New Greek,161"="simsun" 
"Courier New TUR,162"="simsun" 
"FixedSys"="simsun" 
"Helv"="simsun" 
"Helvetica"="simsun" 
"MS Sans Serif"="simsun" 
"MS Shell Dlg"="simsun" 
"MS Shell Dlg 2"="simsun" 
"System"="simsun" 
"Tahoma"="simsun" 
"Times"="simsun" 
"Times New Roman CE,238"="simsun" 
"Times New Roman CYR,204"="simsun" 
"Times New Roman Greek,161"="simsun" 
"Times New Roman TUR,162"="simsun" 
"Tms Rmn"="simsun" 

```bash
WINEPREFIX=~/.deepinwine/Deepin-RTX2015 deepin-wine regedit winefont.reg
```

从Windows目录下的Fonts里的simsun.ttc复制到/home/dave/.deepinwine/Deepin-RTX2015/drive_c/windows/Fonts里面, 重启即可。

```bash
wget https://github.com/sonatype/maven-guide-zh/raw/master/content-zh/src/main/resources/fonts/simsun.ttc -O /home/dave/.deepinwine/Deepin-RTX2015/drive_c/windows/Fonts/
```

如果启动不了，直接删除Accounts目录即可。如果组织架构出不来，可以把好的机器中的Accounts目录下除User.cfg外所有的文件copy覆盖掉。

## QQ
```bash
wget http://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.qq.im/deepin.com.qq.im_8.9.19983deepin23_i386.deb
sudo dpkg -i deepin.com.qq.im_8.9.19983deepin23_i386.deb
#配置，修改显示为120dpi
WINEPREFIX=~/.deepinwine/Deepin-QQ deepin-wine winecfg
```

## 安装slingscold启动器
```bash
sudo add-apt-repository ppa:noobslab/macbuntu
sudo apt-get update
sudo apt-get install slingscold
```

## Mailspring
从https://getmailspring.com/download下载对应的版本安装即可。

## vscode
安装以下插件：
```bash
#java
Java Extension Pack
Spring Boot Extension Pack
Java Code Generators
Eclipse Keymap
Docker
#vue
Vetur
Vue VSCode Snippets
#react
ES7 React/Redux/GraphQL/React-Native snippets
#git
GitLens
zerofinance-git
#其他公共插件
Color Picker
npm
Debugger for Chrome
Local History
AutoFileName
koroFileHeader
XML Tools
#android/ios plugin
Android iOS Emulator
React Native Tools
#see debug:https://github.com/Microsoft/vscode-react-native/blob/master/doc/debugging.md#debugging-on-ios-device
```

## WPS字体
```bash
#https://blog.huzhifeng.com/2017/01/15/WPS/
#https://www.dropbox.com/s/q6rhaorhsbxbylk/wps_symbol_fonts.zip?dl=0
sudo mkdir -p /usr/share/fonts/wps_symbol_fonts
sudo unzip wps_symbol_fonts.zip -d /usr/share/fonts/wps_symbol_fonts
sudo chmod 755 /usr/share/fonts/wps_symbol_fonts
```

## VPN
```bash
sudo apt-get install network-manager-openconnect-gnome
sudo mkdir -p /etc/vpn
cd /etc/vpn
sudo wget http://git.infradead.org/users/dwmw2/vpnc-scripts.git/blob_plain/HEAD:/vpnc-script
sudo chmod +x /etc/vpn/vpnc-script 
# execute
sudo openconnect -u aaa --script=/etc/vpn/vpnc-script --no-dtls x.x.x.x
```

也可以通过自动输入密码：

安装spawn：

```bash
#安装spawn
sudo apt install expect
```

以下为对应的脚本：

```bash
#!/usr/bin/expect

set timeout -1
#set PWD vagrant
#spawn passwd
spawn openconnect -u 对应的用户 --script=/etc/vpn/vpnc-script --no-dtls ip
expect "确定"
send "确定\r"
expect "Password:"
send "对应的密码\r"
interact
#expect eof
```

## java

sudo vim /etc/profile.d/java.sh
```bash
export ANDROID_HOME=/Developer/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator

export JAVA_HOME=/Developer/java/jdk1.8.0_152
export M2_HOME=/Developer/apache-maven-3.3.9
export PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH
```
使配置生效：
```bash
source /etc/profile
```

## nodejs

```bash
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
. ~/.bashrc
#显示有远端的版本
nvm ls-remote
#安装对应的版本
nvm install v10.15.3
```

安装常用工具：

```bash
npm install  hexo-cli -g
npm install hexo-server -g
npm install hexo-deployer-git -g
npm install yarn -g
npm install http-server -g
yarn global add serve

```

## 其它一些常用工具
```bash
#https://www.jianshu.com/p/1e104090ffaa
sudo apt-get install keepassx
sudo apt-get install vlc
sudo apt install synapse
#synapse也可以用albert代替：https://github.com/albertlauncher/albert
#yahei
wget -qO- https://raw.githubusercontent.com/yakumioto/YaHei-Consolas-Hybrid-1.12/master/install.sh | sudo sh
#将alt键打造成command键
sudo vi /usr/share/X11/xkb/keycodes/evdev
#找到LCTL和LALT, 将系统默认的LCTL=37, LALT=64的值互相交换即可。
```

## 添加打印机

### Linux

```bash
#https://www.kyoceradocumentsolutions.co.za/index/service___support/download_center.false.driver.FS6525MFP._.EN.html#
cd "LinuxPackages/FS-6525MFP series/64bit/Global/English"
sudo ./install.sh
sudo apt install system-config-printer
system-config-printer
#输入URI
socket://192.168.101.2:9100
#选择Provide PPD file->Kyocera FS-6525MFP驱动即可。
```

### MAC

```bash
#https://warwick.ac.uk/fac/soc/wbs/central/issu/help/kb/hardware/printers/kyoceramac-win/
wget https://warwick.ac.uk/fac/soc/wbs/central/issu/help/kb/hardware/printers/kyoceramac-win/macphase4.0_2018.01.19-eu.zip
#install Kyocera OS X 10.8+ Web build 2018.01.05.dmg
#参考上面的网址配置即可。如果是windows smb的话，地址为：smb://192.168.100.105/Kyocera02
#驱动选择Kyocera FS-6525MFP
```

## Beyond Compare

```bash
wget http://mirrors.aliyun.com/deepin/pool/non-free/b/bcompare/bcompare_4.1.9-21719_amd64.deb
sudo dpkg -i bcompare_4.1.9-21719_amd64.deb
#register
#https://gist.github.com/satish-setty/04e1058d3043f4d10e2d52feebe135e8
#https://my.oschina.net/sfshine/blog/1829595
sudo sed -i "s/keexjEP3t4Mue23hrnuPtY4TdcsqNiJL-5174TsUdLmJSIXKfG2NGPwBL6vnRPddT7tH29qpkneX63DO9ECSPE9rzY1zhThHERg8lHM9IBFT+rVuiY823aQJuqzxCKIE1bcDqM4wgW01FH6oCBP1G4ub01xmb4BGSUG6ZrjxWHJyNLyIlGvOhoY2HAYzEtzYGwxFZn2JZ66o4RONkXjX0DF9EzsdUef3UAS+JQ+fCYReLawdjEe6tXCv88GKaaPKWxCeaUL9PejICQgRQOLGOZtZQkLgAelrOtehxz5ANOOqCaJgy2mJLQVLM5SJ9Dli909c5ybvEhVmIC0dc9dWH+/N9KmiLVlKMU7RJqnE+WXEEPI1SgglmfmLc1yVH7dqBb9ehOoKG9UE+HAE1YvH1XX2XVGeEqYUY-Tsk7YBTz0WpSpoYyPgx6Iki5KLtQ5G-aKP9eysnkuOAkrvHU8bLbGtZteGwJarev03PhfCioJL4OSqsmQGEvDbHFEbNl1qJtdwEriR+VNZts9vNNLk7UGfeNwIiqpxjk4Mn09nmSd8FhM4ifvcaIbNCRoMPGl6KU12iseSe+w+1kFsLhX+OhQM8WXcWV10cGqBzQE9OqOLUcg9n0krrR3KrohstS9smTwEx9olyLYppvC0p5i7dAx2deWvM1ZxKNs0BvcXGukR+/g" /usr/lib/beyondcompare/BCompare
```

Then restart BC, click "Enter License":

--- BEGIN LICENSE KEY ---
GXN1eh9FbDiX1ACdd7XKMV7hL7x0ClBJLUJ-zFfKofjaj2yxE53xauIfkqZ8FoLpcZ0Ux6McTyNmODDSvSIHLYhg1QkTxjCeSCk6ARz0ABJcnUmd3dZYJNWFyJun14rmGByRnVPL49QH+Rs0kjRGKCB-cb8IT4Gf0Ue9WMQ1A6t31MO9jmjoYUeoUmbeAQSofvuK8GN1rLRv7WXfUJ0uyvYlGLqzq1ZoJAJDyo0Kdr4ThF-IXcv2cxVyWVW1SaMq8GFosDEGThnY7C-SgNXW30jqAOgiRjKKRX9RuNeDMFqgP2cuf0NMvyMrMScnM1ZyiAaJJtzbxqN5hZOMClUTE+++
--- END LICENSE KEY -----

## XMind 8

```bash
wget http://dl2.xmind.cn/xmind-8-update8-linux.zip
sudo unzip xmind-8-update8-linux.zip -d /opt/xmind-8
#run /opt/xmind-8/XMind_amd64/XMind
#Put icon into applications, you should create a file:
#cd /opt/xmind-8/XMind_amd64/
#echo "cd /opt/xmind-8/XMind_amd64 && ./XMind" > xmind
#chmod +x xmind
#If you want to crack, please see: http://blog.slpro.cn/posts/eb75c5c4/
```

## 网易云音乐

```bash
#https://www.zhihu.com/question/277330447
#vim /usr/share/applications/netease-cloud-music.desktop
#修改Exec为：
Exec=sh -c "unset SESSION_MANAGER && netease-cloud-music %U"
```

## virtualbox

下载virtualbox与Extension_Pack，直接安装即可。不过安装后虚拟机不能找到usb，是因为没有权限，通过以下命令解决：

```bash
#https://blog.csdn.net/huohongpeng/article/details/60965563
cat /etc/group | grep vbox
sudo usermod -a -G vboxusers dave
```

重启系统，再次打开虚拟机，USB设备都已经被识别了。

## 系统备份与还原

### 备份

```bash
#https://blog.csdn.net/sinat_27554409/article/details/78227496
#备份
sudo tar -cvpzf /media/dave/DATA/elementary.backup.tgz --ignore-failed-read --exclude=/proc --exclude=/lost+found --exclude=/mnt --exclude=/sys --exclude=/media --exclude=/tmp --exclude=/Developer / > /dev/null
```

### 还原

如果原来的Ubuntu系统已经崩溃，无法进入。则可以使用Ubuntu安装U盘（live USB）进入试用Ubuntu界面。

切换到root用户，找到之前Ubuntu系统的根目录所在磁盘分区（一般电脑上的磁盘分区（假设分区名称为sdaX）均可以在当前Ubuntu系统的根目录下的media目录下（即/media）找到。目录通常为当前根目录下 cd /media/磁盘名称/分区名称）。进入该分区，输入以下指令来删除该根目录下的所有文件：

```bash
sudo rm -rf /media/磁盘名称/分区名称*
```

将备份文件”elementary.backup.tgz”拷入该分区：
```bash
sudo cp -i elementary.backup.tgz /media/磁盘名/分区名sdaX
```

进入分区并将压缩文件解压缩，参数x是告诉tar程序解压缩备份文件：
```bash
sudo tar xvpfz elementary.backup.tgz
```

重新创建那些在备份时被排除在外的目录：
```bash
sudo mkdir proc lost+found mnt sys media tmp Developer
```

- https://blog.daliansky.net/Intel-FB-Patcher-tutorial-and-insertion-pose.html
- https://www.bilibili.com/video/av46767597?from=search&seid=18234894269411097533
- https://github.com/acidanthera/AppleALC

inject id=3