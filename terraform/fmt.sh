#!/bin/bash

cd $(dirname $0)

source ./transform_env.sh

terraform fmt
