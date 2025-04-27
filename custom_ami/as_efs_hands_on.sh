#!/bin/bash

set -e

# CONFIGURATION
AMI_ID="ami-xxxxxxxxxxxxxxxxx"
INSTANCE_TYPE="t2.micro"
KEY_NAME="MyKeyPair"
SECURITY_GROUP_ID="sg-xxxxxxxx"        # SG should allow NFS (2049) + SSH (22)

# 1. Create EFS File System
EFS_ID=$(aws efs create-file-system \
  --creation-token "my-efs-$(date +%s)" \
  --performance-mode generalPurpose \
  --query 'FileSystemId' \
  --output text)

echo "✅ Created EFS: $EFS_ID"

# 2. Get VPC and Subnet IDs
VPC_ID=$(aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text)
SUBNET_IDS=($(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID \
  --query 'Subnets[*].SubnetId' --output text))

echo "✅ Using VPC: $VPC_ID"
echo "✅ Subnets: ${SUBNET_IDS[@]}"

# 3. Create Mount Targets (in first 2 subnets)
for subnet in "${SUBNET_IDS[@]:0:2}"; do
  aws efs create-mount-target \
    --file-system-id "$EFS_ID" \
    --subnet-id "$subnet" \
    --security-groups "$SECURITY_GROUP_ID" &
done
wait

echo "✅ Mount targets created"

# 4. Create Base64-encoded User Data to Mount EFS
USER_DATA=$(base64 <<EOF
#!/bin/bash
yum install -y amazon-efs-utils
mkdir -p /mnt/efs
mount -t efs ${EFS_ID}:/ /mnt/efs
EOF
)

# 5. Launch Two EC2 Instances in Parallel
for i in 0 1; do
  aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --subnet-id "${SUBNET_IDS[$i]}" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --user-data "$USER_DATA" &
done
wait

echo "✅ Launched 2 EC2 instances and attached EFS via user data"
