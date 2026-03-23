FROM alpine:3.21

RUN apk update && apk upgrade --no-cache \
    && apk add --no-cache nginx \
    && mkdir -p /run/nginx \
    && chown -R nginx:nginx /run/nginx \
    && chown -R nginx:nginx /var/lib/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && sed -i 's/listen\s*80;/listen 8080;/' /etc/nginx/http.d/default.conf \
    && rm -rf /var/cache/apk/*

USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
