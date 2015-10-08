#!/bin/sh

LOCAL_BASE=/usr/local

# Install base services
pkg install -y virtualmin usermin bind910 apache24

# Enable services
echo ' \
# Virtualmin \
apache24_enable="YES" \
bind_enable="YES" \
webmin_enable="YES" \
usermin_enable="YES" \
\
' >> /etc/rc.conf

# Install PHP
pkg install -y php56 mod_php

# Install Supporting Packages
pkg install -y webalizer logrotate

# Logrotate expects this file
touch /var/log/lastlog

# Webmin Paths
webmin_base=$LOCAL_BASE/lib
webmin_config_base=$LOCAL_BASE/etc
webmin_config_dir=$webmin_config_base/webmin

# Reconfgigure BIND paths for /usr/local base (10.x)
sed -i -e "s/etc\//usr\/local\/etc\//" $webmin_config_dir/bind8/config
sed -i -e "s/usr\//usr\/local\//" $webmin_config_dir/bind8/config

# Use Apache 2.4
sed -i -e "s/apache22\//apache24\//" $webmin_config_dir/apache/config

# Enable Modules
sed -i -e "s/#LoadModule suexec_module/LoadModule suexec_module/" $LOCAL_BASE/etc/apache24/httpd.conf
sed -i -e "s/#LoadModule actions_module/LoadModule actions_module/" $LOCAL_BASE/etc/apache24/httpd.conf
sed -i -e "s/#LoadModule rewrite_module/LoadModule rewrite_module/" $LOCAL_BASE/etc/apache24/httpd.conf
sed -i -e "s/#LoadModule ssl_module/LoadModule ssl_module/" $LOCAL_BASE/etc/apache24/httpd.conf
sed -i -e "s/#LoadModule socache_shmcb_module/LoadModule socache_shmcb_module/" $LOCAL_BASE/etc/apache24/httpd.conf

# Enable Sample SSL Virtual Host
sed -i -e "s:#Include etc/apache24/extra/httpd-ssl.conf:Include etc/apache24/extra/httpd-ssl.conf:" $LOCAL_BASE/etc/apache24/httpd.conf

# Install Sample SSL Certificate and Key using pre-generated Webmin ones
openssl x509 -in $webmin_base/webmin/miniserv.pem > $LOCAL_BASE/etc/apache24/server.crt
openssl rsa -in $webmin_base/webmin/miniserv.pem > $LOCAL_BASE/etc/apache24/server.key

# SSL store
mkdir -p $LOCAL_BASE/etc/ssl/certs; mkdir -p $LOCAL_BASE/etc/ssl/private
