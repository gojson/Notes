---
layout: post
title: 'gateWayWorker服务器回调'
subtitle: 'thinkphp3.2回调任务处理'
date: 2017-12-07
categories: php
cover: '/notes.jpg'
tags: php
---

## 1.0 情景描述:
客户端上传文件发起任务->等待远程服务器处理任务,任务处理完成->回调接口->通知客户端任务已经处理。

## 2.0 原文地址 
* [借鉴原文地址](http://www.ptbird.cn/gateway-worker-many-people-chat-online-group.html)

## 3.0 server:
* [服务端下载地址](https://github.com/walkor/GatewayWorker)

## 4.0 client:
* [gatewayworker手册官网地址](http://doc2.workerman.net/326102)
* [客户端下载地址](https://github.com/walkor/GatewayClient)

##  5.0 简介:
* gatewayClient
  gateClient是用来辅助 workerman或者是gateway进行用户分组以及向用户发送信息的组件，同时，能够快速便捷的将原有系统的uid和clientid绑定起来。
  gateway-worker(后面直接称gateway)是基于 workerman开发的TCP长连接框架，用于快速开发TCP长连接应用。
  在线聊天一般都是实用长连接保持通信，使用 workerman虽然能够做到同样的效果，但是gateway更加的方便快捷。

## 6.0 使用方法:
一、理论：
1. 与MVC系统整合的原则：
* 现有mvc框架项目与GatewayWorker独立部署互不干扰
* 所有的业务逻辑都由网站页面post/get到mvc框架中完成
* GatewayWorker不接受客户端发来的数据，即GatewayWorker不处理任何业务逻辑，GatewayWorker仅仅当做一个单向的推送通道
* 仅当mvc框架需要向浏览器主动推送数据时才在mvc框架中调用Gateway的API(GatewayClient)完成推送
2. 实现步骤:
* 网站页面建立与GatewayWorker的websocket连接
* GatewayWorker发现有页面发起连接时，将对应连接的client_id发给网站页面
* 网站页面收到client_id后触发一个ajax请求(假设是bind.php)将client_id发到mvc后端
* mvc后端bind.php收到client_id后利用GatewayClient调用Gateway::bindUid($client_id, $uid)将client_id与当前uid(用户id或者客户端唯一标识)绑定。如果有群组、群发功能，也可以利用Gateway::joinGroup($client_id, $group_id)将client_id加入到对应分组
* 页面发起的所有请求都直接post/get到mvc框架统一处理，包括发送消息
* mvc框架处理业务过程中需要向某个uid或者某个群组发送数据时，直接调用GatewayClient的接口Gateway::sendToUid Gateway::sendToGroup 等发送即可

二、server端配置:
* 下载地址: https://github.com/walkor/GatewayWorker
* Application/YourApp/Events.php

```php
class Events
{
    /**
     * 当客户端连接时触发
     * 如果业务不需此回调可以删除onConnect
     * 
     * @param int $client_id 连接id
     */
    public static function onConnect($client_id) {
        #绑定用户uid 和client_id
        $send_data = json_encode(array(
                        'client_id'  => $client_id,
                        'type'       =>'init',
                    ));
        Gateway::sendToClient($client_id,$send_data);
    }
    
   /**
    * 当客户端发来消息时触发
    * @param int $client_id 连接id
    * @param mixed $message 具体消息
    */
   public static function onMessage($client_id, $message) {
        // 向所有人发送 
        // Gateway::sendToAll("$client_id said $message");
   }
   
   /**
    * 当用户断开连接时触发
    * @param int $client_id 连接id
    */
   public static function onClose($client_id) {
       // 向所有人发送 
       GateWay::sendToAll("$client_id logout");
   }
}
```

* Application/YourApp/start_gateway.php

 ```php
use \Workerman\Worker;
use \Workerman\WebServer;
use \GatewayWorker\Gateway;
use \GatewayWorker\BusinessWorker;
use \Workerman\Autoloader;

// gateway 进程，这里使用Text协议，可以用telnet测试
$gateway = new Gateway("websocket://0.0.0.0:8284");
// gateway名称，status方便查看
$gateway->name = 'task';
// gateway进程数
$gateway->count = 4;
// 本机ip，分布式部署时使用内网ip
$gateway->lanIp = '127.0.0.1';
// 内部通讯起始端口，假如$gateway->count=4，起始端口为4000
// 则一般会使用4000 4001 4002 4003 4个端口作为内部通讯端口 
$gateway->startPort = 2900;
// 服务注册地址
$gateway->registerAddress = '127.0.0.1:1238';
 
```
* start.php 放在项目根目录

```php
//以debug（调试）方式启动
php start.php start

//以daemon（守护进程）方式启动
php start.php start -d

//停止
php start.php stop
//重启
php start.php restart

//平滑重启
php start.php reload

//查看状态
php start.php status

```
* 前端js

```js
<script>

$().ready(function(){
    var noticeDiv = $('#zm-task-finish-notice');
    var aside = $('#zm-task-finish-status');
    var ws = new WebSocket("ws://{:C('ZM_TASK_GATEWAY_URL')}"); //new WebSocket('ws://task.dev:8284');//new WebSocket('ws://127.0.0.1:8284');
    ws.onopen = function () { };
    ws.onmessage = function (evt) { 
        var res = eval("("+evt.data+")");
        var type = res.type;
        var ajaxUrl="{:('/Zmeng/Task/bind')}";
        switch(type){
            // Events.php中返回的init类型的消息，将client_id发给后台进行uid绑定
            case 'init':
                // 利用jquery发起ajax请求，将client_id发给后端进行uid绑定
                $.post(ajaxUrl, {client_id: res.client_id}, function(data){
                    // alert(data.status);
                }, 'json');
                break;
            // 当mvc框架调用GatewayClient发消息时直接alert出来
            default :
                if(res.status == 0){
                // for(var i=0;i<res.info.length;i++){
                $.each(res.info, function (i, item) {
                    // 提示信息
                    var taskId = res.info[i].id;
                    var successHtml = '<div class="alert alert-success alert-dismissible">'
                                      +'     <button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button>'
                                      +'     <h4><i class="icon fa fa-check"></i>任务&nbsp;'+taskId+'&nbsp;成功</h4>'
                                      +'     <p>任务&nbsp;<strong>'+taskId+'</strong>&nbsp;成功，请<a target="_blank" href="/zmeng/task/index/id/'+taskId+'"><strong>点击此处</strong></a>查看。</p>'
                                      +'</div>';
                    noticeDiv.prepend(successHtml);
                    changeBtnStat(taskId,'success');
                    // 修改结束时间
                    $('#task-finish-time-'+taskId).text(res.info[taskId].finish_time);
                    console.log(res.info[taskId].finish_time);
                    // 修改结果文件大小
                    var taskFileLine = res.info[taskId].task_result_line ? res.info[taskId].task_result_line : 0;
                    var taskFileSize = res.info[taskId].task_result_size ? res.info[taskId].task_result_size : '0B';
                    $('#task-result-file-'+taskId).text(taskFileSize + ' / ' + taskFileLine + ' 行');
                    // 显示预览按钮
                    $('#task-result-file-preview-'+taskId).removeClass('hide');
                    }
                )
            }else{
                // for(var i=0;i<res.failed.length;i++){
                $.each(res.info, function (i, item) {
                    var taskId = res.info[i].id;
                    var failedHtml = '<div class="alert alert-danger alert-dismissible">'
                                     +'    <button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button>'
                                     +'    <h4><i class="icon fa fa-ban"></i>任务&nbsp;'+taskId+'&nbsp;失败</h4>'
                                     +'     <p>任务&nbsp;<strong>'+taskId+'</strong>&nbsp;失败，请<a target="_blank" href="/zmeng/task/index/id/'+taskId+'"><strong>点击此处</strong></a>查看。</p>'
                                     +'</div>';
                    noticeDiv.prepend(failedHtml);
                    changeBtnStat(taskId,'failed');
                });
            }
            //如果有新的任务(不管失败还是成功)完成，都打开提示
            // if(res.status){
                aside.addClass('control-sidebar-open');
            // }
                break;
        }

        
    }

    function changeBtnStat(id,status){
        var btn = $('#task-result-'+id);
        if(status=='success'){
            btn.find('span').removeClass('btn-success zm-task-running zm-task-created').addClass('btn-primary zm-task-finish').text('下载');
        }
        if(status=='failed'){
            btn.find('span').removeClass('btn-primary zm-task-download').addClass('btn-danger zm-task-created').text('重试');
        }
        if(window.action=='index') init();
    }


})

</script>
```

* php后台 

```php

/******************************************* gateWayClient Begin *****************************/
    /**
     * 通过回调函数,调取通知方法,
     * @param  2017-12-05
     * @param  [int]      $taskId    任务id
     * @param  [int]      $uid       绑定用户id
     * @param  [string]   $error   0 任务成功,1任务失败
     * @return [type]          [description]
     */
    public function informClient( $taskId=329, $uid=4, $error=0 ){
        #初始化客户端
        vendor('workerman/gatewayclient/Gateway');
        $client = new \GatewayClient\Gateway();
        $client::$registerAddress = $this->_gateWayAddress;
        #要通知的用户
        $clientArr = $client::getClientIdByUid($uid);
        #所有通知都通知测试账号
        if( $uid!=$this->_testAccountId && $client::isUidOnline($this->_testAccountId) ){
            #通过uid获取client_id 
            $client_id = $client::getClientIdByUid($this->_testAccountId);
            $clientArr = array_merge($clientArr, $client_id );
        }
        // var_dump($clientArr);die;
        #发送通知
        $message = $this->informInfo( $taskId, $error );
        $client::sendToAll( $message, $clientArr);
        var_dump($clientArr);
    }

    /**
     * 返回给前端的数据
     * @param  2017-12-06
     * @param  [type]     $taskId [任务id]
     * @param  [type]     $error  [0 成功]
     * @return [type]             [description]
     */
    private function informInfo( $taskId, $error ){
        // 根据 $newSuccessTasks 查找完成任务的基本信息
        $taskInfo = M('Task')->where(['id'=>['eq', $taskId]])->getField('id,task_result,task_result_line,finish_time')?: [];
        foreach($taskInfo as $key => $value){
            $Info[$key]['task_result_size'] = format_file_isze(filesize($value['task_result']));
            $Info[$key]['finish_time'] = date('Y-m-d H:i:s', $value['finish_time']);
            $Info[$key]['id'] = $value['id'];
            unset($Info[$key]['task_result']);
        }
        return  json_encode(['status'  => $error,'info' => $Info]);
    }


    #绑定用户uid和client_id
    /**
     * 绑定用户uid和client_id
     * @param  2017-12-06
     * @param  [int]         $uid   要绑定的用户uid
     * @param  [int]         $client_id client_id
     * @return [type]     [description]
     */
    public function bind()
    {
        vendor('workerman/gatewayclient/Gateway');
        $client = new \GatewayClient\Gateway();
        // 用户连接websocket之后,绑定uid和clientid,同时进行分组,根据接收到的roomid进行分组操作
        $uid=session('uid');
        $client_id=I('post.client_id');
        //注册地址配置
        $client::$registerAddress = $this->_gateWayAddress;
        // client_id与uid绑定
        $client::bindUid($client_id, $uid);
        #写入调试
        // $f = fopen('ab.txt','a');
        // fwrite($f, $client_id);
        // fclose($f);
        exit(json_encode(['status'=>3,'msg'=>'ok']));
    }

    /***********************************gateWayClient  END *********************************/

```
