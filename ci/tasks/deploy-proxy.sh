#!/bin/bash

set -e

cf api $CF_API
cf auth

cf t -o $CF_ORG -s $CF_SPACE

space_guid=$(cf space --guid $CF_SPACE)

# assemble the conf
pushd proxy-source/proxy

  cp ../../nginx-conf/* .

  pwd
  ls -al

  export CF_TRACE=true

  cf push -f manifest.yml \
    --strategy rolling \
    --var mirror_hostname="${MIRROR_HOSTNAME}" \
    --var route="${MIRROR_HOSTNAME}.app.cloud.gov" 
popd

cf add-network-policy docker-registry-proxy docker-registry-mirror --port 5000 --protocol tcp