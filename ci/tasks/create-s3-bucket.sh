#!/bin/bash

set -e

cf api $CF_API
cf auth

cf t -o $CF_ORG -s $CF_SPACE

space_guid=$(cf space --guid $CF_SPACE)

svc_instance_name="docker-registry-mirror-s3"
svc_key_name="registry-key"

# ensure the service instance exists
svc_instance_json=$(cf curl "/v3/service_instances?names=${svc_instance_name}&space_guids=${space_guid}")
svc_instance_count=$(echo "$svc_instance_json" | jq -r '.pagination.total_results')
if [ 0 = $svc_instance_count ]; then
  echo "Creating service instance $svc_instance_name."
  cf cs s3 basic $svc_instance_name
  svc_instance_json=$(cf curl "/v3/service_instances?names=${svc_instance_name}&space_guids=${space_guid}")
else
  echo "Service instance $svc_instance_name already exists. Skipping creation."
fi
svc_instance_guid="$(cf service ${svc_instance_name} --guid)"

# ensure the service key exists
svc_keys_json=$(cf curl "/v3/service_credential_bindings?type=key&service_instance_names=${svc_instance_name}&names=${svc_key_name}")
svc_key_count=$(echo "$svc_keys_json" | jq -r '.pagination.total_results')
if [ 0 = $svc_key_count ]; then
  echo "Creating service key $svc_key_name."
  cf create-service-key $svc_instance_name $svc_key_name
else 
  echo "Service key $svc_key_name already exists. Skipping creation."
fi 
