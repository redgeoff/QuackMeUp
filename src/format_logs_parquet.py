import gzip
import json
import os

import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

from src.dirs import ignored_dir


def extract_json_part(line: str) -> str:
    # Assuming JSON part starts after the first space following the timestamp
    parts = line.split(" ", 1)
    return parts[1] if len(parts) > 1 else ""


def is_json(json_part: str) -> bool:
    if not json_part:
        return False
    try:
        json.loads(json_part)
        return True
    except ValueError:
        return False


def process_file(file_path: str, output_dir: str, input_dir: str) -> None:
    print(f"Processing {file_path}")
    relative_path: str = os.path.relpath(file_path, start=input_dir)
    output_file_path: str = (
        os.path.splitext(os.path.join(output_dir, relative_path))[0] + ".parquet"
    )
    output_file_dir: str = os.path.dirname(output_file_path)

    if not os.path.exists(output_file_dir):
        os.makedirs(output_file_dir)

    # Initialize an empty PyArrow Table
    table = None

    with gzip.open(file_path, "rt", encoding="utf-8") as f_in, open(
        output_file_path, "w", encoding="utf-8"
    ) as f_out:
        for line in f_in:
            json_part = extract_json_part(line.strip())
            if is_json(json_part):
                # Convert the JSON part to a DataFrame, then to a PyArrow Table
                json_str = json.dumps(json_part)

                # Create a DataFrame with a single column named "json"
                df = pd.DataFrame([json_str], columns=["json"])

                new_table = pa.Table.from_pandas(df)

                if table is None:
                    table = new_table
                else:
                    # Concatenate the new table with the existing one
                    table = pa.concat_tables([table, new_table])

    # Write the final table to a Parquet file
    if table is not None:
        pq.write_table(table, output_file_path)


def format_logs(input_dir: str, output_dir: str) -> None:
    for root, _dirs, files in os.walk(input_dir):
        for file in files:
            if file.endswith(".gz"):
                file_path: str = os.path.join(root, file)
                process_file(file_path, output_dir, input_dir)


if __name__ == "__main__":
    input_dir = os.path.join(ignored_dir, "logs")
    output_dir = os.path.join(ignored_dir, "formatted_logs_parquet")
    format_logs(input_dir, output_dir)
