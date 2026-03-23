FROM alpine:3.21

RUN apk update && apk upgrade --no-cache \
    && apk add --no-cache nginx \
    && sed -i 's/listen\s*80;/listen 8080;/' /etc/nginx/conf.d/default.conf && \
    sed -i 's|pid\s*/run/nginx.pid;|pid /tmp/nginx.pid;|' /etc/nginx/nginx.conf && \
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx /etc/nginx/conf.d && \
    chmod -R g+w /var/cache/nginx /var/log/nginx \
    && rm -rf /var/cache/apk/*

USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
