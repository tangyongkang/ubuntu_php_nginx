FROM ubuntu:16.04


# 设置基本环境变量
ENV NGINX_VERSION          1.14.0
ENV PHP_VERSION            5.6.0
ENV REDIS_VERSION          4.0.9

#  修改ubuntu的源为阿里源
RUN  cp etc/apt/sources.list  /etc/apt/sources.list.bak
COPY ./sources.list /etc/apt/sources.list

# 源文件修改后更新升级
RUN apt-get update
RUN apt-get -f install
RUN apt-get upgrade -y

# 安装环境必须依赖
RUN  apt-get -f -y install libxfont1 xfonts-encodings xfonts-utils xfonts-base xfonts-75dpi fontconfig libxcb1 libxrender1 libxext6
RUN  apt-get install -y --fix-missing autoconf unzip
RUN  apt-get install -y --fix-missing  vim libtool-bin bison  zlib1g-dev libpcre3 libpcre3-dev libssl-dev libxslt1-dev  libgeoip-dev libgoogle-perftools-dev libperl-dev libtool gcc
RUN  apt-get install -y --fix-missing  pkg-config libmcrypt-dev libxml2-dev build-essential openssl  libssl-dev make curl libcurl4-gnutls-dev libjpeg-dev  libpng-dev
# 在里面创建一个文件夹
RUN mkdir test

# 复制相关下载好的文件包进去
COPY ./nginx/nginx-${NGINX_VERSION}.tar.gz /test/
COPY ./php/php-${PHP_VERSION}.tar.gz /test/
COPY ./redis/redis-${REDIS_VERSION}.tar.gz /test/
COPY ./wkhtmltopdf/wkhtmltox_0.12.5-1.trusty_amd64.deb /test

COPY ./extension/redis-2.2.8.tgz /test/
COPY ./extension/memcache-3.0.6.tgz /test/
COPY ./extension/php-wkhtmltox-master.zip /test/
# COPY ./extension/zend-loader-php5.5-linux-x86_64.tar.gz /test/


# 安装nginx
RUN tar -zxvf /test/nginx-${NGINX_VERSION}.tar.gz -C /test \
    && rm -r /test/nginx-${NGINX_VERSION}.tar.gz \
    && cd  /test/nginx-${NGINX_VERSION} \
    && ./configure --prefix=/usr/local/nginx --with-http_ssl_module --with-stream --with-mail=dynamic\
    && make && make install \
    && cd /  \
    && rm -rf /test/nginx-${NGINX_VERSION} \
    && rm /usr/local/nginx/conf/nginx.conf

# 复制nginx.conf 配置进去
RUN mkdir -p /usr/local/nginx/conf/conf.d/
COPY ./nginx/nginx.conf /usr/local/nginx/conf/
COPY ./nginx/conf.d/default.conf   /usr/local/nginx/conf/conf.d/


# 安装php
RUN tar -zxvf /test/php-${PHP_VERSION}.tar.gz  -C /test \
    && rm -r /test/php-${PHP_VERSION}.tar.gz \
    && cd  /test/php-${PHP_VERSION} \
    && ./configure --prefix=/usr/local/php \
                   --with-config-file-path=/usr/local/php/etc \
                   --with-mysql=mysqlnd \
                   --with-mysqli=mysqlnd \
                   --with-pdo-mysql=mysqlnd \
                   --with-config-file-scan-dir=/usr/local/php/etc \
                   --enable-inline-optimization \
                   --disable-debug \
                   --disable-rpath \
                   --enable-shared \
                   --enable-opcache \
                   --enable-fpm \
                   --with-fpm-user=www-data \
                   --with-fpm-group=www-data \
                   --with-gettext \
                   --with-iconv \
                   --with-mcrypt \
                   --with-xmlrpc \
                   --enable-ftp \
                   --with-openssl \
                   --enable-bcmath \
                   --enable-sockets \
                   --enable-soap \
                   --with-libxml-dir \
                   --enable-mbstring \
                   --enable-socketsbcmath \
                   --enable-wddx \
                   --enable-calendar \
                   --with-curl \
                   --with-gd \
                   --with-zlib \
                   --enable-zip \
                   --with-pear \
    && make \
    && make install \
    && cd /  \
    && rm -rf /test/php-${PHP_VERSION}


