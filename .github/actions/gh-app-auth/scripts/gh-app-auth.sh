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

GITHUB_APP_ID="${GITHUB_APP_ID:-}"
GITHUB_APP_CLIENT_ID="${GITHUB_APP_CLIENT_ID:-}"
GITHUB_APP_PRV_KEY_PATH="${GITHUB_APP_PRV_KEY_PATH:-}"

EXPIRATION_SECONDS="${EXPIRATION_SECONDS:-600}" # default 10 minutes
ISSUE_START_SECONDS="${ISSUE_START_SECONDS:-60}" # default 60 seconds in the past
ALGORITHM="${ALGORITHM:-RS256}"

err_log() {
  >&2 echo "${1}"
}

iss="${GITHUB_APP_CLIENT_ID}"

[ -z "${iss}" ] && {
  # fallback to GITHUB_APP_ID
  iss="${GITHUB_APP_ID}"
}

[ -z "${iss}" ] && {
  err_log "error: GITHUB_APP_ID or GITHUB_APP_CLIENT_ID must be set"
  exit 1
}

[ ! -f "${GITHUB_APP_PRV_KEY_PATH}" ] && {
  err_log "error: GITHUB_APP_PRV_KEY_PATH must refer to a file"
  exit 1
}

if ! command -v openssl &> /dev/null; then
  err_log "error: openssl must be present to run this script"
  exit 1
fi

if ! command -v curl &> /dev/null; then
  err_log "error: curl must be present to run this script"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  err_log "error: jq must be present to run this script"
  exit 1
fi

if ! command -v gh &> /dev/null; then
  err_log "error: gh must be present to run this script"
  err_log "install from https://cli.github.com/"
  exit 1
fi

secret=$(cat "${GITHUB_APP_PRV_KEY_PATH}")

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

GITHUB_JWT="${content}.${signature}"
BEARER="Authorization: Bearer ${GITHUB_JWT}"
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

export GITHUB_TOKEN=$(
    curl \
        --request POST \
        --silent \
        --header "${ACCEPT}" \
        --header "${BEARER}" \
        "${APP_TOKEN_URL}" | \
    jq --raw-output '.token'
)

# side effect: set up git to pull / push with the generated token
gh auth setup-git
