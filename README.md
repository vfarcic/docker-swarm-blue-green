Blue-Green Deployment to the Docker Swarm Cluster
=================================================

Prerequisites
-------------

* VirtualBox
* Vagrant

Steps
-----

```bash
# TODO: git clone

cd docker-swarm-blue-green

vagrant up

# Configures Ansible on the swarm-master node

vagrant ssh swarm-master

ansible-playbook /vagrant/ansible/swarm.yml -i /vagrant/ansible/hosts/dev

curl 10.100.192.200:8500/v1/catalog/nodes | jq '.'
```

```
[
  {
    "Node": "swarm-master",
    "Address": "10.100.192.200"
  },
  {
    "Node": "swarm-node-1",
    "Address": "10.100.192.201"
  },
  {
    "Node": "swarm-node-2",
    "Address": "10.100.192.202"
  }
]
```

```bash
export DOCKER_HOST=tcp://10.100.192.200:2375

docker info
```

```
Containers: 6
Images: 6
Role: primary
Strategy: spread
Filters: health, port, dependency, affinity, constraint
Nodes: 2
 swarm-node-1: 10.100.192.201:2375
  └ Containers: 3
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.018 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-31-generic, operatingsystem=Ubuntu 15.04, storagedriver=devicemapper
 swarm-node-2: 10.100.192.202:2375
  └ Containers: 3
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.018 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-31-generic, operatingsystem=Ubuntu 15.04, storagedriver=devicemapper
CPUs: 2
Total Memory: 2.037 GiB
Name: 0b8218c618d2
```

```bash
docker ps --format "table {{.Names}}"
```

```
NAMES
swarm-node-2/registrator
swarm-node-2/consul
swarm-node-1/registrator
swarm-node-1/consul
```

```bash
cd /vagrant/books-ms

chmod +x *.sh

cat nginx-includes.conf
```

```
location /api/v1/books {
  proxy_pass http://books-ms/api/v1/books;
  proxy_next_upstream error timeout invalid_header http_500;
}
```

```bash
sudo cp nginx-includes.conf /data/nginx/includes/books-ms.conf

cat get-next-color.sh
```

```
#!/usr/bin/env bash

CURR_COLOR=`curl http://localhost:8500/v1/kv/books-ms/color?raw`

if [ "$CURR_COLOR" == "blue" ]; then
    echo "green"
else
    echo "blue"
fi
```

```bash
cat docker-compose.yml
```

```
app:
  image: vfarcic/books-ms
  ports:
    - 8080
  environment:
    - SERVICE_NAME=books-ms
    - DB_HOST=books-ms-db

app-blue:
  environment:
    - SERVICE_NAME=books-ms-blue
  extends:
    service: app

app-green:
  environment:
    - SERVICE_NAME=books-ms-green
  extends:
    service: app

db:
  container_name: books-ms-db
  image: mongo
  environment:
    - SERVICE_NAME=books-ms-db
```

```bash
NEXT_COLOR=$(./get-next-color.sh)

export DOCKER_HOST=tcp://10.100.192.200:2375

docker-compose pull app

docker-compose stop app-$NEXT_COLOR

docker-compose rm -f app-$NEXT_COLOR

docker-compose --x-networking up -d db

docker-compose --x-networking scale app-$NEXT_COLOR=2

docker ps --filter name=books --format "table {{.Names}}"

curl 10.100.192.200:8500/v1/catalog/service/books-ms-$NEXT_COLOR | jq '.'
```

```
[
  {
    "Node": "swarm-node-2",
    "Address": "10.100.192.202",
    "ServiceID": "swarm-node-2:booksms_app-blue_1:8080",
    "ServiceName": "books-ms-blue",
    "ServiceTags": null,
    "ServiceAddress": "10.100.192.202",
    "ServicePort": 32769
  },
  {
    "Node": "swarm-node-1",
    "Address": "10.100.192.201",
    "ServiceID": "swarm-node-1:booksms_app-blue_2:8080",
    "ServiceName": "books-ms-blue",
    "ServiceTags": null,
    "ServiceAddress": "10.100.192.201",
    "ServicePort": 32769
  }
]
```

```bash
# Pre-Integration Testing

ADDRESS=`curl \
    localhost:8500/v1/catalog/service/books-ms-$NEXT_COLOR \
    | jq -r '.[0].ServiceAddress + ":" + (.[0].ServicePort | tostring)'`

