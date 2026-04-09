docker network create --subnet=171.20.0.0/24 lab-network

docker run -d --rm --name server1 --hostname server1 \
  --network lab-network --ip 171.20.0.10 \
  ubuntu:22.04 sleep infinity

docker run -d --rm --name server2 --hostname server2 \
  --network lab-network --ip 171.20.0.20 \
  ubuntu:22.04 sleep infinity

docker run -d --rm --name server3 --hostname server3 \
  --network lab-network --ip 171.20.0.30 \
  ubuntu:22.04 sleep infinity


for server in server1 server2 server3; do
  docker exec $server bash -c 'apt update && apt install -y iproute2 iputils-ping dnsutils net-tools openssh-server openssh-client curl netcat-openbsd rsync tcpdump' &
done
wait
echo "All tools installed"

docker exec -it server1 bash

dig -x 8.8.8.8 +short