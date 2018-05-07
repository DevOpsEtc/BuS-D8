
###########################################################
#  filename: Dockerfile                                   #
#  path:     ~/src/deploy/localhost/docker/php-fpm/          #
#  version:  1.0                                          #
#  date:     08/26/2015                                   #
#  purpose:  build out php-fpm service                    #
#  usage:                                                 #
#  notes:                                                 #
#  author:   DevOpsEtc @ https://github.com/DevOpsEtc   #
#  source:   https://registry.hub.docker.com/_/php        #
###########################################################

# choose base image
FROM debian:jessie

ENV DEBIAN_FRONTEND noninteractive

# install PHP-FPM, php extensions & mta
RUN apt-get update -y && \
    apt-get install -y \
      # make \
      php5-fpm \
      # php access to db
      php5-mysqlnd \
      ## file encryption
      # php5-mcrypt \
      php5-curl \
      # image creation/manipulation via php
      php5-gd \
      # php5-json \
      # pecl dependency
      php5-dev \
      # pecl installer
      php-pear \
      # simple mta to deliver smtp
      ssmtp && \

    # install uploadprogress
    pecl install uploadprogress && \

    # remove unneeded packages
    apt-get remove -y php5-dev && \
    apt-get autoremove -y && \

    # clean up
    rm -rf /var/lib/apt/lists/*
      # php5-cli \ # cli access to php
      # php5-memcache \
      # php5-xdebug \

RUN usermod -u 501 www-data

RUN \
    # php-fpm.conf
    sed -i \
      # keep FPM in foreground
      -e "s/;daemonize = yes/daemonize = no/" \
      # global error log to docker log collector
      -e "s/error_log =.*/error_log = \/proc\/self\/fd\/2/" \
      /etc/php5/fpm/php-fpm.conf && \

    # www.conf
    # site access log to docker log collector; send to /proc/self/fd/1 to hide
    sed -i \
      -e "s/;access.log =.*/access.log = \/proc\/self\/fd\/2/" \
      # accept FastCGI requests from all interfaces via TCP socket
      -e "s/listen = .*/listen = \[::\]:9000/" \
      # make all environment variables available to PHP code
      -e "s/;clear_env = no/clear_env = no/" \
      # only serve php files with .php extention
      -e "s/;security.limit_extensions = .*/security.limit_extensions = .php/" \
      # enable status page
      -e "s/;pm.status_path =.*/pm.status_path = \/fpm-status/" \
      /etc/php5/fpm/pool.d/www.conf && \

    # php.ini
    # add uploadprogress extension
    sed -i \
      -e "$ a\extension=uploadprogress.so" \
      -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" \
      -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" \
      # prevent closet match page loading
      # -e "s/;cgi.fix_pathinfo=0/cgi.fix_pathinfo=1/" \
      -e "s/;sendmail_path =.*/sendmail_path = \/usr\/sbin\/ssmtp -t/" \
      -e "s/;date.timezone =.*/date.timezone = UTC/" \
      /etc/php5/fpm/php.ini && \

    # php.ini (cli)
    sed -i "s/;date.timezone =.*/date.timezone = UTC/" \
    /etc/php5/cli/php.ini && \

    # ssmtp.conf; smtp relay via gmail
    sed -i \
      -e "s/#FromLineOverride=.*/FromLineOverride=YES/" \
      -e "$ a\UseSTARTTLS=YES" \
      /etc/ssmtp/ssmtp.conf

    # -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php5-fpm.sock/" $WWW_CONF
    # -e "s/;listen.mode = 0660/listen.mode = 0660/g" $WWW_CONF
    # -e "s/display_errors = Off/display_errors = On/" $PHP_INI
    # -e "s/error_log = Off/display_errors = On/" $PHP_INI
    # -e "s/;error_log = syslog/error_log = \/var\/log\/php_errors.log/" $PHP_INI
    # -e "s/display_errors = Off/display_errors = stderr/" $PHP_INI
    # -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" $WWW_CONF
    # -e "s/pm.max_children = 5/pm.max_children = 9/g" $WWW_CONF
    # -e "s/pm.start_servers = 2/pm.start_servers = 3/g" $WWW_CONF
    # -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" $WWW_CONF
    # -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" $WWW_CONF
    # -e "s/pm.max_requests = 500/pm.max_requests = 200/g" $WWW_CONF
    # -e "s/chdir = \//chdir = \/var\/www\/public/g" $WWW_CONF

CMD ["php5-fpm"]
