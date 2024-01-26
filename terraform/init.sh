#!/bin/bash

set -a
cd $(dirname $0)

./transform_env.sh

terraform init
