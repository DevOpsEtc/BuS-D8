####################################################################
#  filename: Dockerfile                                            #
#  path:     ~/src/deploy/localhost/docker/build/test/Dockerfile      #
#  version:  1.0                                                   #
#  date:     08/25/2015                                            #
#  purpose:  build out tools service                               #
#  usage:                                                          #
#  notes:                                                          #
#  author:   DevOpsEtc @ https://github.com/DevOpsEtc              #
####################################################################

# base image
FROM alpine:latest

ENV TERM dumb

# update package list & install apps
RUN apk add --update \
    bash \
    curl \
    git \
    mysql-client \
    php \
    php-ctype \
    php-curl \
    php-cli \
    php-dom \
    php-gd \
    php-json \
    php-mysqli \
    php-openssl \
    php-pdo_mysql \
    php-phar \
    wget && \

    # cleanup
    rm -rf /var/cache/apk/* && \

    # install composer
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && \

    # install drush
    composer global require drush/drush:dev-master && \

    # symlink drush binary
    ln -sf ~/.composer/vendor/bin/drush.php /usr/bin/drush

# RUN mkdir -p /var/www

# WORKDIR /var/www

# COPY . /var/www

# VOLUME /var/www

# ENTRYPOINT ["/bin/sh", "-c"]

# CMD ["/usr/bin/tail", "-f"]


# match drush uid to osx host account; enable writing to nfs share
# run drush as nginx web server user
# -u www-data drush
# RUN usermod -u 501 www-data
# USER www-data

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

# keep container running for access via docker exec
CMD ["/usr/bin/tail", "-f"]
