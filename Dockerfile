FROM alpine:3.10

ENV NGINX_VERSION 1.17.6
ENV RTMP_COMMIT 3bf75232676da7eeff85dcd0fc831533a5eafe6b
ENV VIDEO_JS_VERSION 7.7.3

RUN \
    addgroup -S nginx \
    && adduser -S -D -H -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && apk add --no-cache pcre \
    && apk add --no-cache --virtual .build-deps \
        curl \
        gcc \
        git \
        gnupg \
        libc-dev \
        linux-headers \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
    && cd /tmp \
    && curl -fSL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx.tar.gz \
    && curl -fSL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc -o nginx.tar.gz.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver keyserver.ubuntu.com --recv-key B0F4253373F8F6F510D42178520A9993A1C052F8 \
    && gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
    && rm -r "${GNUPGHOME}" nginx.tar.gz.asc \
    && tar -xf nginx.tar.gz \
    && rm nginx.tar.gz \
    && cd nginx-${NGINX_VERSION} \
    && git clone https://github.com/sergey-dryabzhinsky/nginx-rtmp-module.git \
    && git -C nginx-rtmp-module checkout ${RTMP_COMMIT} \
    && ./configure \
        --user=nginx \
        --group=nginx \
        --add-module=nginx-rtmp-module \
        --with-debug \
        --with-file-aio \
        --with-threads \
        --with-http_realip_module \
        --with-http_ssl_module \
        --with-http_v2_module \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && strip /usr/local/nginx/sbin/nginx \
    && cd .. \
    && rm -rf nginx-${NGINX_VERSION} \
    && apk del .build-deps \
    && ln -sf /dev/stdout /usr/local/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/nginx/logs/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

RUN cd /tmp \
    && apk add --no-cache --virtual .build-deps curl \
    && curl -fSL https://github.com/videojs/video.js/releases/download/v${VIDEO_JS_VERSION}/video-js-${VIDEO_JS_VERSION}.zip -o video-js.zip \
    && apk del .build-deps \
    && temp_dir=$(mktemp -d) \
    && cd "${temp_dir}" \
    && unzip /tmp/video-js.zip \
    && rm /tmp/video-js.zip \
    && cd - \
    && cp "${temp_dir}/video.min.js" /usr/local/nginx/html/ \
    && cp "${temp_dir}/video-js.min.css" /usr/local/nginx/html/ \
    && rm -r "${temp_dir}"

ADD nginx.conf /usr/local/nginx/conf/nginx.conf
ADD index.html /usr/local/nginx/html/

CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
