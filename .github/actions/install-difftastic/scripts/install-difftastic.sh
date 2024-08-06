#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if ! command -v curl &> /dev/null; then
  >&2 echo "error: curl must be installed"
  exit 1
fi

if ! command -v tar &> /dev/null; then
  >&2 echo "error: tar must be installed"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  >&2 echo "error: jq must be installed"
  exit 1
fi

# https://github.com/Wilfred/difftastic/releases

BIN_NAME="difft"
TARGETOS="linux"
TARGETARCH="amd64"

REPO="Wilfred/difftastic"

if [ "${TARGETOS}" == "linux" ]; then OS_SUFFIX="unknown-linux-gnu"; fi
if [ "${TARGETOS}" == "darwin" ]; then OS_SUFFIX="apple-darwin"; fi
if [ "${TARGETARCH}" == "amd64" ]; then ARCH="x86_64"; fi
if [ "${TARGETARCH}" == "arm64" ]; then ARCH="aarch64"; fi

TARBALL_URL=$(curl --silent "https://api.github.com/repos/${REPO}/releases/latest" | jq -r .tarball_url)
VERSION=$(grep -o '[^/v]*$' <<< "${TARBALL_URL}")
FILE_NAME="${BIN_NAME}-${ARCH}-${OS_SUFFIX}.tar.gz"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${FILE_NAME}"

TMP_DIR="$(mktemp -d -t ${BIN_NAME}.XXXXXXXXX)"
TMP_FILE="${TMP_DIR}/${FILE_NAME}"

function finish {
  rm -rf "${TMP_DIR}"
}

trap finish EXIT

INSTALL_PATH="${HOME}/.local/bin"
mkdir -p "${INSTALL_PATH}"

curl --silent --location --output "${TMP_FILE}" "${DOWNLOAD_URL}"
tar -xzf "${TMP_FILE}" --directory "${TMP_DIR}"

install "${TMP_DIR}/${BIN_NAME}" "${INSTALL_PATH}"
