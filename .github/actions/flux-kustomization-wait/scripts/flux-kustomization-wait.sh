#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-300}"
START_TIME=$(date +%s)

while true; do
  CURRENT_TIME=$(date +%s)
  ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
  [ "${ELAPSED_TIME}" -ge "${TIMEOUT_SECONDS}" ] && break
  KUSTOMIZATION_STATUS=$(
      flux get kustomization "${NAME}" \
          --namespace "${NAMESPACE}" \
          --no-header | \
      cut -d $'\t' -f 4
  )
  [ "${KUSTOMIZATION_STATUS}" = "True" ] && { echo "ok" && exit 0; }
done
echo "Kustomization reconciliation failed with status: ${KUSTOMIZATION_STATUS}"
exit 1
