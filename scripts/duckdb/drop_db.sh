#!/usr/bin/env bash

cd $(dirname $0)/../..

source .env

rm -rf ${DUCKDB_FILE}