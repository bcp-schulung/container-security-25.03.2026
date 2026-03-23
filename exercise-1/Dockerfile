FROM nginx:1.29.6

# Configure nginx to listen on unprivileged port
RUN sed -i 's/listen\s*80;/listen 8080;/' /etc/nginx/conf.d/default.conf && \
    sed -i 's|pid\s*/run/nginx.pid;|pid /tmp/nginx.pid;|' /etc/nginx/nginx.conf && \
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx /etc/nginx/conf.d && \
    chmod -R g+w /var/cache/nginx /var/log/nginx

COPY index.html /usr/share/nginx/html/index.html

USER nginx

EXPOSE 8080
