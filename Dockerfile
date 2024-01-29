# When building on an Apple M2 chip, the platform is required
FROM --platform=linux/amd64 public.ecr.aws/lambda/python:3.11

RUN pip install poetry

COPY ./poetry.lock ./pyproject.toml ${LAMBDA_TASK_ROOT}/

WORKDIR ${LAMBDA_TASK_ROOT}

RUN poetry config virtualenvs.create false
RUN poetry install --no-interaction --no-ansi

# Note: we copy the src at the end as it it most likely to change often and we don't want to have to
# rebuild the above layers each time it changes
COPY . ${LAMBDA_TASK_ROOT}/

# Run the application:
CMD ["src.log_exporter.lambda_handler.lambda_handler"]