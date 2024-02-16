`make format_logs_parquet`

mkdir ./ignored/minio-data

mkdir -p ./ignored/trino/date=2024-01-08
mkdir -p ./ignored/trino/date=2023-11-23
cp ./ignored/formatted_logs_parquet/exportedlogs/9c24a6ca-2940-46db-ae68-35fdbfc31c06/2024-01-08-\[\$LATEST\]0330663a5bde43789318e56dff29144b/000000.parquet ./ignored/trino/date=2024-01-08
cp ./ignored/formatted_logs_parquet/exportedlogs/b87379fb-9871-4ffc-8e4a-400327a32ab3/2023-11-23-\[\$LATEST\]1685d001422047d193bb13dbc0933004/000000.parquet ./ignored/trino/date=2023-11-23


aws configure --profile minio
aws configure set endpoint_url http://localhost:9000 --profile minio
aws s3 mb s3://logs --profile minio
aws s3 ls --profile minio
aws s3 ls s3://logs --recursive --profile minio
aws s3 cp ./ignored/trino s3://logs --recursive --profile minio


trino --server localhost:8080

CREATE SCHEMA IF NOT EXISTS minio.logs
WITH (location = 's3a://logs/');


CREATE TABLE minio.logs.logs (
  json VARCHAR,
  date VARCHAR
)
WITH (
  partitioned_by = ARRAY['date'],
  external_location = 's3a://logs/',
  format = 'PARQUET'
);

SHOW TABLES IN minio.logs;

call minio.system.sync_partition_metadata('logs', 'logs', 'ADD');

SELECT * FROM minio.logs.logs LIMIT 5;

SELECT date,* FROM minio.logs.logs where date='2023-11-23' LIMIT 15;

SELECT date,* FROM minio.logs.logs where date>='2023-11-23' LIMIT 15;

SELECT
  date,
  json_extract_scalar(json, '$.asctime') as asctime,
  json_extract_scalar(json, '$.request.path') as path,
  json
FROM minio.logs.logs
where date='2023-11-23'
  -- AND json_extract_scalar(json, '$.request.path')='/oauth/authorize'
LIMIT 15;





# ON AWS

select
  date,
  json_extract_scalar(json, '$.asctime') as asctime,
  json_extract_scalar(json, '$.request.path') as path,
  json
from mindful_athena
where date='2023-11-23'
limit 15;