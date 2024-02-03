"""
An example of how to query DuckDB using the Python API.
"""

import os

import duckdb

from src.dirs import root_dir

DUCKDB_FILE = os.getenv("DUCKDB_FILE")
assert DUCKDB_FILE, "Please set the DUCKDB_FILE environment variable."

input_path = os.path.join(root_dir, DUCKDB_FILE)

with duckdb.connect(input_path) as con:
    # TODO: replace with query specific to your dataset
    con.sql("SELECT * FROM logs LIMIT 10").show()
