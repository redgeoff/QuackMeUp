# QuackMeUp: Turnkey Data Analysis Using DuckDB and Metabase for Postgres & CloudWatch
:duck: _Dive into the world of data with a quack!_

![QuackMeUp](QuackMeUp.png)

## Overview
QuackMeUp is an open-source, Python-based toolkit designed to simplify the integration and analysis of data from various sources like PostgreSQL and AWS CloudWatch, using the power of DuckDB and Metabase. It's a one-stop solution for software engineers and data analysts looking to quack their way through data aggregation, transformation, and visualization.

**Key Features:**
- **Effortless Integration**: Seamlessly connect with PostgreSQL databases and CloudWatch logs.
- **Python-Powered**: Leverage the simplicity and flexibility of Python for data manipulation.
- **DuckDB at its Core**: Utilize DuckDB's OLAP capabilities for efficient data querying and analysis.
- **Metabase Visualization**: Transform data into insights with intuitive Metabase dashboards.
- **Modular Design**: Flexible architecture allows easy extension and customization.

## Installation

### Install dependencies

[Install Docker](https://docs.docker.com/get-docker/)

[Install the awscli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and run `aws configure`

Install Python, e.g. `brew install python@3.11`

`python3.11 -m pip install poetry`

`poetry install`

Install the Git hooks for code formatting with black: `poetry run pre-commit install`

Install DuckDB, e.g. `brew install duckdb`

### Configure the .env file

`cp .env.example .env` and then edit `.env`

Choose a value for `TERRAFORM_BUCKET_NAME` that will be unique across all AWS users, e.g. `myorg-quackmeup-terraform-bucket`, where `myorg` is a unique name for your organization. This bucket will be used to remotely store your Terraform state.

Choose a value for `LOGS_BUCKET_NAME` that will be unique across all AWS users, e.g. `myorg-quackmeup-logs`, where `myorg` is a unique name for your organization. This bucket will be used to store logs exported from CloudWatch.

Be sure to substitute the value of `PG_CONNECTION_STRING` with the connection string for your Postgres instance. Ideally, you’d use the connection string for a read replica.

You can leave the rest of the values in `.env` intact unless you prefer them to be different.

### Deploy infrastructure

[Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform)

Load the AWS Console and manually create an S3 bucket with the same name that you specified for `TERRAFORM_BUCKET_NAME`.

`./terraform/init.sh`

`./terraform/plan.sh`

The following `apply.sh` script will then:
- Create an S3 bucket for `LOGS_BUCKET_NAME`
- Create an ECR repository for the Lambda code
- Build and push a Docker image to this ECR repository
- Schedule a Lambda that will export the latest CloudWatch logs to the S3 bucket every 4 hours
- Create IAM policies and roles as needed

`./terraform/apply.sh`

### Tag target logs for export

Open the AWS Console and navigate to CloudWatch Log Groups. For each log that you wish to be exported to S3, simply add a tag with the name=`ExportToS3` and value=`true`. The log exporter Lambda runs every 4 hours so you'll have to wait at least 4 hours before you start seeing any data in the S3 bucket.

### Install QuackMeUp

`./scripts/duckdb/create_db.sh`

`./scripts/duckdb/create_tables.sh`

`./scripts/metabase/build_docker.sh`

`docker-compose up -d`

Seed the metabase config: `./scripts/metabase/import_db.sh`

## Execute pipeline

`./scripts/s3/download_logs.sh`

`make format_logs`

`./scripts/duckdb/import_logs.sh`

## Accessing Metabase

Visit [http://localhost:3000](http://localhost:3000) and log in with:

  - Email: quackmeup@example.com
  - Password: E!v_#nc$48pqfZJ

## Starting fresh

`docker-compose down`

`./scripts/metabase/delete_pgdata.sh`

`./scripts/duckdb/drop_db.sh`

Then repeat the installation

## Validating terraform config

`./terraform/validate.sh`

## Destroying infrastructure

`./terraform/destroy.sh`

## Running tests

`make lint`

`make mypy`

`make test`
`make test ARGS="-k test_extract_json_part"`

`make ci`