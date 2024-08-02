#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

REPO_NAME="${1}"
EXISTING_TAG="${2}"
NEW_TAG="${3}"

MANIFEST=$(
  aws ecr batch-get-image \
      --repository-name "${REPO_NAME}" \
      --image-ids imageTag="${EXISTING_TAG}" \
      --query 'images[].imageManifest' \
      --output text
)

aws ecr put-image \
    --repository-name "${REPO_NAME}" \
    --image-manifest "${MANIFEST}" \
    --image-tag "${NEW_TAG}"
