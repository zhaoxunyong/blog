
## 安装：
```bash
npm install -g cnpm --registry=https://registry.npm.taobao.org
npm config set registry https://registry.npm.taobao.org

npm install -g fis3
cnpm i -g fis-parser-node-sass

mkdir demo
cd demo
fis3 init jello-demo
fis3 release
fis3 server start

#fis3 release prod -d /app
```
