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

build_docker:
	docker build -t quackmeup .