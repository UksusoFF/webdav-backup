#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

FILES_LIST="${SCRIPT_DIR}/include.list"
DOCKER_LIST="${SCRIPT_DIR}/docker.list"

if [ ! -f "${SCRIPT_DIR}/config.sh" ]; then
  cp "${SCRIPT_DIR}/config.sh.example" "${SCRIPT_DIR}/config.sh"
  cp "${SCRIPT_DIR}/include.list.example" "$FILES_LIST"
  touch "${SCRIPT_DIR}/previous.list"
  echo "Place your credentials to config.sh and file paths to include.list"
  exit 1
fi

source "${SCRIPT_DIR}/config.sh"

echo "Local available space: $(df -h . | awk 'END {print $4}')"
echo "Local used space: $(df -h . | awk 'END {print $5}')"

#REMOTE_SPACE_INFO=$(curl -i --request PROPFIND --header "Depth: 0" --data-ascii "<D:propfind xmlns:D=\"DAV:\"><D:prop><D:quota-available-bytes/><D:quota-used-bytes/></D:prop></D:propfind>" --user "${WEB_DAV_USER}":"${WEB_DAV_PASS}" --digest "${WEB_DAV_URL}" --silent --show-error)
#REMOTE_AVAILABLE_SPACE=$(grep -oPm1 "(?<=<d:quota-available-bytes>)[^<]+" <<<"$REMOTE_SPACE_INFO" | awk '{ byte =$1 /1024/1024/1024; print byte " GB" }')

#echo "Remote available space: $REMOTE_AVAILABLE_SPACE"

WEBDAV_FOLDER="${WEB_DAV_URL}/${ARC_FOLDER_NAME}"

RESULT=$(curl -i --request MKCOL --user "${WEB_DAV_USER}":"${WEB_DAV_PASS}" --digest "${WEBDAV_FOLDER}" --silent --show-error --write-out '%{http_code}' --output /dev/null)

if [ "${RESULT}" == "201" ]; then
  echo "Created: ${WEBDAV_FOLDER}"
else
  echo "Failed: ${WEBDAV_FOLDER}"
  exit 1
fi

if [ -f "${FILES_LIST}" ]; then
  bash "${SCRIPT_DIR}/_src_files.sh" "${WEBDAV_FOLDER}"
fi

if [ -f "${DOCKER_LIST}" ]; then
  bash "${SCRIPT_DIR}/_src_docker.sh" "${WEBDAV_FOLDER}"
fi

if [ -n "$(which mysqldump)" ]; then
  bash "${SCRIPT_DIR}/_src_mysql.sh" "${WEBDAV_FOLDER}"
fi

if [ -n "$(which psql)" ]; then
  bash "${SCRIPT_DIR}/_src_psql.sh" "${WEBDAV_FOLDER}"
fi

echo "${ARC_FOLDER_NAME}" >>"${SCRIPT_DIR}/previous.list"

head -n -"${ARC_MAX}" "${SCRIPT_DIR}/previous.list" | while read LAST_BACKUP_NAME; do
  RESULT=$(curl -i --request DELETE --user "${WEB_DAV_USER}":"${WEB_DAV_PASS}" --digest "${WEB_DAV_URL}/${LAST_BACKUP_NAME}/" --silent --show-error --write-out '%{http_code}' --output /dev/null)

  if [ "${RESULT}" == "204" ]; then
    echo "Deleted: $(basename "${LAST_BACKUP_NAME}")"
  else
    echo "Failed: $(basename "${LAST_BACKUP_NAME}")"
    exit 1
  fi

  sed -i "/^${LAST_BACKUP_NAME}$/d" "${SCRIPT_DIR}/previous.list"
done

# Get file list in remote folder. Not used now.
# curl -i --request PROPFIND --header "Depth: 1" --user ${WEB_DAV_USER}:${WEB_DAV_PASS} ${WEB_DAV_URL}/${ARC_FOLDER_NAME}
