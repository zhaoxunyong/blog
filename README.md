## 安装NVM

```bash
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
```

## 安装nodejs

### 安装
```bash
nvm install v8.9.4
```

### 配置
编辑： ~/.bashrc，加入：
```bash
alias cnpm="npm --registry=https://registry.npm.taobao.org"
```

## 安装hexo

### 安装

```bash
#http://stevenshi.me/2017/05/23/ubuntu-hexo/
npm install  hexo-cli -g
npm install hexo-server -g
npm install hexo-deployer-git -g
# Google 
npm install hexo-generator-sitemap
# Baidu
npm install hexo-generator-baidu-sitemap
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

### blog配置

####  新项目时创建
```
# 初始化
hexo init 
```bash
npm install
```

#### 已有的项目

```bash
# 安装依赖项
npm install
#npm rebuild node-sass --force
npm uninstall node-sass
npm install node-sass
# ENOSPC错误解决
#http://hexo.io/docs/troubleshooting.html
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
```

#### Sitemap

在config最后新增

```xml
sitemap:
  path: sitemap.xml
  
baidusitemap:
  path: baidusitemap.xml
```

提交sitemap前注意：部分页面不想被收录的需要在front-matter前加sitemap: false与baidusitemap: false，比如404页面，比如站点确认文件等等。
此外我在config中设置网址为//开头，即没有指明协议，这样生成的sitemap中网址也是//开头，结果不能被google识别，所以需要写上协议才行。

运行：
```bash
hexo s
```

## 安装remarkable
linux 下有很多好用的 markdown 博客撰写工具，诸如Atom、Haroopad、Mark My Words、remarkable 等等。
其中 remarkable 最为流行。 remarkable 是linux下一款免费的 markdown 编辑器。

```bash
# 安装一些依赖
sudo apt-get install   python3-markdown   python3-bs4  wkhtmltopdf

# 安装
wget http://remarkableapp.github.io/files/remarkable_1.87_all.deb
sudo apt-get install -f

# 运行
remarkable
```

