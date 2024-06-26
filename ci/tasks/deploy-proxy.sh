#!/bin/bash

set -e

cf api $CF_API
cf auth

cf t -o $CF_ORG -s $CF_SPACE

space_guid=$(cf space --guid $CF_SPACE)

# assemble the conf
pushd source/proxy

  mkdir nginx
  cp ../../nginx-conf/nginx.conf nginx

  pwd
  ls -al

  cf push -f manifest.yml \
    --strategy rolling \
    --var mirror_hostname="${MIRROR_HOSTNAME}" \
    --var route="${MIRROR_HOSTNAME}.app.cloud.gov"
popd

cf add-network-policy docker-registry-proxy docker-registry-mirror --port 5000 --protocol tcp
