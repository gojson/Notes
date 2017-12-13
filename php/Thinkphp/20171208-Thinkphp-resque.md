---
layout: post
title: 'Thinkphp3.2 配置消息队列php-Resque'
subtitle: 'php-Resque消息队列'
date: 2017-12-07
categories: php
cover: 'http://on2171g4d.bkt.clouddn.com/jekyll-theme-h2o-postcover.jpg'
tags: php
---

## 1.0 情景描述:
使用ThinkPhp3.2 + php-Resque 实现消息队列,
php-resque是php环境中一个轻量级的队列服务。具体队列服务是做什么用的，请自行百度！
将源码更新到 ThinkPHP/Library/Vendor/php-resque/ 目录中

## [git地址](https://github.com/5ini99/tp3-resque)

## 2.0 使用方法
* **创建队列入口文件resque**

```php
#!/usr/bin/env php
<?php
ini_set('display_errors', true);
error_reporting(E_ERROR);
// 定义应用目录
define('APP_PATH','./Application/');
define('MODE_NAME', 'cli'); // 自定义cli模式
define('BIND_MODULE', 'Home');  // 绑定到Home模块
define('BIND_CONTROLLER', 'Queue'); // 绑定到Queue控制器
define('BIND_ACTION', 'index'); // 绑定到index方法
// 处理自定义参数
$act = $argv[1] ?? 'start';
putenv("Q_ACTION={$act}");
putenv("Q_ARGV=" . json_encode($argv));
require './ThinkPHP/ThinkPHP.php';
```

* **config.php 配置队列**

```php
/* 消息队列配置 */
'QUEUE' => array(
    'type' => 'redis',
    'host' => '127.0.0.1',
    'port' =>  '6379',
    'prefix' => 'queue',
    'auth' =>  '',
),

```

* **cli 命令**

```php
php resque start
php resque start --queue=default --pid=/tmp/resque.pid --debug=1
php resque start --queue=default --pid=/tmp/resque.pid --debug=1 &
--queue - 需要执行的队列的名字，可以为空，也可以多个以,分割
--interval -在队列中循环的间隔时间，即完成一个任务后的等待时间，默认是5秒
--count - 需要创建的Worker的数量。所有的Worker都具有相同的属性。默认是创建1个Worker
--debug - 设置“1”启用更啰嗦模式，会输出详细的调试信息
--pid - 手动指定PID文件的位置，适用于单Worker运行方式

```

* **创建控制器**

