lint:
	poetry run pylint src

mypy:
	poetry run mypy src

test:
	poetry run pytest

ci:
	make lint && make mypy && make test

format_logs:
	poetry run python src/format_logs.py