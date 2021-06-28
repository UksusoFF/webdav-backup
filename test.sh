#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

source "$SCRIPT_DIR/config.sh"

ARCFOLDERNAME="${FOLDER_PREFIX}_$(date '+%F_%H_%M')"

WEBDAV_FOLDER="${WEB_DAV_URL}/${ARCFOLDERNAME}"

RESULT=$(curl -i --request MKCOL --user "$WEB_DAV_USER":"$WEB_DAV_PASS" --digest "$WEBDAV_FOLDER" --silent --show-error --write-out '%{http_code}' --output /dev/null)

if [ "$RESULT" == "201" ]; then
  echo "Created: $WEBDAV_FOLDER"
else
  echo "Failed: $WEBDAV_FOLDER"
  exit 1
fi