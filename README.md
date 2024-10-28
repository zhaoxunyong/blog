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
nvm install v12.22.6

#Only for windows
# proxy_on
# choco install python
```

## 安装hexo

### 安装

```bash
#http://stevenshi.me/2017/05/23/ubuntu-hexo/
npm config set registry https://registry.npmmirror.com --global
npm config set disturl https://npmmirror.com/dist --global
npm install  hexo-cli -g
npm install hexo-server -g
npm install hexo-deployer-git -g
npm install yarn -g
npm install http-server -g
#yarn global add serve

yarn config set registry https://registry.npmmirror.com --global
yarn config set disturl https://npmmirror.com/dist --global
```

### 安装git
```bash
sudo apt-get install git
git config --global user.name "dave.zhao"
git config --global user.email dave.zhao@zerofinance.com
git config --global core.autocrlf false
git config --global core.safecrlf warn
git config --global core.filemode false
git config --global core.whitespace cr-at-eol
git config --global credential.helper store
#git config http.postBuffer 524288000
```

### blog配置

####  新项目时创建

```bash
# 初始化
hexo init 
npm install
# Google 
npm instll hexo-generator-sitemap
# Baidu
npm instll hexo-generator-baidu-sitemap
```

#### 已有的项目

```bash
# 安装依赖项
# 不要在vscode中的terminal中执行，可能会找不到python路径
npm install

#npm rebuild node-sass --force
#npm uninstall node-sass
#npm install node-sass

# Google 
#npm install hexo-generator-sitemap
# Baidu
#npm install hexo-generator-baidu-sitemap

# ENOSPC错误解决
#http://hexo.io/docs/troubleshooting.html
#echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
#RPC failed; curl 55 SSL_write() returned SYSCALL, errno = 32
```

运行：

```bash
hexo s
```

创建新的文章：

```bash
hexo n "文件的名称"
```


npm_release:vi5TKBakvgZTdCXJ
npm_view:    1uCWUSqbfGjMYgE3


npm config set registry http://nexus.zerofinance.net/content/groups/publicnpm/

~/.npmrc
registry=http://nexus.zerofinance.net/content/groups/publicnpm/
always-auth=true
email=dave.zhao@zerofinance.com
_auth="bnBtX3JlbGVhc2U6dmk1VEtCYWt2Z1pUZENYSg=="


A request has been made to list all accounts. 
You can select which accounts the caller can see
  [x] 0x4FbCCAb5BCD9a85264964f362129acE0BB686314
    URL: keystore:///data/eth/geth-tutorial/keystore/UTC--2022-05-06T09-45-52.235883825Z--4fbccab5bcd9a85264964f362129ace0bb686314


    0x4fbccab5bcd9a85264964f362129ace0bb686314



mkdir geth-tutorial/keystore
clef newaccount --keystore geth-tutorial/keystore
clef --keystore geth-tutorial/keystore --configdir geth-tutorial/clef --chainid 5
geth --datadir geth-tutorial --signer=geth-tutorial/clef/clef.ipc --ropsten --syncmode snap --http
geth attach http://127.0.0.1:8545

560