```php
<?php
/**************************************************
 *    Filename:      QueueController.class.php
 *    Copyright:     (C) 2017 All rights reserved
 *    Author:        Theast
 *    Description:   ---
 *    Create:        2017-01-08 21:47:52
 *    Last Modified:  2017-02-09 20:35:36
 *************************************************/ 
namespace Job\Controller;

use Think\Controller;
use Exception;
use Resque;

if (!IS_CLI)  die('The file can only be run in cli mode!');
/***
 * queue入口
 * Class Worker
 * @package Job\Controller
 */
class QueueController extends Controller{
    protected $vendor;
    protected $args = [];
    protected $keys = [];
    protected $queues = '*';

    public function __construct() {
        parent::__construct(); 

        vendor('Resque.autoload');
        $argv = json_decode(getenv('Q_ARGV'));
        foreach ($argv as $item) {
            if (strpos($item, '=')) {
                list($key, $val) = explode('=', $item);
            } else {
                $key = $val = $item;
            }
            $this->keys[] = $key;
            $this->args[$key] = $val;
        }
    
        $this->init();
    }

    /**
     * 启动队列服务,配置队列服务信息
     * */
    public function run() {
        // 处理队列配置
        $config = C('QUEUE');
        if ($config) {
            // 初始化队列服务,使用database(1)
            \Resque::setBackend(['redis' => $config], 1);
            // 初始化缓存前缀
            if(isset($config['prefix']) && !empty($config['prefix']))
                \Resque\Redis::prefix($config['prefix']);
        }
    }

    /**
     * 执行队列
     * 环境变量参数值：
     * --queue|QUEUE: 需要执行的队列的名字
     * --interval|INTERVAL：在队列中循环的间隔时间，即完成一个任务后的等待时间，默认是5秒
     * --app|APP_INCLUDE：需要自动载入PHP文件路径，Worker需要知道你的Job的位置并载入Job
     * --count|COUNT：需要创建的Worker的数量。所有的Worker都具有相同的属性。默认是创建1个Worker
     * --debug|VVERBOSE：设置“1”启用更啰嗦模式，会输出详细的调试信息
     * --pid|PIDFILE：手动指定PID文件的位置，适用于单Worker运行方式
     */
    private function init() {
        $is_sington = false; //是否单例运行，单例运行会在tmp目录下建立一个唯一的PID

        // 根据参数设置QUEUE环境变量
        $QUEUE = in_array('--queue', $this->keys) ? $this->args['--queue'] : '*';
        if (empty($QUEUE)) {
            die("Set QUEUE env var containing the list of queues to work.\n");
        }
        $this->queues = explode(',', $QUEUE);

        // 根据参数设置INTERVAL环境变量
        $interval = in_array('--interval', $this->keys) ? $this->args['--interval'] : 5;
        putenv("INTERVAL={$interval}");

        // 根据参数设置COUNT环境变量
        $count = in_array('--count', $this->keys) ? $this->args['--count'] : 1;
        putenv("COUNT={$count}");

        // 根据参数设置APP_INCLUDE环境变量
        $app = in_array('--app', $this->keys) ? $this->args['--app'] : '';
        putenv("APP_INCLUDE={$app}");

        // 根据参数设置PIDFILE环境变量
        $pid = in_array('--pid', $this->keys) ? $this->args['--pid'] : '';
        putenv("PIDFILE={$pid}");

        // 根据参数设置VVERBOSE环境变量
        $debug = in_array('--debug', $this->keys) ? $this->args['--debug'] : '';
        putenv("VVERBOSE={$debug}");
    }

    public function index() {
        $act = getenv('Q_ACTION');
        switch ($act) {
        case 'stop':
            $this->stop();
            break;
        case 'status':
            $this->status();
            break;
        default:
            $this->start();
        }
    }

    /**
     * 开始队列
     */
    public function start() {
        // 载入任务类
        $path = APP_PATH . 'Job';
        $flag = \FilesystemIterator::KEY_AS_FILENAME;
        $glob = new \FilesystemIterator($path, $flag);
        foreach ($glob as $file) {
            if('php' === pathinfo($file, PATHINFO_EXTENSION))
                require realpath($file);
        }

        $logLevel = 0;
        $LOGGING = getenv('LOGGING');
        $VERBOSE = getenv('VERBOSE');
        $VVERBOSE = getenv('VVERBOSE');
        if (!empty($LOGGING) || !empty($VERBOSE)) {
            $logLevel = Resque\Worker::LOG_NORMAL;
        } else {
            if (!empty($VVERBOSE)) {
                $logLevel = Resque\Worker::LOG_VERBOSE;
            }
        }

        $APP_INCLUDE = getenv('APP_INCLUDE');
        if ($APP_INCLUDE) {
            if (!file_exists($APP_INCLUDE)) {
                die('APP_INCLUDE (' . $APP_INCLUDE . ") does not exist.\n");
            }
            require_once $APP_INCLUDE;
        }

        $interval = 5;
        $INTERVAL = getenv('INTERVAL');
        if (!empty($INTERVAL)) {
            $interval = $INTERVAL;
        }

        $count = 1;
        $COUNT = getenv('COUNT');
        if (!empty($COUNT) && $COUNT > 1) {
            $count = $COUNT;
        }

        if ($count > 1) {
            for ($i = 0; $i < $count; ++$i) {
                $pid = pcntl_fork();
                if ($pid == -1) {
                    die("Could not fork worker " . $i . "\n");
                } // Child, start the worker
                else {
                    if (!$pid) {
                        $worker = new Resque\Worker($this->queues);
                        $worker->logLevel = $logLevel;
                        fwrite(STDOUT, '*** Starting worker ' . $worker . "\n");
                        $worker->work($interval);
                        break;
                    }
                }
            }
        } // Start a single worker
        else {
            $worker = new Resque\Worker($this->queues);
            $worker->logLevel = $logLevel;

            $PIDFILE = getenv('PIDFILE');
            if ($PIDFILE) {
                file_put_contents($PIDFILE, getmypid()) or
                    die('Could not write PID information to ' . $PIDFILE);
            }

            fwrite(STDOUT, '*** Starting worker ' . $worker . "\n");
            $worker->work($interval);
        }
    }

    /**
     * 停止队列
     */
    public function stop() {
        $worker = new Resque\Worker($this->queues);
        $worker->shutdown();
    }

    /**
     * 查看某个任务状态
     */
    public function status() {
        $id = in_array('--id', $this->keys) ? $this->args['--id'] : '';
        $status = new \Resque\Job\Status($id);
        if (!$status->isTracking()) {
            die("Resque is not tracking the status of this job.\n");
        }

        echo "Tracking status of " . $id . ". Press [break] to stop.\n\n";
        while (true) {
            fwrite(STDOUT, "Status of " . $id . " is: " . $status->get() . "\n");
            sleep(1);
        }
    }
}

```

