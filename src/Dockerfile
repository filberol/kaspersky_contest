FROM nginx

# Copy config from local files
COPY /etc/nginx/conf.d /etc/nginx/conf.d

# Copy custom files to the nginx html directory
COPY *.html /usr/share/nginx/html

EXPOSE 80