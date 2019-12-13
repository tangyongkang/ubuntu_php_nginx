FROM ubuntu:16.04

# 设置基本环境变量
ENV NGINX_VERSION                           1.17.4
ENV PHP_VERSION                             7.2.0
ENV REDIS_VERSION                           4.0.9
ENV PHP_WKHTMLTOPDF                         wkhtmltox_0.12.5-1.trusty_amd64

# PHP 扩展安装
ENV PHP_EXTENSION_XLS_WRITER                php-ext-excel-export
ENV PHP_EXTENSION_REDIS                     4.2.0
ENV PHP_EXTENSION_WKHTMLTOPDF               phpwkhtmltox-master

# 其它  php-7.2.0
ENV PHP_INI_EXTENSION_PATH                  /usr/local/php/lib/php/extensions/no-debug-non-zts-20170718/


#  修改ubuntu的源为阿里源
RUN  rm -rf etc/apt/sources.list
COPY ./sources.list /etc/apt/sources.list

# 源文件修改后更新升级
RUN apt-get update
RUN apt-get -f install
RUN apt-get upgrade -y

# 安装环境必须依赖
RUN  apt-get -f -y install libxfont1 xfonts-encodings xfonts-utils xfonts-base xfonts-75dpi fontconfig libxcb1 libxrender1 libxext6
RUN  apt-get install -y --fix-missing autoconf unzip wget
RUN  apt-get install -y --fix-missing  libtool-bin bison  zlib1g-dev libpcre3 libpcre3-dev libssl-dev libxslt1-dev  libgeoip-dev libgoogle-perftools-dev libperl-dev libtool gcc
RUN  apt-get install -y --fix-missing  pkg-config libmcrypt-dev libxml2-dev build-essential openssl  libssl-dev make curl libcurl4-gnutls-dev libjpeg-dev  libpng-dev
# 在里面创建一个文件夹
RUN mkdir test

# 复制相关下载好的文件包进去
COPY ./nginx/nginx-${NGINX_VERSION}.tar.gz /test/
COPY ./php/php-${PHP_VERSION}.tar.gz /test/
COPY ./redis/redis-${REDIS_VERSION}.tar.gz /test/
COPY ./wkhtmltopdf/${PHP_WKHTMLTOPDF}.deb /test

COPY ./extension/redis-${PHP_EXTENSION_REDIS}.tgz /test/
COPY ./extension/${PHP_EXTENSION_WKHTMLTOPDF}.zip /test/
COPY ./extension/${PHP_EXTENSION_XLS_WRITER}.zip /test/


#安装nginx
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
COPY ./nginx/conf.d/rewrite.conf   /usr/local/nginx/conf/conf.d/


 #安装php
RUN tar -zxvf /test/php-${PHP_VERSION}.tar.gz  -C /test \
    && rm -r /test/php-${PHP_VERSION}.tar.gz \
    && cd  /test/php-${PHP_VERSION} \
    && ./configure --prefix=/usr/local/php \
                   --with-config-file-path=/usr/local/php/etc \
                   --with-mysqli=mysqlnd \
                   --with-pdo-mysql=mysqlnd \
                   --with-config-file-scan-dir=/usr/local/php/etc/php.d \
                   --enable-inline-optimization \
                   --disable-debug \
                   --with-openssl \
                   --disable-rpath \
                   --enable-shared \
                   --enable-opcache \
                   --enable-fpm \
                   --with-fpm-user=nginx \
                   --with-fpm-group=nginx \
                   --with-gettext \
                   --with-iconv \
                   --with-xmlrpc \
                   --enable-ftp \
                   --enable-bcmath \
                   --enable-soap \
                   --with-libxml-dir \
                   --enable-mbstring \
                   --enable-wddx \
                   --enable-calendar \
                   --with-curl \
                   --with-gd \
                   --with-zlib \
                   --enable-zip \
                   --enable-pcntl \
                   --with-pear \
    && make \
    && make install \
    && cd / \
    && rm -rf /test/php-${PHP_VERSION}


