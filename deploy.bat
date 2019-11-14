@echo off
cd /d d:\blog
call hexo g
start hexo d
git add .
git commit -m "add blog"
git push
TASKKILL /F /IM cmd.exe
pause