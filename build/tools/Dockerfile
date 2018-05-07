####################################################################
#  filename: Dockerfile                                            #
#  path:     ~/src/deploy/localhost/docker/tools/                     #
#  version:  1.0                                                   #
#  date:     08/24/2015                                            #
#  purpose:  build out tools service                               #
#  usage:                                                          #
#  notes:                                                          #
#  author:   DevOpsEtc @ https://github.com/DevOpsEtc            #
#  source:   https://registry.hub.docker.com/u/composer/composer/  #
####################################################################

# choose base image
FROM debian:jessie

# install php, composer, git, drush & dependencies
RUN apt-get update && \
    apt-get install -y \
      curl \
      # revision control system
      git \
      # cli access to php
      php5-cli \
      # image creation/manipulation via php
      php5-gd \
      # php access to db
      php5-mysqlnd \
      # cli access to db via drush
      mysql-client && \
      \
    # clean up
    rm -rf /var/lib/apt/lists/* && \
    # install composer
    curl -sS https://getcomposer.org/installer | php && \
      \
    # move composer binary
    mv composer.phar /usr/local/bin/composer && \
      \
    # install drush
    composer global require drush/drush:dev-master && \
      \
    # symlink drush binary
    ln -sf ~/.composer/vendor/bin/drush.php /usr/local/bin/drush

# php config
# RUN sed -i \
#   -e 's/display_errors = Off/display_errors = On/' /etc/php5/apache2/php.ini \
    # -e 's/display_errors = Off/display_errors = On/' /etc/php5/cli/php.ini

# match drush uid to osx host account; enable writing to nfs share
# run drush as nginx web server user
# -u www-data drush
# RUN usermod -u 501 www-data
# USER www-data

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

# keep container running for access via docker exec
CMD ["/usr/bin/tail", "-f"]
