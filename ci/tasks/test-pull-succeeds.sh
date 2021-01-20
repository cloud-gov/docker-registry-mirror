#!/bin/sh

set -ex

docker --version

sudo /etc/init.d/docker start

docker pull ${MIRROR_HOSTNAME}.app.cloud.gov:443/18fgsa/concourse-task

if [ $? != 0 ]; then
  echo "Docker pull through registry failed"
  exit 1
else 
  echo "Docker pulled successfully through registry"
fi