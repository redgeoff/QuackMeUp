from unittest.mock import MagicMock, patch

from src.log_exporter.lambda_handler import (
    get_last_export_value,
    get_log_groups,
    lambda_handler,
    put_last_export_value,
    schedule_exports,
    to_log_groups_to_export,
)


@patch("src.log_exporter.lambda_handler.boto3.client")
def test_get_log_groups(mock_boto_client):
    # Set up the mock client and its method
    mock_logs_client = MagicMock()
    mock_logs_client.describe_log_groups.side_effect = [
        {
            "logGroups": [{"logGroupName": "group1"}, {"logGroupName": "group2"}],
            "nextToken": "token",
        },
        {"logGroups": [{"logGroupName": "group3"}]},
    ]
    mock_boto_client.return_value = mock_logs_client

    # Call the function
    result = get_log_groups()

    # Assertions
    expected_result = [
        {"logGroupName": "group1"},
        {"logGroupName": "group2"},
        {"logGroupName": "group3"},
    ]
    assert result == expected_result
    assert mock_logs_client.describe_log_groups.call_count == 2


@patch("src.log_exporter.lambda_handler.boto3.client")
def test_to_log_groups_to_export(mock_boto_client):
    mock_logs = MagicMock()
    mock_logs.list_tags_log_group.return_value = {"tags": {"ExportToS3": "true"}}
    mock_boto_client.return_value = mock_logs

    log_groups = [{"logGroupName": "group1"}, {"logGroupName": "group2"}]

    result = to_log_groups_to_export(log_groups)

    assert result == ["group1", "group2"]


@patch("src.log_exporter.lambda_handler.boto3.client")
def test_get_last_export_value(mock_boto_client):
    mock_ssm = MagicMock()
    mock_ssm.get_parameter.return_value = {"Parameter": {"Value": "12345"}}
    mock_boto_client.return_value = mock_ssm

    result = get_last_export_value("test_param")

    assert result == "12345"


@patch("src.log_exporter.lambda_handler.boto3.client")
def test_put_last_export_value(mock_boto_client):
    mock_ssm = MagicMock()
    mock_boto_client.return_value = mock_ssm

    put_last_export_value("test_param", 12345)

    mock_ssm.put_parameter.assert_called_once_with(
        Name="test_param", Type="String", Value="12345", Overwrite=True
    )


def getenv_side_effect(env_name):
    if env_name == "LOGS_BUCKET_NAME":
        return "my-bucket-name"
    elif env_name == "PROJECT_NAME":
        return "quackmeup"


@patch("src.log_exporter.lambda_handler.boto3.client")
@patch("src.log_exporter.lambda_handler.put_last_export_value")
@patch("src.log_exporter.lambda_handler.get_last_export_value")
@patch("src.log_exporter.lambda_handler.time")
@patch("src.log_exporter.lambda_handler.os.getenv")
def test_schedule_exports(
    mock_getenv,
    mock_time,
    mock_get_last_export_value,
    mock_put_last_export_value,
    mock_boto_client,
):
    # Mock AWS services
    mock_logs_client = MagicMock()
    mock_boto_client.return_value = mock_logs_client

    # Prepare mock return values and side effects
    mock_get_last_export_value.return_value = "1234567890"  # Past timestamp
    mock_time.time.return_value = 1234567900  # Current timestamp (10 seconds later)
    groups_to_export = ["group1", "group2"]

    mock_getenv.side_effect = getenv_side_effect

    # Call the function
    schedule_exports(groups_to_export)

    # Assertions
    # Check if get_last_export_value is called for each group
    assert mock_get_last_export_value.call_count == len(groups_to_export)

    # Check if create_export_task is called correctly
    # This assumes the export is needed based on the timestamps
    expected_params = [
        {
            "logGroupName": group,
            "fromTime": int(mock_get_last_export_value.return_value),
            "to": int(mock_time.time.return_value) * 1000,
            "destination": "my-bucket-name",
        }
        for group in groups_to_export
    ]

    # Check each call individually
    for params in expected_params:
        mock_logs_client.create_export_task.assert_any_call(**params)

    # Additionally, ensure the number of calls matches the expected number
    assert mock_logs_client.create_export_task.call_count == len(groups_to_export)

    # Check if put_last_export_value is called for each group with the new timestamp
    assert mock_put_last_export_value.call_count == len(groups_to_export)
    for group in groups_to_export:
        param_name = f"/quackmeup/log-exporter/last-export/{group}".replace("//", "/")
        mock_put_last_export_value.assert_any_call(
            param_name, mock_time.time.return_value * 1000
        )


@patch("src.log_exporter.lambda_handler.schedule_exports")
@patch("src.log_exporter.lambda_handler.to_log_groups_to_export")
@patch("src.log_exporter.lambda_handler.get_log_groups")
def test_lambda_handler(
    mock_get_log_groups, mock_to_log_groups_to_export, mock_schedule_exports
):
    # Mock the return values of the functions
    mock_get_log_groups.return_value = [
        {"logGroupName": "group1"},
        {"logGroupName": "group2"},
    ]
    mock_to_log_groups_to_export.return_value = ["group1", "group2"]

    # Call lambda_handler
    lambda_handler(None, None)

    # Assertions to ensure that each function is called correctly
    mock_get_log_groups.assert_called_once()
    mock_to_log_groups_to_export.assert_called_once_with(
        mock_get_log_groups.return_value
    )
    mock_schedule_exports.assert_called_once_with(
        mock_to_log_groups_to_export.return_value
    )
