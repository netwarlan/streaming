FROM buildpack-deps:bullseye

## Versions of Nginx and nginx-rtmp-module to use
ENV NGINX_VERSION="nginx-1.20.2" \
    NGINX_RTMP_MODULE_VERSION="1.2.2" \
    NGINX_WEB_DIR="/html"

## Install dependencies
RUN apt-get update \
    && apt-get install -y \
        ca-certificates \
        openssl \
        libssl-dev \
    && apt-get clean \
    && rm -rf /var/tmp/* /var/lib/apt/lists/* /tmp/* \

    ## Download and decompress NGINX
    && mkdir -p /tmp/build/nginx \
    && cd /tmp/build/nginx \
    && wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz \
    && tar -zxf ${NGINX_VERSION}.tar.gz \

    ## Download and decompress RTMP module
    && mkdir -p /tmp/build/nginx-rtmp-module \
    && cd /tmp/build/nginx-rtmp-module \
    && wget -O nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_MODULE_VERSION}.tar.gz \
    && tar -zxf nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz \
    && cd nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} \

    ## Build and install Nginx
    &&  cd /tmp/build/nginx/${NGINX_VERSION} \
    && ./configure \
        --sbin-path=/usr/local/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx/nginx.pid \
        --lock-path=/var/lock/nginx/nginx.lock \
        --http-log-path=/var/log/nginx/access.log \
        --http-client-body-temp-path=/tmp/nginx-client-body \
        --with-http_ssl_module \
        --with-threads \
        --add-module=/tmp/build/nginx-rtmp-module/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} \
    && make -j $(getconf _NPROCESSORS_ONLN) \
    && make install \
    && mkdir -p /var/lock/nginx \
    && mkdir -p $NGINX_WEB_DIR \
    && rm -rf /tmp/build \

    ## Forward logs to Docker
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

## Set up config file
COPY nginx.conf /etc/nginx/nginx.conf

## Copy web frontend
COPY html/ /html/

EXPOSE 80 1935

## Start here
CMD ["nginx", "-g", "daemon off;"]
