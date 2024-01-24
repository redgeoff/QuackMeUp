#!/usr/bin/env bash

cd $(dirname $0)

docker build -f Dockerfile_metabase -t quackmeup-metabase .