#!/bin/bash

set -e

cf api $CF_API
cf auth

cf t -o $CF_ORG -s $CF_SPACE

space_guid=$(cf space --guid $CF_SPACE)

# Read the service key values and inject them via envars
svc_instance_name="docker-registry-mirror-s3"
svc_key_name="registry-key"
svc_key_guid=$(cf service-key --guid $svc_instance_name $svc_key_name)
svc_key_json=$(cf curl "/v2/service_keys/${svc_key_guid}")
s3_access_key=$(echo "$svc_key_json" | jq -r '.entity.credentials.access_key_id')
s3_bucket=$(echo "$svc_key_json" | jq -r '.entity.credentials.bucket')
s3_region=$(echo "$svc_key_json" | jq -r '.entity.credentials.region')
s3_secret_key=$(echo "$svc_key_json" | jq -r '.entity.credentials.secret_access_key')

cf push -f source/registry/manifest.yml \
  --strategy rolling \
  --var s3_access_key="${s3_access_key}" \
  --var s3_bucket="${s3_bucket}" \
  --var s3_region="${s3_region}" \
  --var s3_secret_key="${s3_secret_key}" \
  --var route="${MIRROR_HOSTNAME}.apps.internal"
