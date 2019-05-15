@echo off
start hexo g
start hexo d
git add .
git commit -m "add blog"
git push
pause