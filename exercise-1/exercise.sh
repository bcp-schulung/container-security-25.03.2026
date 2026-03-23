docker build -t my-nginx .
docker run -d -p 9090:8080 my-nginx
curl localhost:9090