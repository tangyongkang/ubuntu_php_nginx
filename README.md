#ANPSC Docker - 快速构建ANPSC容器环境

快速构建开发、测试、生产 Ubuntu + Nginx + Php + Redis + Supervisor 的Docker 容器应用环境


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

    sudo yum install -y yum-utils device-mapper-persistent-data lvm2  dos2unix


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


nginx 文件格式修改
    
    dos2unix entrypoint.sh
    
php 源码版本下载地址
   
    http://ftp.ntu.edu.tw/php/distributions/php-5.6.0.tar.gz


镜像加速  
     
      systemctl restart docker
      
      
安装mysql

      docker pull mysql:5.7
      docker run -d -p 3306:3306 --name mysql -v /docker/mysql/logs:/logs -v /docker/mysql/data:/var/lib/mysql -v /etc/mysql/mysql.conf.d/mysqld.cnf:/etc/mysql/mysql.conf.d/mysqld.cnf  -e MYSQL_ROOT_PASSWORD=123456 mysql:5.7
      docker exec -it mysql bash
      mysql -uroot -p123456
      
让root用户可以远程登陆
      
      GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '123456' WITH GRANT OPTION;
      
创建一个rcuser用户，给rcuser用户赋权，拥有所有权限，创建一个数据库实例rising,刷新生效
      
      CREATE USER 'rcuser'@'%' IDENTIFIED BY 'rcuser123';   
      GRANT ALL ON *.* TO 'rcuser'@'%';
      CREATE DATABASE rising;
      
修改字符集，插入中文不报错
      
      ALTER DATABASE rising DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;        
      flush privileges;
      

##主要特性

+ 基于[Alpine Linux](https://alpinelinux.org/) 最小化Linux环境加速构建镜像。 
+ 支持Nginx虚拟站点、SSL证书服务。配置参考Nginx中`cert`与`conf.d`目录文件。

所有的容器基于Alpine Linux,默认使用`sh` shell，进入容器时使用该命令：

```bash
$ docker exec -it container_name sh
```

## 构建镜像
    git clone https://github.com/tcyfree/anpsc.git
    docker build --no-cache -t anpsc:55 -f ./Dockerfile55 .
    docker build --no-cache -t anpsc:56 -f ./Dockerfile56 .
    docker build --no-cache -t anpsc:72 -f ./Dockerfile72 .
    
## 启动镜像
    docker run -d -p 8000:80  --name=lnmpv1  -v /www/wwwroot/dev_docker:/www/wwwroot/html/ anpsc:v1
 
    
## 进入镜像容器内
    docker exec -it lnmpv1 bash

        

## 推送镜像
    docker login # 先登录
    
    docker tag anpsc:v1 tcyfree/anpsc:v1
    
    docker push tcyfree/anpsc:v1

    sudo cp -r /www/wwwroot/alpine-nginx-php/php7 /root/