#!/usr/bin/env bash

cd $(dirname $0)/../..

source .env

duckdb ${DUCKDB_FILE} -c "INSTALL postgres"

duckdb ${DUCKDB_FILE} -c "LOAD postgres; CALL postgres_attach('${PG_CONNECTION_STRING}', source_schema='${PG_SCHEMA}');"