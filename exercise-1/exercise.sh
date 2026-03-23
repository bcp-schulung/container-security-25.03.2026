docker build -t my-nginx .
docker run -p 9090:80 my-nginx
curl localhost:9090