#!/bin/sh
hexo clean
hexo g
sed -i 's;<url>//;<url>/;g' public/search.xml
hexo d
