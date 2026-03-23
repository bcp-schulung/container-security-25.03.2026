docker ps
docker logs <container_id>
docker inspect <container_id>
docker exec -it <container_id> /bin/bash
docker cp <container_id>:/usr/share/nginx/html/index.html ./index.html
docker exec -it <container_id> kill 1
docker ps -a
docker start <container_id>