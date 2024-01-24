#!/usr/bin/env bash

cd $(dirname $0)

docker stop quackmeup-metabase-1
docker exec quackmeup-db-1 psql -U postgres -c 'DROP DATABASE metabase'
docker exec quackmeup-db-1 psql -U postgres -c 'CREATE DATABASE metabase'
cat ../../data/metabase/metabase.sql | docker exec -i quackmeup-db-1 psql -U postgres metabase
docker start quackmeup-metabase-1