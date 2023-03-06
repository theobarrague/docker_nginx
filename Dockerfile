# syntax=docker/dockerfile:1.3-labs

FROM debian:stable-slim

ARG OPENRESTY_VERSION=1.21.4.1
ARG OPENSSL_VERSION=3.0.8
ARG ZLIB_VERSION=1.2.13
ARG PCRE_VERSION=8.45

WORKDIR /tmp

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y build-essential musl-tools wget

RUN wget -qO - https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz | tar xvzf -
RUN wget -qO - https://github.com/openssl/openssl/archive/refs/tags/openssl-${OPENSSL_VERSION}.tar.gz | tar xvzf -
RUN wget -qO - https://ftp.exim.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz | tar xvzf -
RUN wget -qO - https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz | tar xvzf -

RUN cd openresty-${OPENRESTY_VERSION} \
  && CC="musl-gcc -static" ./configure \
    -j`nproc` \
    --with-cc-opt="-fstack-protector-strong -fPIC" \
    --with-openssl=../openssl-openssl-${OPENSSL_VERSION} \
    --with-zlib=../zlib-${ZLIB_VERSION} \
    --with-pcre=../pcre-${PCRE_VERSION} \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --lock-path=/var/lock/nginx.lock \
    --pid-path=/run/nginx.pid \
    --prefix=/usr/share/nginx \
    --with-openssl-opt="" \
    --with-pcre-opt="" \
    --with-zlib-opt="" \
    --with-http_v2_module \
    --with-pcre-jit \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
  && make -j`nproc` \
  && make install

FROM scratch

LABEL org.opencontainers.image.authors="theo@barrague.fr"

COPY --from=0 /usr/share/nginx/nginx/sbin/nginx /bin/nginx

COPY app/ /

ENTRYPOINT [ "/bin/nginx" ]
