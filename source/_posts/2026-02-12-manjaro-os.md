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
sudo pacman -S pacman-contrib vim xorg-mkfontscale

#yay
#https://wiki.archlinuxcn.org/wiki/Yay
sudo pacman -S yay
#将 Yay 升级到新版本
yay -Sua
#升级所有包（含 AUR）
pacman -Syu
yay -Syu 
#清理不需要的依赖 
yay -Yc 

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
yay -S fcitx5-sogou

#雾凇拼音
#https://obsp.de/zh/posts/2025-02-18-arch_linuxgnome%E5%AE%89%E8%A3%85fcitx_5%E8%BE%93%E5%85%A5%E6%B3%95-%E4%B8%AD%E5%B7%9E%E9%9F%B5rime-%E9%9B%BE%E5%87%87%E6%8B%BC%E9%9F%B3/
yay -S fcitx5 fcitx5-rime fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-config-qt
yay -S rime-ice-git
mkdir -p ~/.local/share/fcitx5/rime/
vim ~/.local/share/fcitx5/rime/default.custom.yaml
patch:
  # 仅使用「雾凇拼音」的默认配置，配置此行即可
  __include: rime_ice_suggestion:/
  # 以下根据自己所需自行定义，仅做参考。
  # 针对对应处方的定制条目，请使用 <recipe>.custom.yaml 中配置，例如 rime_ice.custom.yaml
  __patch:
    key_binder/bindings/+:
      # 开启逗号句号翻页
      - { when: paging, accept: comma, send: Page_Up }
      - { when: has_menu, accept: period, send: Page_Down }
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

```bash


命令 	        描述
yay 	        升级系统，相当于yay -Syu
yay             <搜索词> 	显示包安装选择菜单
yay -Bi         <目录> 	安装依赖并构建本地PKGBUILD
yay -G          <AUR Package> 	从ABS或AUR下载PKGBUILD (yay v12.0+)
yay -Gp         <AUR Package> 	打印ABS或AUR的PKGBUILD到stdout
yay -Ps         打印系统统计信息
yay -Yc         清理不需要的依赖
yay -S   包名 	安装软件包
yay -Syu        升级所有包（含 AUR）
yay -Sc         清理缓存文件
yay -Yc         删除无用依赖
yay -Rns 包名 	删除软件包和依赖及配置
yay -Rs  包名 	删除软件包和依赖
yay -R   包名 	删除软件包 

yay -Syu --devel 	        执行系统升级，但同时检查开发包的更新
yay -Syu --timeupdate 	    执行系统升级并使用PKGBUILD修改时间（不是版本号）来确定更新
yay -Wu     <AUR Package> 	取消对包的投票 (需要设置AUR_USERNAME和AUR_PASSWORD环境变量) (yay v11.3+)
yay -Wv <AUR Package> 	    投票支持包 (需要设置AUR_USERNAME和AUR_PASSWORD环境变量) (yay v11.3+)
yay -Y --combinedupgrade --save 	使组合升级成为默认模式
yay -Y --gendb 	            生成用于开发更新的开发包数据库
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