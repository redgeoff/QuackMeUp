#!/usr/bin/env bash

cd $(dirname $0)

docker exec quackmeup-db-1 pg_dump -U postgres metabase > ../../data/metabase/metabase.sql