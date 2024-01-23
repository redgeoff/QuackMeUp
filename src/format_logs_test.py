import gzip

from src.format_logs import extract_json_part, format_logs, is_json, process_file


def test_extract_json_part():
    line = '2022-01-01T12:00:00Z {"key": "value"}'
    expected = '{"key": "value"}'
    assert extract_json_part(line) == expected


def test_is_json():
    json_part = '{"key": "value"}'
    assert is_json(json_part) == True

    non_json_part = "not a json string"
    assert is_json(non_json_part) == False


def test_process_file(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    output_dir.mkdir()

    file_path = input_dir / "test.gz"
    with gzip.open(file_path, "wt", encoding="utf-8") as f:
        f.write('2022-01-01T12:00:00Z {"key": "value"}\n')

    process_file(str(file_path), str(output_dir), str(input_dir))

    output_file_path = output_dir / "test.json"
    with open(output_file_path, "r", encoding="utf-8") as f:
        assert f.read() == '{"key": "value"}\n'


def test_format_logs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    output_dir.mkdir()

    file_path = input_dir / "test.gz"
    with gzip.open(file_path, "wt", encoding="utf-8") as f:
        f.write('2022-01-01T12:00:00Z {"key": "value"}\n')

    format_logs(str(input_dir), str(output_dir))

    output_file_path = output_dir / "test.json"
    with open(output_file_path, "r", encoding="utf-8") as f:
        assert f.read() == '{"key": "value"}\n'
