# Source: ideas adapted from
# https://medium.com/dnx-labs/exporting-cloudwatch-logs-automatically-to-s3-with-a-lambda-function-80e1f7ea0187

import os
import time
from typing import Any, Dict, List

import boto3
from botocore.exceptions import ClientError

from src.logger import logger

# Set to export specific logs or you can flag a log for export by tagging it with ExportToS3=true
LOGS_TO_EXPORT = [
    # "/aws/lambda/mylambda",
]

LOGS_BUCKET_NAME = os.getenv("LOGS_BUCKET_NAME")

PROJECT_NAME = os.getenv("PROJECT_NAME")

REGION = os.getenv("REGION")
SSM_KEY_PREFIX = f"/{PROJECT_NAME}/log-exporter/last-export"
SKIP_UNTIL_HOURS = 12

logs = boto3.client("logs", region_name=REGION)
ssm = boto3.client("ssm", region_name=REGION)


def get_log_groups() -> List[Dict[str, Any]]:
    next_token = None
    log_groups = []
    command = {"nextToken": next_token}

    while True:
        if next_token is not None:
            command = {"nextToken": next_token}
        else:
            command = {}

        data = logs.describe_log_groups(**command)

        if data["logGroups"]:
            log_groups += data["logGroups"]

        if not data.get("nextToken"):
            break

        next_token = str(data["nextToken"])

    return log_groups


def to_log_groups_to_export(log_groups: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    groups_to_export = []

    for log_group in log_groups:
        response = logs.list_tags_log_group(logGroupName=log_group["logGroupName"])
        log_group_tags = response["tags"]
        if "ExportToS3" in log_group_tags and log_group_tags["ExportToS3"] == "true":
            groups_to_export.append(log_group["logGroupName"])

    return groups_to_export


def get_s3_bucket() -> str:
    return LOGS_BUCKET_NAME


def get_last_export_value(param_name: str) -> str:
    value = "0"
    try:
        param = ssm.get_parameter(Name=param_name)
        if param["Parameter"].get("Value") is not None:
            value = param["Parameter"]["Value"]
    except ClientError as err:
        if err.response["Error"]["Code"] != "ParameterNotFound":
            raise err

    return value


def put_last_export_value(param_name: str, export_to_time: int) -> None:
    ssm.put_parameter(
        Name=param_name, Type="String", Value=str(export_to_time), Overwrite=True
    )


def schedule_exports(groups_to_export: List[str]) -> None:
    for log_group in groups_to_export:
        param_name = f"/{SSM_KEY_PREFIX}/{log_group}".replace("//", "/")

        value = get_last_export_value(param_name)
        export_to_time = int(round(time.time() * 1000))

        if export_to_time - int(value) < SKIP_UNTIL_HOURS * 60 * 60 * 1000:
            # Hasn't been long enough from the last export of this log group
            logger.info(
                "Skipping until it has been %i hrs from the last export",
                SKIP_UNTIL_HOURS,
                extra={
                    "logGroupName": log_group,
                    "export_to_time": export_to_time,
                    "value": value,
                },
            )
            continue

        request = {
            "logGroupName": log_group,
            "fromTime": int(value),
            "to": export_to_time,
            "destination": get_s3_bucket(),
        }

        try:
            response = logs.create_export_task(**request)

            logger.info(
                "Log export to S3 scheduled",
                extra={
                    "request": request,
                    "response": response,
                },
            )

            # TODO: is this timeout really needed to avoid LimitExceededException errors?
            time.sleep(1)
        except ClientError as err:
            if err.response["Error"]["Code"] == "LimitExceededException":
                # Logging logic here
                logger.warning(
                    "".join(
                        [
                            "Need to wait until all tasks are finished ",
                            "(LimitExceededException). Continuing later...",
                        ]
                    ),
                    extra={"e": err, "request": request},
                )
                break

            logger.error(
                "error exporting log to S3", extra={"e": err, "request": request}
            )
            raise err

        put_last_export_value(param_name, export_to_time)


def lambda_handler(_event: Any, _context: Any) -> None:
    if not get_s3_bucket():
        raise Exception("LOGS_BUCKET_NAME must be set")

    log_groups = get_log_groups()
    log_groups_to_export = to_log_groups_to_export(log_groups)

    log_groups_to_export.append(LOGS_TO_EXPORT)

    schedule_exports(log_groups_to_export)


if __name__ == "__main__":
    lambda_handler(None, None)
