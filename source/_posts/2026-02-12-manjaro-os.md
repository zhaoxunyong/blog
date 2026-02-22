---
title: manjaro-os
date: 2026-02-12 11:50:03
categories: ["Linux"]
tags: ["Linux"]
toc: true
---

记录manjaro的安装过程。

<!-- more -->

## 安装操作系统

[https://manjaro.org/products/download/x86](https://manjaro.org/products/download/x86)

GNOME is a modern desktop, the layout is different from other options but easy and intuitive to learn.

## 优化apt

Recommend: Add/Remove Software & Preferences->Use mirrors from: Change to China, and Refresh Mirrors.

Upgrade:
```
sudo pacman -Syu
```

## 安装基础包

```bash
#pacman
#https://zhuanlan.zhihu.com/p/383694450
sudo pacman -S pacman-contrib vim xorg-mkfontscale net-tools jq lrzsz

#yay
sudo pacman -S yay
#将 Yay 升级到新版本
yay -Sua
#升级所有包（含 AUR）
pacman -Syu
yay -Syu 
#清理不需要的依赖 
yay -Yc 
#降级软件包版本
yay -S downgrade
sudo downgrade 包名
#自动化安装
yay -S packagename --noconfirm --needed

#paru
#https://zhuanlan.zhihu.com/p/350920414
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
#usage like yay

#debtap
yay -S debtap
debtap package
sudo pacman -U package.xtz

#homebrew
#https://brew.sh/
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"


#安装输入法
#https://zhuanlan.zhihu.com/p/468426138
sudo pacman -Rs $(pacman -Qsq fcitx)
sudo pacman -S fcitx5 
sudo pacman -S fcitx5-configtool  
sudo pacman -S fcitx5-qt
sudo pacman -S fcitx5-gtk
sudo pacman -S fcitx5-chinese-addons

#安装Input Method Panel
https://extensions.gnome.org/extension/261/kimpanel/

#安装sogou
#yay -S fcitx5-sogou
#reboot

# Windows字体
https://rrroger.github.io/notebook/linux/Ubuntu%E5%AE%89%E8%A3%85%E5%BE%AE%E8%BD%AF%E5%AD%97%E4%BD%93.html
https://www.cnblogs.com/liutongqing/p/7923297.html

sudo git clone https://github.com/fernvenue/microsoft-yahei.git /usr/share/fonts/truetype/windows-font
sudo chmod -R 777  /usr/share/fonts/truetype/windows-font
cd /usr/share/fonts/truetype/windows-font
sudo rm -fr /usr/share/fonts/truetype/windows-font/.git
sudo mkfontscale
sudo mkfontdir
sudo fc-cache -fv
#查看已经安装的中文字体
fc-list :lang=zh

#常用软件
yay -S microsoft-edge-stable-bin 
#旧机器需要在/usr/share/applications/microsoft-edge.desktop中添加：Exec=/usr/bin/microsoft-edge-stable --disable-gpu %U
#betterbird安装后，需要安装plugin: Minimize on Close
yay -S betterbird
yay -S wps-office-cn
#yay -Ss visual-studio-code
yay -S visual-studio-code-bin
yay -S cursor-bin
yay -S safeeyes
yay -S snipaste
#rsync -avP dave@192.168.3.37:~/.config/tabby ~/.config/ 
yay -S tabby-bin
yay -S feishu-bin
yay -S google-chrome
yay -S lx-music
yay -S musicfree
yay -S wechat-bin
yay -S xunlei-bin
yay -S alacarte
#多屏壁纸
yay -S hydrapaper
#录屏
yay -S kooha
sudo pacman -Syu ffmpeg vlc mpv celluloid
#Typora
#https://github.com/SSRVodka/typora-aur-1.9.3-1
wget https://github.com/SSRVodka/typora-aur-1.9.3-1/releases/download/1.9.3/typora_1.9.3_amd64.deb
debtap typora_1.9.3_amd64.deb
sudo pacman -U typora-1.9.3-1-x86_64.pkg.tar.zst

#ulauncher
#https://ulauncher.io/
cd /tmp && git clone https://aur.archlinux.org/ulauncher.git && cd ulauncher && makepkg -is


#Tweaks->Startup Applications
Betterbird
Ulauncher
Safe Eyes
Snipate
Feishu

#快捷键
Snipaste  Snipaste snip -> F1
ulauncher ulauncher-toggle -> Alt+Space
xdg-open  xdg-open . -> Super+E
显示桌面：搜索Hide all normal windows，设置Super+D

#kubectl:
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv kubectl /usr/local/bin/

#.zshrc
alias ll="ls -l"
alias sudo='sudo '
alias rm="/works/shell/rm.sh"
alias k=kubectl
#source <(kubectl completion bash | sed s/kubectl/k/g)

function proxy_off(){
    unset http_proxy
    unset https_proxy
    echo -e "The proxy has been closed!"
}
function proxy_on() {
    export no_proxy="127.0.0.1,localhost,10.0.0.0/8,172.0.0.0/8,192.168.0.0/16,*.zerofinance.net,*.aliyun.com,*.163.com,*.docker-cn.com,registry.gcalls.cn"
    export http_proxy="http://127.0.0.1:1082"
    export https_proxy=$http_proxy
    echo -e "The proxy has been opened!"
}

. ~/.zshrc

#git
git config --global user.name "dave.zhao"
git config --global user.email dave.zhao@zerofinance.com
git config --global core.autocrlf false
git config --global core.safecrlf warn
git config --global core.filemode false
git config --global core.whitespace cr-at-eol
git config --global credential.helper store
```

## Yay命令

https://wiki.archlinuxcn.org/wiki/Yay

https://ehewen.com/blog/yay/

```bash
功能	                  命令
搜索包（官方 + AUR）	      yay 包名
安装软件包	               yay -S 包名
升级所有包（含 AUR）	      yay -Syu
清理缓存文件	             yay -Sc
删除无用依赖	             yay -Yc
删除软件包及配置	          yay -Rns 包名
仅安装 AUR 包	             yay -S 包名 --aur
仅安装官方包	             yay -S 包名 --repo
搜索安装包	               yay -Ss 包名
查看包信息	               yay -Si 包名
查看包的文件路径	           yay -Ql 包名
查找某文件属于哪个包	       yay -Qo 路径
查看包的详情	              yay -Qi 包名
查看所有 AUR 安装包	        yay -Qm
清理系统垃圾	              yay -Sc && yay -Yc
```

## howdy

```bash
#https://www.cnblogs.com/gardenialyx/p/19104354
#https://www.cnblogs.com/dingnosakura/p/18223572
yay -S howdy-git

#list camera
v4l2-ctl --list-devices

#修改 Howdy 配置文件
sudo vim /etc/howdy/config.ini
certainty = 4.5
device_path = /dev/video0


#如果你的摄像头有红外功能，还可以在最后一行加上这一句来让你的人脸识别在黑暗的环境下给你自动补光：
use_ir = true

#录入面部信息
#sudo howdy add -U dave
sudo howdy add

#删除人脸
#sudo howdy -U dave clear
sudo howdy clear

sudo vim /etc/pam.d/system-auth
#%PAM-1.0

auth sufficient pam_unix.so try_first_pass likeauth nullok
auth sufficient /usr/lib/security/pam_howdy.so

#测试人脸识别
sudo howdy test
#测试 sudo
sudo -i

```

## 扩展

```bash
#go to https://extensions.gnome.org/ and search:
Desktop Widgets(Desktop Clock)
Disable 3 Finger Gestures Redux
Input Method Panel
```

### toupad

三指拖放：https://github.com/ferstar/gestures.git

```bash
#https://blog.ferstar.org/posts/linux-touchpad-gestures-drag/
#https://github.com/ferstar/blog/issues/73
wget https://github.com/ferstar/gestures/releases/download/v0.8.2/gestures-linux-x86_64.tar.gz
tar zxvf gestures-linux-x86_64.tar.gz
sudo cp -a gestures-linux-x86_64/gestures /usr/local/bin/

sudo pacman -S libinput xdotool
yay -S ydotool

#Start ydotool Service
systemctl --user enable --now ydotool

# 1. Generate config file (first time only)
gestures generate-config

✓ Configuration file created at: /home/dave/.config/gestures.kdl

Edit the file to customize your gestures:
  vim /home/dave/.config/gestures.kdl

After editing, reload the config:
  gestures reload

View full documentation:
  https://github.com/ferstar/gestures/blob/dev/config.md

# 2. Install service file
gestures install-service

# 3. Enable and start the service
systemctl --user enable --now gestures.service

#禁止休眠
# 一次性禁止所有休眠相关目标（sleep/suspend/hibernate/hybrid-sleep）
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
想恢复时用：
sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

## ssh

```bash
sudo pacman -S openssh
sudo sed -i 's;#PermitRootLogin.*;PermitRootLogin yes;g' /etc/ssh/sshd_config
sudo systemctl enable sshd
sudo systemctl start sshd

```


## Securecrt

```bash
#https://www.cnblogs.com/amsilence/p/19151338
#https://github.com/amsilence/Linux-tools
yay --editmenu --editor=nano -S scrt
#把里面的source地址改为：https://eli.xir.no/VanDyke/scrt-9.6.4-3695.ubuntu24-64.x86_64.deb
git clone https://github.com/amsilence/Linux-tools.git
cd Linux-tools
#rm -fr /tmp/.securecrt.tmp/
./securecrt_linux_crack.pl /usr/bin/SecureCRT
#注册
Name: ygeR
Company: TEAM ZWT
Serial Number: 03-38-361120
Issue Date: 10-19-2025
License Key: ACVG1Z 96MXM2 UP86HH UDGR4C ABKBJK 2NW3BH ZC23H5 GEWB7W
```

## Remote Desktop

```bash
#向日葵
https://comate.baidu.com/zh/page/lbqpmkldtwh

#rustdesk
https://rustdesk.com/zh-cn/
https://github.com/rustdesk/rustdesk

```

## NVM

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
. ~/.bashrc
#显示有远端的版本
#nvm ls-remote
#安装对应的版本
nvm install 12
nvm install 22
nvm alias default 22
```

## Python Venv

```bash
#python -m venv /works/python_venv
#. /works/python_venv/bin/activate
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
#Python3.12
conda create --name py312 python=3.12
conda activate py312

```

## waydroid

https://geek-blogs.com/blog/best-android-emulator-for-linux/

```bash
pip install dbus-python gbinder PyGObject
yay -S waydroid
sudo waydroid init -s GAPPS
sudo systemctl start waydroid-container
# 启动 Waydroid 图形界面
waydroid show-full-ui

#完全停止
waydroid session stop
sudo systemctl stop waydroid-container
```

Fix: This device isn’t Play Protect certified

```bash
#获取 Waydroid 的 Android ID（GSF ID）
sudo waydroid shell -- sh -c "sqlite3 /data/data/com.google.android.gsf/databases/gservices.db 'select value from main where name = \"android_id\";'"
#输出是一串长数字（比如 1234567890123456789），这就是你的 android_id。

```

在浏览器注册设备

```
打开任何浏览器（Manjaro 的 Firefox/Chrome 都行），访问：
https://www.google.com/android/uncertified
用你要登录 Play Store 的 同一个 Google 账号 登录。
输入刚才复制的 android_id（只复制数字，不要带 android_id|）。
完成 reCAPTCHA（可能要点图片验证）。
点击 Register。
页面会显示 “Device registered” 或类似（如果卡住不动，别慌，注册已成功）。

等待 + 清理缓存（关键步骤，很多坑在这里）
注册后 不要马上登录 Play Store，等 5-30 分钟（有时需几小时，Google 服务器同步慢）。
在 Waydroid 里：
去 设置 > 应用 > 查看所有应用 > Google Play Store → 强制停止 + 清除缓存 + 清除数据。
同上，对 Google Play Services 也清除缓存（别清数据，除非必要）。
```

重启 Waydroid：
```bash
waydroid session stop
sudo systemctl restart waydroid-container
waydroid show-full-ui
```

安装apk

```bash
waydroid session start
waydroid app install /path/to/your.apk
```

## Samba

```bash
sudo pacman -Syu samba smbclient

#共享 /works/share 文件夹
sudo vim /etc/samba/smb.conf
[share]
   comment = share
   path = /works/share
   browseable = yes
   writable = yes
   create mask = 0700
   directory mask = 0700
   valid users = dave

#创建共享目录并设置权限
mkdir -p /works/share
chmod 777 /works/share

#添加 Samba 用户
sudo smbpasswd -a $USER
# 启用该用户
sudo smbpasswd -e $USER

#禁用AppArmor
sudo aa-complain /usr/sbin/smbd

#启动并设置为开机自启
sudo systemctl enable --now smb

#检查状态
sudo systemctl status smb
# 检查配置文件是否有语法错误
testparm

#连接测试
smbclient //192.168.3.10/share -U dave
```

## aria2

```bash
yay -Syu aria2

mkdir -p /works/aria2 /works/aria2/Downloads
vim /works/aria2/aria2.conf
# 基本设置
dir=/works/aria2/Downloads
file-allocation=falloc
continue=true
allow-overwrite=true

# 速度与连接优化（根据你带宽调整）
max-concurrent-downloads=10
max-connection-per-server=16
min-split-size=1M
split=16

# RPC 设置（给 AriaNg、Motrix、手机App等前端用，必开）
enable-rpc=true
rpc-listen-all=true
rpc-listen-port=6800
rpc-secret=Aa123456
rpc-allow-origin-all=true

# BT相关（可选）
enable-dht=true
enable-peer-exchange=true
bt-enable-lpd=true
bt-max-peers=0
seed-ratio=0.0

# 其他优化
disk-cache=64M
http-accept-gzip=true
user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36

#测试启动
aria2c --conf-path=/works/aria2/aria2.conf

#做成 systemd 用户服务
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/aria2.service
[Unit]
Description=aria2 download utility
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/aria2c --conf-path=/works/aria2/aria2.conf --log=/works/aria2/aria2.log
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target

systemctl --user daemon-reload
systemctl --user enable --now aria2.service
systemctl --user status aria2

#aria2-explorer 
https://chromewebstore.google.com/detail/aria2-explorer/mpkodccbngfoacfalldjimigbofkhgjn?pli=1
系统设置->常规设置：配置对应的RPC即可
```