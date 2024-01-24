#!/usr/bin/env bash

cd $(dirname $0)/../..

source .env

duckdb ${DUCKDB_FILE} -c "DROP TABLE IF EXISTS logs; CREATE TABLE logs AS SELECT * FROM 'ignored/formatted_logs/**/*.json'"