#!/bin/bash

##
# CONFIGURE THE SCRIPT HERE
##
NGINX_VERSION=1.5.0
PHP_VERSION=5.4.15
MYSQL_VERSION=5.6.11
MYSQL_PASSWORD="YOURPWHERE"
PCRE_VERSION=8.32
NGINX_PARAMS="--with-http_ssl_module --with-pcre=pcre-8.32 --with-http_realip_module --with-http_gzip_static_module --without-http_ssi_module --without-http_userid_module --without-http_auth_basic_module --without-http_geo_module --without-http_map_module --without-http_split_clients_module --without-http_uwsgi_module --without-http_scgi_module --without-http_browser_module"
PHP_PARAMS="--with-mysql --enable-fpm --with-zlib --with-pcre --with-pear --enable-fastcgi -with-mcrypt --enable-cli --with-gd"







### DO NOT EDIT BELOW HERE
ORIGINAL_DIRECTORY=$PWD
CFLAGS="-fstack-protector-all -fomit-frame-pointer -Os -pipe -falign-functions=64 -falign-loops=32 -fforce-addr -ffast-math"

# Run update
apt-get update && apt-get upgrade
# Stop non-required software
/etc/init.d/apache2 stop
/etc/init.d/sendmail stop
# Purge non-required software
apt-get purge apache2 bind9 sendmail
# Install dependencies
apt-get install git build-essential libssl-dev libxml2-dev libaio1 libaio-dev libncurses5 libncurses5-dev cmake libmcrypt-dev libpng-dev

mkdir ~/src
cd ~/src


##
# NGINX SETUP
##
wget -O - "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz" |tar xz
cd nginx-$NGINX_VERSION
wget -O - "ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$PCRE_VERSION.tar.gz" |tar xz
./configure $NGINX_PARAMS --with-cc-opt="$CFLAGS"
make && make install
mkdir /usr/local/nginx/sites-enabled
mkdir /var/{log,www}
git clone https://github.com/martijngonlag/Nginx-config.git
cp Nginx-config/nginx /etc/init.d/nginx
chmod +x /etc/init.d/nginx
rm -rf Nginx-config
ln -s $ORIGINAL_DIRECTORY/nginx.conf /usr/local/nginx/conf/
cd ..


##
# PHP SETUP
##
groupadd nobody
wget -O - "http://us1.php.net/distributions/php-$PHP_VERSION.tar.gz" |tar xz
cd php-$PHP_VERSION
./configure $PHP_PARAMS --with-cc-opt="$CFLAGS"
make && make install
cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
mv /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf
cd ..


##
# MYSQL SETUP
##
groupadd mysql
useradd -g mysql mysql
wget -O - "http://cdn.mysql.com/Downloads/MySQL-5.6/mysql-$MYSQL_VERSION.tar.gz" |tar xz
cd mysql-$MYSQL_VERSION
CFLAGS="$CFLAGS" cmake .
make && make install
cd /usr/local/mysql
chown -R mysql .
chgrp -R mysql .
scripts/mysql_install_db --user=mysql --no-defaults
chown -R root .
chown -R mysql data
bin/mysqld_safe --user=mysql &
ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe
ln -s /tmp/mysql.sock /var/run/mysqld/mysqld.sock
ln -s /usr/local/mysql/bin/mysql /usr/bin
cp support-files/my-default.cnf /etc/mysql/my.cnf
cp support-files/mysql.server /etc/init.d/mysql
mkdir /var/run/mysqld
ln -s /tmp/mysql.sock /var/run/mysqld/mysqld.sock
mysqladmin -u root password $MYSQL_PASSWORD
/usr/local/mysql/bin/mysql_secure_installation

update-rc.d php-fpm defaults
update-rc.d nginx defaults
update-rc.d mysql defaults
