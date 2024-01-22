#!/usr/bin/env bash

cd $(dirname $0)/../..

source .env

aws s3 sync s3://${LOGS_BUCKET_NAME}/ ignored/logs