from unittest.mock import MagicMock, patch

from src.log_exporter.lambda_handler import (
    get_last_export_value,
    get_log_groups,
    get_s3_bucket,
    put_last_export_value,
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


# @patch('boto3.client')
# def test_to_log_groups_to_export(mock_boto_client):
#   mock_logs = MagicMock()
#   mock_logs.list_tags_log_group.return_value = {"tags": {"ExportToS3": "true"}}
#   mock_boto_client.return_value = mock_logs

#   log_groups = [{"logGroupName": "group1"}, {"logGroupName": "group2"}]

#   result = to_log_groups_to_export(log_groups)

#   assert result == ["group1", "group2"]

# @patch('os.getenv')
# def test_get_s3_bucket(mock_getenv):
#   mock_getenv.return_value = "test_bucket"

#   result = get_s3_bucket()

#   assert result == "test_bucket"

# @patch('boto3.client')
# def test_get_last_export_value(mock_boto_client):
#   mock_ssm = MagicMock()
#   mock_ssm.get_parameter.return_value = {"Parameter": {"Value": "12345"}}
#   mock_boto_client.return_value = mock_ssm

#   result = get_last_export_value("test_param")

#   assert result == "12345"

# @patch('boto3.client')
# def test_put_last_export_value(mock_boto_client):
#   mock_ssm = MagicMock()
#   mock_boto_client.return_value = mock_ssm

#   put_last_export_value("test_param", 12345)

#   mock_ssm.put_parameter.assert_called_once_with(Name="test_param", Type="String", Value="12345", Overwrite=True)

# @patch('src.lambda_handler.get_s3_bucket')
# @patch('src.lambda_handler.get_log_groups')
# @patch('src.lambda_handler.to_log_groups_to_export')
# @patch('src.lambda_handler.get_last_export_value')
# @patch('src.lambda_handler.put_last_export_value')
# @patch('src.lambda_handler.export_logs_to_s3')
# def test_lambda_handler(mock_export_logs_to_s3, mock_put_last_export_value, mock_get_last_export_value, mock_to_log_groups_to_export, mock_get_log_groups, mock_get_s3_bucket):
#     mock_get_s3_bucket.return_value = 'test_bucket'
#     mock_get_log_groups.return_value = ['group1', 'group2', 'group3']
#     mock_to_log_groups_to_export.return_value = ['group1', 'group2']
#     mock_get_last_export_value.return_value = '12345'

#     lambda_handler.lambda_handler(None, None)

#     mock_get_s3_bucket.assert_called_once()
#     mock_get_log_groups.assert_called_once()
#     mock_to_log_groups_to_export.assert_called_once_with(['group1', 'group2', 'group3'])
#     mock_get_last_export_value.assert_called_once_with('group1')
#     mock_put_last_export_value.assert_called_once_with('group1', ANY)
#     mock_export_logs_to_s3.assert_called_once_with('group1', 'test_bucket', '12345', ANY)