curl http://$ADDRESS/api/v1/books | jq '.'

# Integration

cat nginx-upstreams-$NEXT_COLOR.ctmpl
```

```
upstream books-ms {
    {{range service "books-ms-blue" "any"}}
    server {{.Address}}:{{.Port}};
    {{end}}
}
```

```bash
sudo consul-template -consul localhost:8500 -template "nginx-upstreams-$NEXT_COLOR.ctmpl:/data/nginx/upstreams/books-ms.conf:docker kill -s HUP nginx" -once

cat /data/nginx/upstreams/books-ms.conf
```

```
upstream books-ms {

    server 10.100.192.201:32769;

    server 10.100.192.202:32769;

}
```

```bash
# Post-Integration Testing

curl http://10.100.192.200/api/v1/books | jq '.'

curl http://10.100.192.200/api/v1/books | jq '.'

curl http://10.100.192.200/api/v1/books | jq '.'

sudo docker logs nginx
```

```
... "GET /api/v1/books HTTP/1.1" 200 201 "-" "curl/7.38.0" "-" 10.100.192.201:32769
... "GET /api/v1/books HTTP/1.1" 200 201 "-" "curl/7.38.0" "-" 10.100.192.202:32769
... "GET /api/v1/books HTTP/1.1" 200 201 "-" "curl/7.38.0" "-" 10.100.192.201:32769
```

```bash
curl -X PUT -d $NEXT_COLOR localhost:8500/v1/kv/books-ms/color

NEXT_COLOR=$(./get-next-color.sh)

docker-compose stop app-$NEXT_COLOR

# Second Release

NEXT_COLOR=$(./get-next-color.sh)

docker-compose pull app

docker-compose stop app-$NEXT_COLOR

docker-compose rm -f app-$NEXT_COLOR

docker-compose --x-networking up -d db

docker-compose --x-networking scale app-$NEXT_COLOR=2

docker ps --filter name=books --format "table {{.Names}}"
```

```
NAMES
swarm-node-1/booksms_app-green_2
swarm-node-2/booksms_app-green_1
swarm-node-1/booksms_app-blue_2
swarm-node-1/books-ms-db
swarm-node-2/booksms_app-blue_1

# Pre-Integration Testing

ADDRESS=`curl \
    localhost:8500/v1/catalog/service/books-ms-$NEXT_COLOR \
    | jq -r '.[0].ServiceAddress + ":" + (.[0].ServicePort | tostring)'`

curl http://$ADDRESS/api/v1/books | jq '.'

# Integration

sudo consul-template -consul localhost:8500 -template "nginx-upstreams-$NEXT_COLOR.ctmpl:/data/nginx/upstreams/books-ms.conf:docker kill -s HUP nginx" -once

# Post-Integration Testing

curl http://10.100.192.200/api/v1/books | jq '.'

curl http://10.100.192.200/api/v1/books | jq '.'

curl http://10.100.192.200/api/v1/books | jq '.'

sudo docker logs nginx
```

```
... "GET /api/v1/books HTTP/1.1" 200 201 "-" "curl/7.38.0" "-" 10.100.192.201:32770
... "GET /api/v1/books HTTP/1.1" 200 201 "-" "curl/7.38.0" "-" 10.100.192.202:32770
... "GET /api/v1/books HTTP/1.1" 200 201 "-" "curl/7.38.0" "-" 10.100.192.201:32770
```

```bash
curl -X PUT -d $NEXT_COLOR localhost:8500/v1/kv/books-ms/color

NEXT_COLOR=$(./get-next-color.sh)

docker-compose stop app-$NEXT_COLOR

docker ps -a --filter name=books --format "table {{.Names}}\t{{.Status}}"
```

```
NAMES                              STATUS
swarm-node-1/booksms_app-green_2   Up 4 minutes
swarm-node-2/booksms_app-green_1   Up 4 minutes
swarm-node-1/booksms_app-blue_2    Exited (137) About a minute ago
swarm-node-1/books-ms-db           Up 16 minutes
swarm-node-2/booksms_app-blue_1    Exited (137) About a minute ago
```

Open [http://10.100.192.200:8500/](http://10.100.192.200:8500/)

TODO
----

* Change Compose to latest version