#!/bin/bash

cf api $CF_API
cf auth

cf t -o $CF_ORG -s $CF_SPACE

space_guid=$(cf space --guid $CF_SPACE)

cf cancel-deployment $CF_APP_NAME
