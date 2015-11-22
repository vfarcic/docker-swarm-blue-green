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

vagrant ssh swarm-master

ansible-playbook /vagrant/ansible/swarm.yml -i /vagrant/ansible/hosts/dev

curl 10.100.192.200:8500/v1/catalog/nodes | jq '.'

curl 10.100.192.200:8500/v1/catalog/services \
    | jq '.'

export DOCKER_HOST=tcp://10.100.192.200:2375

docker info

docker ps

cd /vagrant/books-ms

chmod +x *.sh

# Start repeat

NEXT_COLOR=$(./get-next-color.sh)

echo $NEXT_COLOR

docker-compose pull app

docker-compose stop app

docker-compose rm -f app

docker-compose --x-networking up -d db app-$NEXT_COLOR

docker ps --filter name=books --format "table {{.Names}}"

curl 10.100.192.200:8500/v1/catalog/services \
    | jq '.'

curl 10.100.192.200:8500/v1/catalog/service/books-ms-$NEXT_COLOR \
    | jq '.'

ADDRESS=`curl \
    localhost:8500/v1/catalog/service/books-ms-$NEXT_COLOR \
    | jq -r '.[0].ServiceAddress + ":" + (.[0].ServicePort | tostring)'`

curl http://$ADDRESS/api/v1/books
```

TODO
----

* Remove all but 8500 from Consul