# 复制相关配置
COPY ./php/php.ini  /usr/local/php/etc/
COPY ./php/php-fpm.conf  /usr/local/php/etc/

# 安装redis
RUN tar -zxvf /test/redis-${REDIS_VERSION}.tar.gz -C /test \
    && rm -r /test/redis-${REDIS_VERSION}.tar.gz \
    && cd  /test/redis-${REDIS_VERSION} \
    && make && make install \
    && cd /  \
    && rm -rf /test/redis-${REDIS_VERSION}

# 复制设置redis.conf 配置
RUN mkdir -p /etc/redis/
COPY ./redis/redis.conf  /etc/redis/


# 安装 wkhtmltopdf  wkhtmltox_0.12.5-1.trusty_amd64.deb
RUN dpkg -i /test/wkhtmltox_0.12.5-1.trusty_amd64.deb \
    && rm  /test/wkhtmltox_0.12.5-1.trusty_amd64.deb
# 安装字体
RUN apt-get install -y -f --force-yes  --no-install-recommends ttf-wqy-zenhei
RUN apt-get install -y -f --force-yes  --no-install-recommends ttf-wqy-microhei


# 安装php-redis 扩展  redis-2.2.8.tgz
RUN tar -zxvf /test/redis-2.2.8.tgz -C /test \
    && rm -r /test/redis-2.2.8.tgz \
    && cd  /test/redis-2.2.8 \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config \
    && make && make install \
    && cd /  \
    && rm -rf /test/redis-2.2.8

# 安装  php- memcache 扩展  memcache-3.0.6.tgz
RUN tar -zxvf /test/memcache-3.0.6.tgz -C /test \
    && rm -r /test/memcache-3.0.6.tgz \
    && cd  /test/memcache-3.0.6 \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config \
    && make && make install \
    && cd /  \
    && rm -rf /test/memcache-3.0.6

# 安装  ZendGuardLoader扩展 zend-loader-php5.5-linux-x86_64.tar.gz
#RUN tar -zxvf /test/zend-loader-php5.5-linux-x86_64.tar.gz -C /test \
#    && rm -r /test/zend-loader-php5.5-linux-x86_64.tar.gz \
#    && cp /test/zend-loader-php5.5-linux-x86_64/ZendGuardLoader.so  /usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/ \
#    && cp /test/zend-loader-php5.5-linux-x86_64/opcache.so  /usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/ \
#    && rm -rf /test/zend-loader-php5.5-linux-x86_64

# 安装wkhtmltopdf扩展  php-wkhtmltox-master.zip
RUN unzip /test/php-wkhtmltox-master.zip -d /test  \
    && rm -r /test/php-wkhtmltox-master.zip \
    && cd /test/php-wkhtmltox-master \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config \
    && make && make install \
    && cd /  \
    && rm -rf /test/php-wkhtmltox-master

# 守护进程  安装supervisor ,
RUN  apt-get install -y supervisor

#复制相关配置文件
COPY ./supervisor/php-fpm_supervisor.conf /etc/supervisor/conf.d/
COPY ./supervisor/nginx_supervisor.conf /etc/supervisor/conf.d/
COPY ./supervisor/redis_supervisor.conf /etc/supervisor/conf.d/

# 安装composer

#RUN curl -sS https://getcomposer.org/installer | /usr/local/php/bin/php \
#    && mv composer.phar /usr/local/bin/composer \
#    && ln -s /usr/local/php/bin/php /usr/local/bin/php \
#    && composer config -g repo.packagist composer https://packagist.phpcomposer.com


# 添加用户，分组
RUN useradd nginx

# 创建php执行路径文件夹
RUN mkdir -p /www/wwwroot/html/
#复制基本文件
COPY ./php/index.php  /www/wwwroot/html/

WORKDIR /www/wwwroot/
COPY ./entrypoint.sh /www/wwwroot/
RUN chmod +x /www/wwwroot/entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
