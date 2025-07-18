#!/bin/bash

# List of subnet IDs
SUBNETS="subnet-0c90db45d723fa622 subnet-0f94e759fb77d53ff subnet-010f7f7b54109a4c6 subnet-025d4a9a756af68bc subnet-0d8d759f09a854589 subnet-0e0ee8ece5a12c8c8 subnet-02b4929a51c291b56 subnet-0708a4500a7496c96 subnet-0e8ee05f2d466b1e3 subnet-03ebdc111e1e73882 subnet-0b4e76c5d4f5d043c subnet-0604f42bf04a0a46d subnet-00c1ee2d4c5498aac subnet-0047a9e65a4ce3f5f subnet-06bee2f8284c4a188"

# Region
REGION="eu-north-1"

# Function to check for dependencies
check_dependencies() {
  local subnet_id=$1

  # Check for running EC2 instances
  instances=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=subnet-id,Values=$subnet_id" "Name=instance-state-name,Values=running,pending" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text)

  # Check for network interfaces
  network_interfaces=$(aws ec2 describe-network-interfaces \
    --region "$REGION" \
    --filters "Name=subnet-id,Values=$subnet_id" \
    --query 'NetworkInterfaces[].NetworkInterfaceId' \
    --output text)

  if [ -n "$instances" ] || [ -n "$network_interfaces" ]; then
    echo "Cannot delete subnet $subnet_id due to dependencies:"
    [ -n "$instances" ] && echo " - EC2 Instances: $instances"
    [ -n "$network_interfaces" ] && echo " - Network Interfaces: $network_interfaces"
    return 1
  fi
  return 0
}

# Function to delete a subnet
delete_subnet() {
  local subnet_id=$1
  echo "Attempting to delete subnet $subnet_id..."
  if aws ec2 delete-subnet --region "$REGION" --subnet-id "$subnet_id" 2>/dev/null; then
    echo "Successfully deleted subnet $subnet_id"
  else
    echo "Failed to delete subnet $subnet_id (possible dependency or permissions issue)"
    return 1
  fi
}

# Main loop to process each subnet
for subnet_id in $SUBNETS; do
  if check_dependencies "$subnet_id"; then
    delete_subnet "$subnet_id"
  else
    echo "Skipping deletion of $subnet_id due to dependencies"
  fi
done

echo "Subnet deletion process completed."
