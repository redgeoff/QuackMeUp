# QuackMeUp: Streamlined Data Analytics in a Pythonic Pond
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

**Ideal for:**
- Software engineers seeking an integrated approach to data handling.
- Data analysts looking to combine and visualize complex datasets.
- Anyone enthusiastic about Python and open-source data analysis tools.

## Installation

### Install dependencies

[Install Docker](https://docs.docker.com/get-docker/)

Install the awscli and run `aws configure`

`cp .env.example .env` and then edit `.env`

`brew install python@3.11`

`python3.11 -m pip install poetry`

`poetry install`

`poetry run pre-commit install`

`brew install duckdb`

## Deploy infrastructure

[Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform)

Load the AWS Console and manually create an S3 bucket called `quackmeup-terraform-bucket`, which will be used to remotely store the terraform state.

`./terraform/init.sh`

`./terraform/plan.sh`

`./terraform/apply.sh`

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