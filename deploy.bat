@echo off
start hexo g
ping -n 15 127.1>nul
start hexo d
git add .
git commit -m "add blog"
git push
TASKKILL /F /IM cmd.exe
pause