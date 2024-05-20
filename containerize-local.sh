docker build -t local_nginx ./src
docker run -d -p 8080:80 local_nginx