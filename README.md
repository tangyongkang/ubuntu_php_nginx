#ANPSC Docker - 快速构建ANPSC容器环境

快速构建开发、测试、生产Docker + Alpine + PHP7 + Nginx + Composer + Supervisor + Crontab + Laravel 的Docker 容器应用环境


移除旧的版本：

    sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine

安装一些必要的系统工具：

    sudo yum install -y yum-utils device-mapper-persistent-data lvm2


添加软件源信息：

    sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo



更新 yum 缓存：

    sudo yum makecache fast
    


安装 Docker-ce：

    sudo yum -y install docker-ce


启动 Docker 后台服务

    sudo systemctl start docker


测试运行 hello-world

    docker run hello-world






镜像加速       

   由于众所周知的原因，docker国外源速度不快，所以这边我们使用ali的源，当然你可以选择其它的源。
   ali的源需要先去https://cr.console.aliyun.com/注册，会得到一个加速的个人连接，注册相关请自行百度。
   
   vim /etc/docker/daemon.json：
   {
     "registry-mirrors": ["https://yt3uvnue.mirror.aliyuncs.com"]
   }
   //重启使配置生效
   systemctl restart docker

##主要特性

+ 基于[Alpine Linux](https://alpinelinux.org/) 最小化Linux环境加速构建镜像。 
+ 支持Nginx虚拟站点、SSL证书服务。配置参考Nginx中`cert`与`conf.d`目录文件。

所有的容器基于Alpine Linux,默认使用`sh` shell，进入容器时使用该命令：

```bash
$ docker exec -it container_name sh
```

## 构建镜像
    git clone https://github.com/tcyfree/anpsc.git
    docker build --no-cache -t anpsc:v1 .
    
## 启动镜像
    docker run -d -p 8096:80 --name=lnmpv1 -v /www/wwwroot/PMS1:/usr/share/nginx/html/public anpsc:v1
 
    
## 进入镜像容器内
    docker exec -it anpsc-v1 sh

        

## 推送镜像
    docker login # 先登录
    
    docker tag anpsc:v1 tcyfree/anpsc:v1
    
    docker push tcyfree/anpsc:v1

    sudo cp -r /www/wwwroot/alpine-nginx-php/php7 /root/