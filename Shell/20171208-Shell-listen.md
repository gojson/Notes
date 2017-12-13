---
layout: post
title: 'linux shell命令监控'
subtitle: 'shell 监控mysql,mem'
date: 2017-12-07
categories: php
cover: 'http://on2171g4d.bkt.clouddn.com/jekyll-theme-h2o-postcover.jpg'
tags: php
---

## [Copy来源](http://www.ptbird.cn/server-monitor-shell-mail-warning.html)

例如：监控apache状态、监控mysql的状态、监控内存使用以及硬盘的使用。

一、监控apache

为了更好地实现该功能，使用的命令是nc -w

主要命令如下：

nc - w 3 localhost 80 &>/dev/null

-w 3 表示与localhost 80 端口通信3秒，如果成功通信证明apache当前状态正常。

通过if条件判断，并发送邮件给 admin@ptbird.cn（之前添加的用户admin在windows下的客户端中接收邮件）

 

nc -w 3 localhost 80 &>/dev/null

if [[ $? -eq 0 ]]; then
	str="apache server status OK!"
else
	str="apache server status ERROR!"
fi

echo $str | mail -s 'apache web server' admin@ptbird.com.cn
#向admin@ptbird.com.cn发送邮件，主题为 apache web server
 

二、监控mysql

mysql不允许外IP连接，因此需要监控localhost 3306

其他的和apache一样

主要命令如下：

nc - w 3 localhost 3306&>/dev/null

-w 3 表示与localhost 3306 端口通信3秒，如果成功通信证明mysql当前状态正常。

通过if条件判断，并发送邮件给 admin@ptbird.cn（之前添加的用户admin在windows下的客户端中接收邮件）

 

nc -w 3 localhost 3306 &>/dev/null

if [[ $? -eq 0 ]]; then
	str="mysql server status OK!"
else
	str="mysql server status ERROR!"
fi

echo $str | mail -s 'mysql server' admin@ptbird.com.cn
 

三、监控disk用量

disk的用量我用了df -Th

主要命令如下：

df -Th | sed -n '3p' |awk '{print int($5)}'

sed -n '3p' 取第三行

awk '{print int($5)}'   输出第五列 因为第五列是百分比，去掉百分号用来比较。

（我不太习惯用awk获取行）

通过if条件判断，并发送邮件给 admin@ptbird.cn（之前添加的用户admin在windows下的客户端中接收邮件）

ds=`df -Th | sed -n '3p' |awk '{print int($5)}'`

if [[ ds -lt 45 ]]; then
	str="disk space is less than 45%!"
else
	str="disk space is greater than 45%!"
fi

echo $str | mail -s 'linux server disk space' admin@ptbird.com.cn
 

三、监控memory用量

mem 用的是free -m

主要命令如下：

free -m | sed -n '2p'|awk '{print int($3*100/$2)}'

取第二行并且第三列/第二列的结果为百分比，但是因为结果其实是0.23... 所以*100再取整得到的是百分比的整数

通过if条件判断，并发送邮件给 admin@ptbird.cn（之前添加的用户admin在windows下的客户端中接收邮件）

per=`free -m | sed -n '2p'|awk '{print int($3*100/$2)}'`

if [[ per -lt 45 ]]; then
	str="mem space is less than 45%!Now mem space is used ${per}%"
else
	str="mem space is greater than 45%!Now mem space is used ${per}%"
fi

echo $str | mail -s 'linux server mem space' admin@ptbird.com.cn
四、crontab计划

将上面的脚本写在一个脚本中可以发送4封邮件，也可以发送一封，把字符串拼接就行了。

为了避免编码问题，全用的英文发送。

编辑crontab：

crontab -e 

10 14 * * * bash /mnt/monitor.sh
