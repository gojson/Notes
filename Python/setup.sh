brew install python3
ln /usr/local/bin/python3 /usr/local/bin/python

p3 list
pip3 install redis
pip3 install xlrd
pip3 install virtualenv
pip3 install mysqlclient
pip3 install Django
#创建一个项目
#django-admin startproject mysite
#python manage.py migrate  #migrate查看INSTALLED_APPS设置并根据mysite/settings.py文件中的数据库设置创建任何必要的数据库表
