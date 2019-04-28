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
nvm install v10.15.3
```

## 安装hexo

### 安装

```bash
#http://stevenshi.me/2017/05/23/ubuntu-hexo/
npm install  hexo-cli -g
npm install hexo-server -g
npm install hexo-deployer-git -g
npm install yarn -g
npm install http-server -g
yarn global add serve

npm config set registry https://registry.npm.taobao.org --global
npm config set disturl https://npm.taobao.org/dist --global
yarn config set registry https://registry.npm.taobao.org --global
yarn config set disturl https://npm.taobao.org/dist --global
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
git config http.postBuffer 524288000
```

### blog配置

####  新项目时创建

```bash
# 初始化
hexo init 
yarn install
# Google 
yarn add hexo-generator-sitemap
# Baidu
yarn add hexo-generator-baidu-sitemap
```

#### 已有的项目

```bash
# 安装依赖项
yarn install
# Google 
#yarn add hexo-generator-sitemap
# Baidu
#yarn add hexo-generator-baidu-sitemap
#npm rebuild node-sass --force
#npm uninstall node-sass
#npm install node-sass
# ENOSPC错误解决
#http://hexo.io/docs/troubleshooting.html
#echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
#RPC failed; curl 55 SSL_write() returned SYSCALL, errno = 32
```

#提交sitemap前注意：部分页面不想被收录的需要在front-matter前加sitemap: false与baidusitemap: false，比如404页面，比如站点确认文件等等。
#此外我在config中设置网址为//开头，即没有指明协议，这样生成的sitemap中网址也是//开头，结果不能被google识别，所以需要写上协议才行。

运行：
```bash
hexo s
```

