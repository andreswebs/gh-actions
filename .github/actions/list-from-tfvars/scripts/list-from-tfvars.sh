#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

input_tfvars_file="${1}"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file_name>"
    exit 1
fi

if [ ! -f "${input_tfvars_file}" ]; then
    echo "Error: File '${input_tfvars_file}' not found."
    exit 1
fi

values=()

while IFS= read -r line; do
    value=$(echo "${line}" | awk -F '"' '{print $2}')
    if [ -n "${value}" ]; then
        values+=("${value}")
    fi
done < "${input_tfvars_file}"

json_list=$(printf '"%s", ' "${values[@]}")
json_list="[${json_list%, }]"

echo "${json_list}"
