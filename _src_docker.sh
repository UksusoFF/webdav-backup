#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

source "${SCRIPT_DIR}/config.sh"

WEBDAV_FOLDER="${1}"

for DOCKER_DIR in $(cat "${SCRIPT_DIR}/docker.list"); do
  cd ${DOCKER_DIR}

  ARCHIVE_NAME=$(basename "$(dirname "$DOCKER_DIR")")_$(basename "$DOCKER_DIR")_DOCKER.tar.gz

  ARCHIVE_PATH="${SCRIPT_DIR}/${ARCHIVE_NAME}"

  docker compose down

  tar cfz "${ARCHIVE_PATH}" --exclude-from="${SCRIPT_DIR}/exclude.list" -C "$DOCKER_DIR" .

  RESULT=$(curl --user "${WEB_DAV_USER}":"${WEB_DAV_PASS}" --digest -T "${ARCHIVE_PATH}" "${WEBDAV_FOLDER}/${ARCHIVE_NAME}" --silent --show-error --write-out '%{http_code}' --output /dev/null)

  if [ "${RESULT}" == "201" ]; then
    echo "Uploaded: $(basename "${ARCHIVE_PATH}")"
  else
    echo "Failed: $(basename "${ARCHIVE_PATH}")"
    exit 1
  fi

  docker compose up -d

  rm "${ARCHIVE_PATH}"
done
