#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

NAME="${1}"
VALUE="${2}"
TYPE="${3:-SecureString}"

# Using JSON to overcome the bug of urls in the value
# See: https://stackoverflow.com/questions/53092997/saving-a-url-to-aws-parameter-store-with-aws-cli
JSON="{
  \"Name\": \"${NAME}\",
  \"Value\": \"${VALUE}\",
  \"Type\": \"${TYPE}\"
}"

aws ssm put-parameter \
  --cli-input-json "${JSON}" \
  --overwrite
