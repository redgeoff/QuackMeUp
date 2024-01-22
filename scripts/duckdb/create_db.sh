#!/usr/bin/env bash

cd $(dirname $0)/../..

source .env

duckdb ${DUCKDB_FILE} -c "select now()"