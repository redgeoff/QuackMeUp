from src.format_logs import format_logs


def test_format_logs():
    assert format_logs() == "formatted logs"
