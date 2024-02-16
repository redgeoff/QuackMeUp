lint:
	poetry run pylint src

mypy:
	poetry run mypy src

test:
	poetry run pytest $(ARGS)

ci:
	make lint && make mypy && make test

format_logs:
	poetry run python -m src.format_logs

format_logs_parquet:
	poetry run python -m src.format_logs_parquet

build_docker:
	docker build -t quackmeup .

log_exporter:
	poetry run python -m src.log_exporter.lambda_handler

query_duckdb:
	poetry run python -m src.query_duckdb