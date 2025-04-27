#!/bin/bash

set -euo pipefail

# ----------------------------
# CONFIGURATION
# ----------------------------
LOG_DIR="/opt/logs"
TMP_DIR="/tmp"
DATE_YESTERDAY=$(date -d "yesterday" '+%Y-%m-%d')
ARCHIVE_NAME="logs_$DATE_YESTERDAY.zip"
ARCHIVE_PATH="$TMP_DIR/$ARCHIVE_NAME"
S3_BUCKET="your-s3-bucket-name"
S3_KEY="logs/$ARCHIVE_NAME"
AWS_CLI_PROFILE="default"

# ----------------------------
# LOGGING
# ----------------------------
log_info() {
  echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# ----------------------------
# MAIN
# ----------------------------
log_info "Looking for files containing '$DATE_YESTERDAY' in filename..."

FILES=$(find "$LOG_DIR" -type f -name "*$DATE_YESTERDAY*")

if [ -z "$FILES" ]; then
  log_info "No files found with date $DATE_YESTERDAY in filename. Exiting."
  exit 0
fi

log_info "Compressing files into $ARCHIVE_PATH..."
zip -j "$ARCHIVE_PATH" $FILES

log_info "Uploading $ARCHIVE_NAME to s3://$S3_BUCKET/$S3_KEY..."
aws s3 cp "$ARCHIVE_PATH" "s3://$S3_BUCKET/$S3_KEY" --profile "$AWS_CLI_PROFILE"

log_info "Upload successful. Cleaning up..."
rm -f "$ARCHIVE_PATH"

log_info "Done."
