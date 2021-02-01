#!/bin/bash

# Tests to ensure pushes to the mirror are disabled using the docker API: https://docs.docker.com/registry/spec/api/#pushing-an-image

status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST https://${MIRROR_HOSTNAME}.app.cloud.gov:443/v2/no-push/blobs/uploads/)
if [ "$status_code" != "405" ]; then
  echo "ERROR: Expected a status of 405 and receieved $status_code"
  exit 1
else
  echo "Pushes are disabled"
fi