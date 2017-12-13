#调用类的对象时自动调用此方法
__str__

#创建数据表:

### 1.文件:polls/models.py

```python
from django.db import models
class Question(models.Model):
    question_text = models.CharField(max_length=200)
    pub_date = models.DateTimeField('date published')

class Choice(models.Model):
    question = models.ForeignKey(Question)
    choice_text = models.CharField(max_length=200)
    votes = models.IntegerField(default=0)
```

### 2.激活model
###通过运行makemigrations告诉Django，已经对模型做了一些更改（在这个例子中，你创建了一个新的模型）并且会将这些更改记录为迁移文件

```python
mysite/settings.py
INSTALLED_APPS = (
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'polls',
)
```

### 3. 执行命令
python manage.py makemigrations polls

### 4.查看生成哪些sql
sqlmigrate命令接收迁移文件的名字并返回它们的SQL语句
python manage.py sqlmigrate polls 0001

### 5. 此步骤可省略：检查model是否存在
python manage.py check；它会检查你的项目中的模型是否存在问题，而不用执行迁移或者接触数据库


### 6. 创建数据表
python manage.py migrate


### 7.总结
请记住实现模型变更的三个步骤：

修改你的模型（在models.py文件中）。
运行python manage.py makemigrations ，为这些修改创建迁移文件
运行python manage.py migrate ，将这些改变更新到数据库中。

