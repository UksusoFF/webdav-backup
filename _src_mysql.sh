#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

source "${SCRIPT_DIR}/config.sh"

WEBDAV_FOLDER="${1}"

mysql -N -e "SHOW DATABASES;" | grep -v -E "performance_schema|information_schema|mysql|afterlogic|sys" | while read DB; do
  ARCHIVE_NAME=${DB}_db.sql.gz

  ARCHIVE_PATH="${SCRIPT_DIR}/${ARCHIVE_NAME}"

  mysqldump "${DB}" | gzip >"${ARCHIVE_PATH}"

  RESULT=$(curl --user "${WEB_DAV_USER}":"${WEB_DAV_PASS}" --digest -T "${ARCHIVE_PATH}" "${WEBDAV_FOLDER}/${ARCHIVE_NAME}" --silent --show-error --write-out '%{http_code}' --output /dev/null)

  if [ "${RESULT}" == "201" ]; then
    echo "Uploaded: $(basename "${ARCHIVE_PATH}")"
  else
    echo "Failed: $(basename "${ARCHIVE_PATH}")"
    exit 1
  fi

  rm "${ARCHIVE_PATH}"
done
