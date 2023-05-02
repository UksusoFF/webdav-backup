#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

source "${SCRIPT_DIR}/config.sh"

FILE_NAME="${1}"
TARGET="${2}"

echo "${FILE_NAME}"
echo "${WEB_DAV_USER}"
wget --user "${WEB_DAV_USER}" --password "${WEB_DAV_PASS}" "${WEB_DAV_URL}/${FILE_NAME}" -O - | tar xvz -C "${TARGET}"
