#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

image_uri="${1}"

regex="([^\/]+)\/([^:]+):([^\/]+)$"

if [[ $image_uri =~ $regex ]]; then
    registry="${BASH_REMATCH[1]}"
    repo_name="${BASH_REMATCH[2]}"
    tag="${BASH_REMATCH[3]}"
    output="{ \"registry\": \"$registry\", \"repo_name\": \"${repo_name}\", \"tag\": \"${tag}\" }"
    echo "${output}"
else
    echo "Error: the provided string does not match the expected format."
    exit 1
fi
