#!/bin/bash

set -a
cd $(dirname $0)

source ./transform_env.sh

terraform destroy
