## Build stage - compile nginx with RTMP module
FROM buildpack-deps:bookworm AS build

ENV NGINX_VERSION="nginx-1.26.2" \
    NGINX_RTMP_MODULE_VERSION="1.2.2"

RUN apt-get update \
    && apt-get install -y \
        ca-certificates \
        openssl \
        libssl-dev \
        libpcre2-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    # Download and decompress NGINX
    && mkdir -p /tmp/build/nginx \
    && cd /tmp/build/nginx \
    && wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz \
    && tar -zxf ${NGINX_VERSION}.tar.gz \
    # Download and decompress RTMP module
    && mkdir -p /tmp/build/nginx-rtmp-module \
    && cd /tmp/build/nginx-rtmp-module \
    && wget -O nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_MODULE_VERSION}.tar.gz \
    && tar -zxf nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz \
    # Build and install Nginx
    && cd /tmp/build/nginx/${NGINX_VERSION} \
    && ./configure \
        --sbin-path=/usr/local/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx/nginx.pid \
        --lock-path=/var/lock/nginx/nginx.lock \
        --http-log-path=/var/log/nginx/access.log \
        --http-client-body-temp-path=/tmp/nginx-client-body \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-threads \
        --with-pcre \
        --add-module=/tmp/build/nginx-rtmp-module/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} \
    && make -j $(getconf _NPROCESSORS_ONLN) \
    && make install

## Runtime stage - minimal image
FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        openssl \
        libpcre2-8-0 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/lock/nginx /var/run/nginx /var/log/nginx /html \
    && mkdir -p /usr/local/nginx/proxy_temp /usr/local/nginx/fastcgi_temp /usr/local/nginx/uwsgi_temp /usr/local/nginx/scgi_temp \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

COPY --from=build /usr/local/sbin/nginx /usr/local/sbin/nginx
COPY --from=build /etc/nginx/ /etc/nginx/
COPY nginx.conf /etc/nginx/nginx.conf
COPY html/ /html/

EXPOSE 80 1935

CMD ["nginx", "-g", "daemon off;"]
