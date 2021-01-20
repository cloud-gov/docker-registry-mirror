#!/bin/sh

set -ex

docker network create pull-network

docker run --name pull-docker \
  -e DOCKER_TLS_CERTDIR=/certs \
  --network pull-network \
  --network-alias docker \
  -v some-docker-certs-ca:/certs/ca \
  -v some-docker-certs-client:/certs/client \
  --privileged \
  docker:dind &> /dev/null &

docker run -it --rm \
  -e DOCKER_TLS_CERTDIR=/certs \
  --network pull-network \
  -v some-docker-certs-client:/certs/client:ro \
  docker:latest pull ${MIRROR_HOSTNAME}.app.cloud.gov:443/hello-world

if [ $? != 0 ]; then
  echo "Docker pull through registry failed"
  exit 1
else 
  echo "Docker pulled successfully through registry"
fi