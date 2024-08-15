#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

## Credits:

## Script adapted from:

## Dobes Vandermeer (@dobesv)
## https://github.com/cli/cli/discussions/5081#discussioncomment-5797413

## And GitHub:
## https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app

GH_APP_OR_CLIENT_ID="${GH_APP_OR_CLIENT_ID:-}"
GH_APP_PRV_KEY_PATH="${GH_APP_PRV_KEY_PATH:-}"

EXPIRATION_SECONDS="${EXPIRATION_SECONDS:-600}" # default 10 minutes
ISSUE_START_SECONDS="${ISSUE_START_SECONDS:-60}" # default 60 seconds in the past
ALGORITHM="${ALGORITHM:-RS256}"

err_log() {
  >&2 echo "${1}"
}

check_cmd() {
  if ! command -v "${1}" &> /dev/null; then
    err_log "error: ${1} command is missing; you must check how to install it"
    exit 1
  fi
}

[ -z "${GH_APP_OR_CLIENT_ID}" ] && {
  err_log "error: GH_APP_OR_CLIENT_ID must be set"
  exit 1
}

[ ! -f "${GH_APP_PRV_KEY_PATH}" ] && {
  err_log "error: GH_APP_PRV_KEY_PATH must refer to a file"
  exit 1
}

check_cmd openssl
check_cmd curl
check_cmd jq

iss="${GH_APP_OR_CLIENT_ID}"
secret=$(cat "${GH_APP_PRV_KEY_PATH}")

now=$(date +%s)
iat=$((${now} - ${ISSUE_START_SECONDS})) # Issues x seconds in the past
exp=$((${now} + ${EXPIRATION_SECONDS})) # Expires x seconds in the future


b64enc() { openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'; }

header_json='{
    "typ":"JWT",
    "alg":"'${ALGORITHM}'"
}'

payload_json='{
    "iat":'${iat}',
    "exp":'${exp}',
    "iss":"'${iss}'"
}'

header=$( echo -n "${header_json}" | b64enc )
payload=$( echo -n "${payload_json}" | b64enc )

content="${header}.${payload}"
signature=$(
    openssl \
        dgst \
        -sha256 \
        -sign \
        <(echo -n "${secret}") \
        <(echo -n "${content}") | \
    b64enc
)

GH_JWT="${content}.${signature}"
BEARER="Authorization: Bearer ${GH_JWT}"
ACCEPT="Accept: application/vnd.github.v3+json"
INSTALLATIONS_API_URL="https://api.github.com/app/installations"

# Request installation information;
# this assumes there's just one
# installation (this is a private GitHub app);
# if you have multiple installations you'll have to
# customize this to pick out the installation
# you're interested in

APP_TOKEN_URL=$(
    curl \
        --silent \
        --header "${ACCEPT}" \
        --header "${BEARER}" \
        "${INSTALLATIONS_API_URL}" | \
    jq --raw-output '.[0].access_tokens_url' # single installation
)

GH_TOKEN=$(
    curl \
        --request POST \
        --silent \
        --header "${ACCEPT}" \
        --header "${BEARER}" \
        "${APP_TOKEN_URL}" | \
    jq --raw-output '.token'
)

echo "${GH_TOKEN}"
