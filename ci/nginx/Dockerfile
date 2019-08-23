FROM nginx:stable-alpine

COPY nginx/nginx.conf  /etc/nginx/nginx.conf
COPY nginx/startup.sh  /opt/startup.sh
COPY assets            /opt/www/public

EXPOSE 8080

RUN touch /var/run/nginx.pid && \
  chown -R nginx:0 /var/run/nginx.pid /var/cache/nginx /opt/www/public /etc/nginx /run && \
  chmod -R g=u /opt/www/public /var/cache/nginx /etc/nginx /var/run/nginx.pid /run

USER nginx

ENTRYPOINT ["/opt/startup.sh"]
