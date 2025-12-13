#!/bin/sh

#nvm use v12.22.6
hexo clean
hexo g
sed -i 's;<url>//;<url>/;g' public/search.xml
hexo d
