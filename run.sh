#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

if [ ! -f "$SCRIPT_DIR/config.sh" ]; then
  cp "$SCRIPT_DIR/config.sh.example" "$SCRIPT_DIR/config.sh"
  cp "$SCRIPT_DIR/include.list.example" "$SCRIPT_DIR/include.list"
  touch "$SCRIPT_DIR/previous.list"
  echo "Place your credentials to config.sh and file paths to include.list"
  exit 1
fi

source "$SCRIPT_DIR/config.sh"

ARCFOLDERNAME="${FOLDER_PREFIX}_$(date '+%F_%H_%M')"

echo "Local available space: $(df -h . | awk 'END {print $4}')"
echo "Local used space: $(df -h . | awk 'END {print $5}')"

#REMOTE_SPACE_INFO=$(curl -i --request PROPFIND --header "Depth: 0" --data-ascii "<D:propfind xmlns:D=\"DAV:\"><D:prop><D:quota-available-bytes/><D:quota-used-bytes/></D:prop></D:propfind>" --user "$WEB_DAV_USER":"$WEB_DAV_PASS" --digest "$WEB_DAV_URL" --silent --show-error)
#REMOTE_AVAILABLE_SPACE=$(grep -oPm1 "(?<=<d:quota-available-bytes>)[^<]+" <<<"$REMOTE_SPACE_INFO" | awk '{ byte =$1 /1024/1024/1024; print byte " GB" }')

#echo "Remote available space: $REMOTE_AVAILABLE_SPACE"

WEBDAV_FOLDER="${WEB_DAV_URL}/${ARCFOLDERNAME}"

RESULT=$(curl -i --request MKCOL --user "$WEB_DAV_USER":"$WEB_DAV_PASS" --digest "$WEBDAV_FOLDER" --silent --show-error --write-out '%{http_code}' --output /dev/null)

if [ "$RESULT" == "201" ]; then
  echo "Created: $WEBDAV_FOLDER"
else
  echo "Failed: $WEBDAV_FOLDER"
  exit 1
fi

for FILES_DIR in $(cat "$SCRIPT_DIR/include.list"); do
  ARCHIVE_NAME=$(basename "$(dirname "$FILES_DIR")")_$(basename "$FILES_DIR")_files.tar.gz

  ARCHIVE_PATH=$SCRIPT_DIR/$ARCHIVE_NAME

  tar cfz "$ARCHIVE_PATH" --exclude-from="$SCRIPT_DIR/exclude.list" -C "$FILES_DIR" .

  RESULT=$(curl --user "$WEB_DAV_USER":"$WEB_DAV_PASS" --digest -T "$ARCHIVE_PATH" "$WEBDAV_FOLDER/$ARCHIVE_NAME" --silent --show-error --write-out '%{http_code}' --output /dev/null)

  if [ "$RESULT" == "201" ]; then
    echo "Uploaded: $(basename "$ARCHIVE_PATH")"
  else
    echo "Failed: $(basename "$ARCHIVE_PATH")"
    exit 1
  fi

  rm "$ARCHIVE_PATH"
done

mysql -N -e "SHOW DATABASES;" | grep -v -E "performance_schema|information_schema|mysql|afterlogic|sys" | while read DB; do
  ARCHIVE_NAME=${DB}_db.sql.gz

  ARCHIVE_PATH=$SCRIPT_DIR/$ARCHIVE_NAME

  mysqldump "$DB" | gzip >"$ARCHIVE_PATH"

  RESULT=$(curl --user "$WEB_DAV_USER":"$WEB_DAV_PASS" --digest -T "$ARCHIVE_PATH" "$WEBDAV_FOLDER/$ARCHIVE_NAME" --silent --show-error --write-out '%{http_code}' --output /dev/null)

  if [ "$RESULT" == "201" ]; then
    echo "Uploaded: $(basename "$ARCHIVE_PATH")"
  else
    echo "Failed: $(basename "$ARCHIVE_PATH")"
    exit 1
  fi

  rm "$ARCHIVE_PATH"
done

su -c "psql -qAtX -c \"SELECT datname FROM pg_database;\"" postgres | grep -v -E "postgres|template0|template1" | while read DB; do
  ARCHIVE_NAME=${DB}_pg.sql.gz

  ARCHIVE_PATH=$SCRIPT_DIR/$ARCHIVE_NAME

  mysqldump "$DB" | gzip >"$ARCHIVE_PATH"

  RESULT=$(curl --user "$WEB_DAV_USER":"$WEB_DAV_PASS" --digest -T "$ARCHIVE_PATH" "$WEBDAV_FOLDER/$ARCHIVE_NAME" --silent --show-error --write-out '%{http_code}' --output /dev/null)

  if [ "$RESULT" == "201" ]; then
    echo "Uploaded: $(basename "$ARCHIVE_PATH")"
  else
    echo "Failed: $(basename "$ARCHIVE_PATH")"
    exit 1
  fi

  rm "$ARCHIVE_PATH"
done

echo "$ARCFOLDERNAME" >>"$SCRIPT_DIR/previous.list"

head -n -"$ARC_MAX" "$SCRIPT_DIR/previous.list" | while read LASTBACKUPNAME; do
  RESULT=$(curl -i --request DELETE --user "$WEB_DAV_USER":"$WEB_DAV_PASS" --digest "$WEB_DAV_URL/$LASTBACKUPNAME/" --silent --show-error --write-out '%{http_code}' --output /dev/null)

  if [ "$RESULT" == "204" ]; then
    echo "Deleted: $(basename "$LASTBACKUPNAME")"
  else
    echo "Failed: $(basename "$LASTBACKUPNAME")"
    exit 1
  fi

  sed -i "/^$LASTBACKUPNAME$/d" "$SCRIPT_DIR/previous.list"
done

# Get file list in remote folder. Not used now.
# curl -i --request PROPFIND --header "Depth: 1" --user $WEB_DAV_USER:$WEB_DAV_PASS $WEB_DAV_URL/$ARCFOLDERNAME
