---
title: 记一次在CentOS 7上部署Java测试环境的过程
date: 2017-06-29 13:45:35
tags: ["Java","Linux","CentOS","MySQL"]
categories: ["2017-06"]
---
将之前配置LNMJ测试环境的过程归个档，方便日后查阅。

#### 1） JDK环境
##### 下载并安装
```shell
cd usr
mkdir java
```
当时不小心下到了JDKDemo的包，直接下JDK包时发现下载下来的是网页，于是只好手动下载再上传。
![](http://upload-images.jianshu.io/upload_images/6184025-f4b899a078bdb590.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
```shell
cd java
rpm -ivh jdk-8u131-linux-x64.rpm
```
##### 配置环境
```shell
vi /etc/profile
```
按I进入编辑模式，将如下内容加入profile中：
```
export JAVA_HOME=/usr/java/jdk1.8.0_131
export CLASSPATH=.:$JAVA_HOME/jre/lib/rt.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
```
输入
```shell
source /etc/profile
```
命令，让配置生效。
最后和Windows平台一样，输入java -version来验证安装。


#### 2）Tomcat的配置
##### 下载并安装
wget下载安装包，并且解压。
```shell
tar -zxvf apache-tomcat-x.x.xx.tar.gz
```
修改文件夹名字方便后续使用。
##### 配置环境变量
编辑/etc/profile，在末尾加上：
```
export CATALINA_HOME=/usr/apache-tomcat
export CATALINA_BASE=/usr/apache-tomcat
export PATH=$PATH:$JAVA_HOME/bin:$CATALINA_HOME/bin
```
刷新并运行Tomcat进行测试：
```shell
source /etc/profile
/usr/apache-tomcat/bin/startup.sh
```
##### 将Tomcat配置为系统服务，方便用systemctrl管理：
  + 在Tomcat的bin目录下，新建setenv.sh脚本。Tomcat启动时会自动运行这个脚本。
  ```shell
  CATALINA_PID="$CATALINA_BASE/tomcat.pid"
  ```
  + 使用vi编辑/usr/lib/systemd/system/tomcat.service文件
  ````
  [Unit]
  Description=Tomcat
  After=syslog.target network.target remote-fs.target nss-lookup.target
  [Service]
  Type=forking
  PIDFile=/usr/apache-tomcat/tomcat.pid
  ExecStart=/usr/apache-tomcat/bin/startup.sh
  ExecReload=/bin/kill -s HUP $MAINPID
  ExecStop=/bin/kill -s QUIT $MAINPID
  PrivateTmp=true
  [Install]
  WantedBy=multi-user.target
  ````
  
然后就可以用systemctrl命令来管理Tomcat的开机启动等问题了。

当时出了一个很奇怪的bug，我本地运行没有问题的war包，上传到服务器上就是404，在Tomcat管理页面里也能看到这个WebAPP在运行。
最后我直接删掉了服务器Tomcat，将本地Tomcat直接上传上去，并把权限改为0777，最终解决问题。


#### 3）MySQL
MySQL这事比较复杂，Oracle收购了MySQL之后，准备在MySQL6.x收费，然后社区开发了一个叫MariaDB的分支，采用GPL授权，以此应对。
当然我还是不准备采用这个分支，能求稳就别浪……
##### 下载并安装
```shell
wget http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
rpm -ivh mysql-community-release-el7-5.noarch.rpm
yum install mysql-community-server
```
##### 启动
运行mysql -u root启动。
（值得注意的是，只有root账户没有密码的时候才能这么启动，否则返回Access denied，不会提示你输入密码。在有密码的时候需要加上-p参数。）
进入mysql命令行之后，运行SQL语句设置密码：
```SQL
set password for 'root'@'localhost' =password('密码');
```
当时配置完成后死活连不上，最后发现CentOS不是用IPTABLE作为防火墙，而是使用了firewall。
更换为IPTABLE，并且开放端口后问题解决。

##### 一些配置：
  + 更改编码：
    ```shell
    vi /etc/my.cnf
    ```
    在文件末尾添加：
    ```
    [mysql]
    default-character-set =utf8
    ```
  + 设置其他IP可以连接：
    在MySQL命令行中执行：
    ```SQL
    grant all privileges on *.* to root@'%'identified by '你的密码';
    ```

#### 4）nginx
nginx的安装给我一种印象，下载的似乎是源代码，还要下一个gcc的编译器，现场编译现场用。
（不知道是不是真的，如有谬误请指正）
##### 安装依赖
```shell
yum install gcc-c++  
yum install pcre pcre-devel  
yum install zlib zlib-devel  
yum install openssl openssl--devel  
```
##### 安装nginx本体
```shell
wget http://nginx.org/download/nginx-1.7.12.tar.gz
tar -zxvf nginx-1.7.12.tar.gz
```
并重命名目录，去掉版本号，方便后续使用。
当时安装完后，因为firewall的问题（我看错，认为80端口是打开的）以为配置出了错，最后一怒之下关了防火墙一切正常了。
决定换回熟悉的iptable。
#####配置nginx代理Tomcat
编辑nginx.conf文件，在http-server-location-proxy_pass段中填入：
```
http://127.0.0.1:8080
#此处8080为Tomcat默认端口号
```
##### 将nginx配置为服务
  + 先编辑nginx.conf文件：
  ```shell
  vi /usr/local/ngnix/conf/nginx.conf
  ```
  将里面的pid段后面的路径复制出来。
  + 使用vi编辑/usr/lib/systemd/system/nginx.service
  ````
  [Unit]
  Description=nginx - high performance web server
  Documentation=http://nginx.org/en/docs/
  After=network.target remote-fs.target nss-lookup.target
  [Service]
  Type=forking
  #与nginx.conf一致
  PIDFile=/usr/local/nginx/logs/nginx.pid
  #启动前检测配置文件 是否正确
  ExecStartPre=/usr/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf
  #启动
  ExecStart=/usr/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
  #重启
  ExecReload=/bin/kill -s HUP $MAINPID
  #关闭
  ExecStop=/bin/kill -s QUIT $MAINPID
  PrivateTmp=true
  [Install]
  WantedBy=multi-user.target
  ````
  
 至此，JDK Tomcat Nginx MySQL全部配置完成。
 可以将war包上传到Tomcat的webapp目录下，Tomcat会自动部署。