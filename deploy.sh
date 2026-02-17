#!/bin/zsh

. ~/.zshrc

nvm use 12
hexo clean
hexo g
sed -i 's;<url>//;<url>/;g' public/search.xml
hexo d
