#!/bin/bash

# List of route table IDs
ROUTE_TABLES="rtb-05bd2ddeb93c5c76b rtb-0d9f9bf16adbc9332 rtb-09ab8667c5def4303 rtb-095c712b4eb19cf35 rtb-02fa12976f2cc4d61 rtb-0f4d194ea502101a9 rtb-0913bbbb19f6b4c37 rtb-06cc8e8cb3439d255 rtb-0f0b93b99e7009411 rtb-067cdc2d51a442dbc"

# Region
REGION="eu-north-1"

# Function to check for dependencies
check_dependencies() {
  local route_table_id=$1

  # Check for associated subnets
  subnets=$(aws ec2 describe-route-tables \
    --region "$REGION" \
    --route-table-ids "$route_table_id" \
    --query 'RouteTables[0].Associations[].SubnetId' \
    --output text)

  # Check for non-default routes (e.g., internet gateways, NAT gateways, VPC endpoints)
  routes=$(aws ec2 describe-route-tables \
    --region "$REGION" \
    --route-table-ids "$route_table_id" \
    --query 'RouteTables[0].Routes[?GatewayId!=null || VpcPeeringConnectionId!=null || NatGatewayId!=null || DestinationPrefixListId!=null]' \
    --output text)

  if [ -n "$subnets" ] || [ -n "$routes" ]; then
    echo "Cannot delete route table $route_table_id due to dependencies:"
    [ -n "$subnets" ] && echo " - Subnets: $subnets"
    [ -n "$routes" ] && echo " - Non-default routes exist (check for gateways, VPC endpoints, etc.)"
    return 1
  fi
  return 0
}

# Function to delete a route table
delete_route_table() {
  local route_table_id=$1
  echo "Attempting to delete route table $route_table_id..."
  if aws ec2 delete-route-table --region "$REGION" --route-table-id "$route_table_id" 2>/dev/null; then
    echo "Successfully deleted route table $route_table_id"
  else
    echo "Failed to delete route table $route_table_id (possible dependency or permissions issue)"
    return 1
  fi
}

# Main loop to process each route table
for route_table_id in $ROUTE_TABLES; do
  if check_dependencies "$route_table_id"; then
    delete_route_table "$route_table_id"
  else
    echo "Skipping deletion of $route_table_id due to dependencies"
  fi
done

echo "Route table deletion process completed."
