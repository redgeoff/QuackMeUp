#!/bin/bash

cd $(dirname $0)

source ./transform_env.sh

terraform init -backend-config="bucket=$TERRAFORM_BUCKET_NAME" -backend-config="region=$REGION"