* **生产者-控制器:crontab 中添加任务,定时执行此方法**

```php
/**
     * crontab调此任务,或者 由server回调此任务
     * @return json
     * */
    public function crontab(){
        if(IS_ClI || IS_POST){
            // 记录日志
            $json = json_encode($_POST);
            $log = date('Y-m-d H:i:s') . "\t{$res}\t{$json}";
            log_record(self::DDB_CALL_BACK_LOG_UNION, $log);

            // 0. 获取基本数据
            $dspType     = $_POST['dspType'] ? : 'yoyi';              # DSP类型
            $report      = $_POST['report'];                          # 注意 report 中 cus 为 count(distinct imei)
            // 0.1 其他参数
            $date        = $_POST['params']['date'];                  # 计算日期
            $logStart    = $_POST['params']['log_start'];             # 日志开始日期，一般为 date-180
            $logEnd      = $_POST['params']['log_end'];               # 日志结束日期，一般为 date
            $streamStart = $_POST['params']['stream_start'];          # 客流开始日期
            $streamEnd   = $_POST['params']['stream_end'];            # 客流结束日期
            // TODO 来自高空的代码
            
            $file = $_POST['log_file_url'];
            $args = [
                'action'  => 'union-finish',
                'report'  => $report,
                'params'  => $_POST['params'],
                'dspType' => $dspType,
                'file'    => $file,
            ];
            $job = '\\Job\\Controller\\DaodianbaoJobController';
            $jobId = \Resque::enqueue('default', $job, $args, true);
            return $this->ajaxReturn(['status'=>0, 'msg'=>'ok', 'jog'=>$jobId]);
      }
  }
```

* **消费-控制器**

```php
public function perform() {
        $args = $this->args;
        $action = $args['action'];
        $rid  = $args['rid'];
        $adId = $args['adId'];
        $dateTime = $args['dateTime'];
 
        switch($action){
            case 'init':                                                                    # 初始化随机日志任务 [1.随机日志 2.导出随机日志IMEI]
                $mids = $args['mids'];
                $yoyiId = $args['yoyiId'];
                $from   = $args['from'];
                $to     = $args['to'];

                $_sendRes = $this->_exportMac($rid, $mids, $from, $to);
                # 任务类型顾客来源cusori,受众MAC allviewer,受众轨迹randviewer
                # 状态, 顾客来源(cusori):exmac->tobaidu->finish->download
                $update = ['status'=>'exmac','finish_at'=>$dateTime];
                M('Jbb_report_task')->where(['r_id'=>$rid, 'type'=>$this->_taskType])->setField($update);
              break;
            case 'tobaidu':                                                                 # 发送给旭远
                $project = $args['project'];
                $table   = $args['table'];
                $line    = $args['line'];
                $_sendRes = $this->_sendToBaidu($rid, $this->_taskType, $project, $table);
                
                # 将project 和 table 更新 # 状态, 受众分析(allviewer):exdid->exmac->tobaidu->finish->download
                $update = ['project'=>$project, 'table'=>$table,'status'=>'tobaidu', 'finish_at'=>$dateTime,'line'=>$line];
                M('Jbb_report_task')->where(['r_id'=>$rid, 'type'=>$this->_taskType])->setField($update);
     
              break;
            case 'finish':
                $bdUname = $args['username'];
                $bdPass  = $args['password'];
                $bdDate  = $args['date'];

                if($bdUname && $bdPass && $bdDate){
                    $bdPass  = authcode($bdPass, 'ENCODE', C('DMP_BAIDU_PASS_HASH_KEY'));
                    $update = ['bd_uname'=>$bdUname, 'bd_pass'=>$bdPass, 'bd_date'=>$bdDate,'finish_at'=>$dateTime,'status'=>'finish'];
                    M('Jbb_report_task')->where(['r_id'=>$rid, 'type'=>$this->_taskType])->setField($update);
                }
              break;
            case 'download':
                break;
        }
    }
```
