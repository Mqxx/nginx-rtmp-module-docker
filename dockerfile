FROM alpine:3.20

RUN apk add --no-cache \
    bash \
    build-base \
    pcre-dev \
    zlib-dev \
    openssl-dev \
    wget \
    git \
    ca-certificates \
    libc-dev \
    linux-headers \
    curl \
    unzip

RUN adduser -D -g 'nginx' nginx

ARG NGINX_VERSION=1.29.1
ARG NGINX_RTMP_VERSION=master

RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O /tmp/nginx.tar.gz; \
    tar -zxvf /tmp/nginx.tar.gz -C /tmp; \
    git clone --branch ${NGINX_RTMP_VERSION} --depth=1 https://github.com/arut/nginx-rtmp-module.git /tmp/nginx-rtmp-module; \
    cd /tmp/nginx-${NGINX_VERSION}; \
    ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-stream \
        --with-stream_ssl_module \
        --add-module=/tmp/nginx-rtmp-module; \
    make -j$(nproc); \
    make install; \
    rm -rf /tmp/*

RUN ln -sf /dev/stdout /var/log/nginx/access.log; \
    ln -sf /dev/stderr /var/log/nginx/error.log

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY defaults/ /defaults/

EXPOSE 80 443 1935

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

