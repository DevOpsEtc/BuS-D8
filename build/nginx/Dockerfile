###########################################################
#  filename: Dockerfile                                   #
#  path:     ~/src/deploy/localhost/docker/nginx/            #
#  version:  1.0                                          #
#  date:     08/22/2015                                   #
#  purpose:  build out nginx service                      #
#  usage:                                                 #
#  notes:                                                 #
#  author:   DevOpsEtc @ https://github.com/DevOpsEtc   #
#  source:   https://registry.hub.docker.com/_/nginx      #
###########################################################

# choose base image
FROM debian:jessie

ENV NGINX_VERSION 1.9.4-1~jessie

RUN \
    # import and regtister GPG key, to verify integrity of install
    apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
    \
    # add nginx official repo to sources.list
    && echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list

# install & cleanup
RUN apt-get update \
    && apt-get install -y \
      ca-certificates \
      nginx=${NGINX_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# match uid of service user to osx host account to enable writing to nfs share
RUN usermod -u 501 www-data

# config
RUN \
    # forward request and error logs to docker log collector
    ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    \
    # kill default website
    && rm -f /etc/nginx/conf.d/default.conf \
    \
    # load any .conf files under sites-enabled folder
    # && sed -i "s/\*\.conf;/\*\.conf;\n    include \/etc\/nginx\/sites\/*\.conf;/" /etc/nginx/nginx.conf \
    && sed -i \
      # run service in foreground to keep container running
      -e "1s/^/daemon off;/" \
      # run service as www-data user
      -e "s/user\s*nginx;/user www-data;/" \
      # ?
      # -e "s/worker_processes\s*1/worker_processes 1/" \
      # ?
      # -e "s/sendfile\s*on;/#sendfile on;/" \
      # ?
      -e "s/keepalive_timeout\s*65;/keepalive_timeout 2;/" \
      # upload files up to 100 MB
      -e "s/keepalive_timeout 2;/keepalive_timeout 2;\n    client_max_body_size 100m;/" \
      # ?
      -e "s/#gzip\s*on;/gzip on;/" \
      /etc/nginx/nginx.conf \
    \
    # check config syntax; easier to troublshoot before build
    && nginx -t \

    # fastcgi_params
    && sed -i \
      -e "s/fastcgi_param  SCRIPT_NAME/fastcgi_param  SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;\nfastcgi_param  SCRIPT_NAME/" \
      -e "s/fastcgi_param  REQUEST_URI/fastcgi_param  PATH_TRANSLATED    \$document_root\$fastcgi_path_info;\nfastcgi_param  REQUEST_URI/" \
      -e "s/fastcgi_param  PATH_TRANSLATED/fastcgi_param  PATH_INFO          \$fastcgi_path_info;\nfastcgi_param  PATH_TRANSLATED/" \
      /etc/nginx/fastcgi_params

# EXPOSE 80 443

# run nginx in foreground; to keep container running
# CMD ["nginx", "-g", "daemon off;"]
CMD ["nginx"]
