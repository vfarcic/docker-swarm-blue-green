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

TODO: Continue

```bash
cd /vagrant/books-ms

chmod +x *.sh

sudo cp nginx-includes.conf /data/nginx/includes/books-ms.conf

# Start repeat

NEXT_COLOR=$(./get-next-color.sh)

echo $NEXT_COLOR

docker-compose pull app

docker-compose rm -f app

docker-compose --x-networking scale db=1 app-$NEXT_COLOR=2

docker ps --filter name=books --format "table {{.Names}}"

curl 10.100.192.200:8500/v1/catalog/services \
    | jq '.'

curl 10.100.192.200:8500/v1/catalog/service/books-ms-$NEXT_COLOR \
    | jq '.'

ADDRESS=`curl \
    localhost:8500/v1/catalog/service/books-ms-$NEXT_COLOR \
    | jq -r '.[0].ServiceAddress + ":" + (.[0].ServicePort | tostring)'`

curl http://$ADDRESS/api/v1/books | jq '.'

sudo consul-template \
    -consul localhost:8500 \
    -template "nginx-upstreams-$NEXT_COLOR.ctmpl:/data/nginx/upstreams/books-ms.conf:docker kill -s HUP nginx" \
    -once

curl http://10.100.192.200/api/v1/books | jq '.'

curl http://10.100.192.200/api/v1/books | jq '.'

curl http://10.100.192.200/api/v1/books | jq '.'

sudo docker logs nginx

curl -X PUT -d $NEXT_COLOR \
    localhost:8500/v1/kv/books-ms/color

NEXT_COLOR=$(./get-next-color.sh)

docker-compose stop app-$NEXT_COLOR

curl http://10.100.192.200/api/v1/books | jq '.'

# End repeat
```

Open [http://10.100.192.200:8500/](http://10.100.192.200:8500/)

TODO
----

* Change Compose to latest version