# 复制相关配置
COPY ./php/php7.ini  /usr/local/php/etc/
COPY ./php/php-fpm.conf  /usr/local/php/etc/
# 软连接处理
RUN ln -s /usr/local/php/bin/php /usr/local/bin/php \
    && mv /usr/local/php/etc/php7.ini /usr/local/php/etc/php.ini

# 根据php环境不同  extension_dir 也不同
RUN sed -i "s|extension_dir =.*|extension_dir =  "${PHP_INI_EXTENSION_PATH}"|i" /usr/local/php/etc/php.ini


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
RUN dpkg -i /test/${PHP_WKHTMLTOPDF}.deb \
    && rm  /test/${PHP_WKHTMLTOPDF}.deb
# 安装字体
RUN apt-get install -y -f --force-yes  --no-install-recommends ttf-wqy-zenhei
RUN apt-get install -y -f --force-yes  --no-install-recommends ttf-wqy-microhei


# 安装php-redis 扩展
RUN tar -zxvf /test/redis-${PHP_EXTENSION_REDIS}.tgz -C /test \
    && rm -r /test/redis-${PHP_EXTENSION_REDIS}.tgz \
    && cd  /test/redis-${PHP_EXTENSION_REDIS} \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config \
    && make && make install \
    && cd /  \
    && rm -rf /test/redis-${PHP_EXTENSION_REDIS}

# 安装php-xlswriter 扩展
RUN unzip /test/${PHP_EXTENSION_XLS_WRITER}.zip -d /test  \
    && rm -r /test/${PHP_EXTENSION_XLS_WRITER}.zip \
    && cd /test/${PHP_EXTENSION_XLS_WRITER} \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config  --enable-reader\
    && make && make install \
    && cd /  \
    && rm -rf /test/${PHP_EXTENSION_XLS_WRITER}


# 安装wkhtmltopdf扩展  php-wkhtmltox-master.zip
RUN unzip /test/${PHP_EXTENSION_WKHTMLTOPDF}.zip -d /test  \
    && rm -r /test/${PHP_EXTENSION_WKHTMLTOPDF}.zip \
    && cd /test/${PHP_EXTENSION_WKHTMLTOPDF} \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config \
    && make && make install \
    && cd /  \
    && rm -rf /test/${PHP_EXTENSION_WKHTMLTOPDF}



# 守护进程  安装supervisor ,
RUN  apt-get install -y supervisor

#复制相关配置文件
COPY ./supervisor/php-fpm_supervisor.conf /etc/supervisor/conf.d/
COPY ./supervisor/nginx_supervisor.conf /etc/supervisor/conf.d/
COPY ./supervisor/redis_supervisor.conf /etc/supervisor/conf.d/

# 安装composer
RUN wget https://getcomposer.org/composer.phar \
    && mv composer.phar composer \
    && chmod +x composer \
    && mv composer /usr/local/bin \
    && composer config -g repo.packagist composer https://packagist.phpcomposer.com

# 安装 crontab
RUN apt-get install -y cron

#
## 卸载不必要的环境依赖
##RUN apt-get -y autoremove libxfont1 xfonts-encodings xfonts-utils xfonts-base xfonts-75dpi fontconfig libxcb1 libxrender1 libxext6 autoconf unzip
##RUN apt-get -y autoremove libtool-bin bison  zlib1g-dev libpcre3 libpcre3-dev libssl-dev libxslt1-dev  libgeoip-dev libgoogle-perftools-dev libperl-dev libtool gcc
##RUN apt-get -y autoremove pkg-config libmcrypt-dev libxml2-dev build-essential openssl  libssl-dev make curl libcurl4-gnutls-dev libjpeg-dev  libpng-dev
RUN apt-get -y autoremove unzip

# 修复环境依赖
RUN apt-get update
RUN apt-get -f install
RUN apt-get upgrade -y



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
