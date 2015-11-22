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