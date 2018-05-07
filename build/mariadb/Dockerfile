###########################################################
#  filename: Dockerfile                                   #
#  path:     ~/src/deploy/localhost/docker/mariadb/          #
#  version:  1.0                                          #
#  date:     08/13/2015                                   #
#  purpose:  build out mariadb service                    #
#  usage:                                                 #
#  notes:                                                 #
#  author:   DevOpsEtc @ https://github.com/DevOpsEtc   #
#  source:   https://registry.hub.docker.com/_/mariadb/   #
###########################################################

# choose base image
FROM debian:jessie

ENV MARIADB_MAJOR 10.0
ENV MARIADB_VERSION 10.0.21+maria-1~jessie
ENV DEBIAN_FRONTEND noninteractive

# add service user/group & match uid to osx host to enable writing to nfs share
# RUN groupadd -r mysql && useradd -r -g mysql mysql && usermod -u 501 mysql
RUN groupadd -r mysql && useradd -r mysql -u 501 -g mysql

RUN \
    # import and register GPG key, to verify integrity of install
    apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 199369E5404BD5FC7D2FE43BCBCB082A1BB943DB \
    \
    # add MariaDB official repo to sources.list & pin dependency preferrences
    && echo "deb http://ftp.osuosl.org/pub/mariadb/repo/$MARIADB_MAJOR/debian jessie main" > /etc/apt/sources.list.d/mariadb.list \
    && { \
      echo 'Package: *'; \
      echo 'Pin: release o=MariaDB'; \
      echo 'Pin-Priority: 999'; \
    } > /etc/apt/preferences.d/mariadb

RUN { \
		echo mariadb-server-$MARIADB_MAJOR mysql-server/root_password password 'unused'; \
		echo mariadb-server-$MARIADB_MAJOR mysql-server/root_password_again password 'unused'; \
    } | debconf-set-selections \
    && apt-get update -y \
    && apt-get install -y \
      mariadb-server=$MARIADB_VERSION \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql \
    && mkdir /var/lib/mysql

# keep separate from install so subsequent builds are faster
RUN sed -i \
      # which interfaces to listen on
      -r 's/^(bind-address|skip-networking)/;\1/' \
      /etc/mysql/my.cnf

    # && sed -i \
      # /etc/mysql/conf.d/mariadb.cnf

# VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

# EXPOSE 3306
CMD ["mysqld"]

    # cleanup some temp files
    # && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # && rm -rf /var/lib/mysql \
    # && mkdir /var/lib/mysql \
      # \
    # && sed -ri 's/^(bind-address|skip-networking)/;\1/' /etc/mysql/my.cnf
