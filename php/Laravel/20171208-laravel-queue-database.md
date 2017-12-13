---
layout: post
title: 'Laravel配置redis队列-Database'
subtitle: 'redis-queue-Database'
date: 2017-12-07
categories: php
cover: 'http://on2171g4d.bkt.clouddn.com/jekyll-theme-h2o-postcover.jpg'
tags: php
---

## 1.0 情景描述:
使用Laravel5.4框架,处理消息队列，redis队列的database方式

## 2.0 官网地址 
* [官网安装文档地址](https://laravel.com/docs/5.4/queues)
* **安装步骤:**
  1. php artisan queue:table ,php artisan migrate      //创建job table,用来记录任务,
  2. database.php ,

  ```php
'redis' => [
    'driver' => 'redis',
    'connection' => 'default',
    'queue' => '{default}',
    'retry_after' => 90,
],
  ```
  3. app.php

```php
'default' => env('QUEUE_DRIVER', 'database'),
```
  4. 监听任务()

```php
php artisan queue:work --queue=high,default
```
  5. 创建任务处理类

```php
php artisan make:job SendEmail
```
  6. 生产任务

```php
<?php
namespace App\Http\Controllers;

use App\Jobs\ProcessPodcast;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class PodcastController extends Controller
{
    /**
     * Store a new podcast.
     *
     * @param  Request  $request
     * @return Response
     */
    public function store(Request $request)
    {
        //dispatch(new SendEmail($arr));
	dispatch((new Job)->onQueue('high'));
    }
}
```
   6 任务类

```php
<?php

namespace App\Jobs;

use App\Podcast;
use App\AudioProcessor;
use Illuminate\Bus\Queueable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;

class SendEmail implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $podcast;

    /**
     * Create a new job instance.
     *
     * @param  Podcast  $podcast
     * @return void
     */
    public function __construct(Podcast $podcast)
    {
        $this->podcast = $podcast;
    }

    /**
     * Execute the job.
     *
     * @param  AudioProcessor  $processor
     * @return void
     */
    public function handle(AudioProcessor $processor)
    {
     	//处理任务逻辑
    }
}
```
   7. 重启任务

```php
php artisan queue:restart
```
