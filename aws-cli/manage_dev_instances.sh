#!/bin/bash

set -euo pipefail

# ----------------------------
# CONFIGURATION
# ----------------------------
AWS_PROFILE="default"  # Change if using a different named profile
REGION="us-east-1"     # Change to your AWS region
TAG_KEY="Environment"
TAG_VALUE="dev"
ACTION="${1:-}"        # Accept "start" or "stop" as first argument

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
# FUNCTION TO GET INSTANCE IDS
# ----------------------------
get_instance_ids() {
  aws ec2 describe-instances \
    --profile "$AWS_PROFILE" \
    --region "$REGION" \
    --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" "Name=instance-state-name,Values=running,stopped" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text
}

# ----------------------------
# START OR STOP INSTANCES
# ----------------------------
manage_instances() {
  local action="$1"

  instance_ids=$(get_instance_ids)

  if [ -z "$instance_ids" ]; then
    log_info "No instances found with tag $TAG_KEY=$TAG_VALUE"
    exit 0
  fi

  if [ "$action" = "stop" ]; then
    log_info "Stopping instances: $instance_ids"
    aws ec2 stop-instances --instance-ids $instance_ids --profile "$AWS_PROFILE" --region "$REGION"
  elif [ "$action" = "start" ]; then
    log_info "Starting instances: $instance_ids"
    aws ec2 start-instances --instance-ids $instance_ids --profile "$AWS_PROFILE" --region "$REGION"
  else
    log_error "Invalid action: $action. Use 'start' or 'stop'."
    exit 1
  fi
}

# ----------------------------
# MAIN
# ----------------------------
if [ -z "$ACTION" ]; then
  log_error "Usage: $0 <start|stop>"
  exit 1
fi

manage_instances "$ACTION"


#Setup a cronjob now
# Stop every Friday at 9 PM
#0 21 * * 5 /path/to/manage_dev_instances.sh stop >> /var/log/dev_instance_stop.log 2>&1

# Start every Monday at 6 AM
#0 6 * * 1 /path/to/manage_dev_instances.sh start >> /var/log/dev_instance_start.log 2>&1
