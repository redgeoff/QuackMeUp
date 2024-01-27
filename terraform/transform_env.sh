#!/bin/bash

# Load the .env file
set -a
source ../.env
set +a

# Read the .env file line by line
while IFS='=' read -r key value; do
    # Check if the line is not empty and does not start with a #
    if [[ ! -z "$key" && ! "$key" =~ ^# ]]; then
        # Remove wrapping double quotes from value
        value="${value#\"}"
        value="${value%\"}"

        # Remove wrapping single quotes from value
        value="${value#\'}"
        value="${value%\'}"

        # Prepare the new variable name with TF_VAR_ prefix
        new_var_name="TF_VAR_$key"

        # Export the variable with the new name
        export "$new_var_name"="$value"

        # Optionally, you can echo the variable for debugging
        # echo "$new_var_name=$value"
    fi
done < ../.env
