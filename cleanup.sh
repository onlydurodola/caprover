#!/bin/bash

# cleanup.sh
# Updated script to delete all AWS resources in eu-north-1 for a clean Terraform deployment
# Region
REGION="eu-north-1"

# Log function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check and delete EC2 instances
delete_ec2_instances() {
  log "Checking for EC2 instances..."
  INSTANCE_IDS=$(aws ec2 describe-instances --region "$REGION" --query 'Reservations[].Instances[].InstanceId' --output text)
  if [ -n "$INSTANCE_IDS" ]; then
    log "Terminating instances: $INSTANCE_IDS"
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region "$REGION"
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS --region "$REGION"
    log "Terminated instances: $INSTANCE_IDS"
  else
    log "No EC2 instances found"
  fi
}

# Function to delete ALB and target groups
delete_alb_and_target_groups() {
  log "Checking for ALB (shortlink-alb)..."
  ALB_ARN=$(aws elbv2 describe-load-balancers --region "$REGION" --query 'LoadBalancers[?LoadBalancerName==`shortlink-alb`].LoadBalancerArn' --output text)
  if [ -n "$ALB_ARN" ]; then
    log "Deleting ALB: $ALB_ARN"
    aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region "$REGION"
    aws elbv2 wait load-balancers-deleted --load-balancer-arns "$ALB_ARN" --region "$REGION"
    log "Deleted ALB: $ALB_ARN"
  else
    log "No ALB found"
  fi

  log "Checking for target groups..."
  TARGET_GROUP_ARNS=$(aws elbv2 describe-target-groups --region "$REGION" --query 'TargetGroups[].TargetGroupArn' --output text)
  for ARN in $TARGET_GROUP_ARNS; do
    log "Deleting target group: $ARN"
    aws elbv2 delete-target-group --target-group-arn "$ARN" --region "$REGION"
    log "Deleted target group: $ARN"
  done
}

# Function to delete ECR repositories
delete_ecr_repositories() {
  log "Checking for ECR repositories..."
  REPOS=$(aws ecr describe-repositories --region "$REGION" --query 'repositories[].repositoryName' --output text)
  for REPO in $REPOS; do
    log "Deleting ECR repository: $REPO"
    aws ecr delete-repository --repository-name "$REPO" --region "$REGION" --force
    log "Deleted ECR repository: $REPO"
  done
}

# Function to delete Route53 hosted zones
delete_route53_zones() {
  log "Checking for Route53 hosted zones..."
  ZONE_IDS=$(aws route53 list-hosted-zones --query 'HostedZones[].Id' --output text)
  for ZONE_ID in $ZONE_IDS; do
    ZONE_ID=$(echo "$ZONE_ID" | sed 's|/hostedzone/||')
    log "Processing hosted zone: $ZONE_ID"
    RECORD_SETS=$(aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" --query 'ResourceRecordSets[?Type!=`NS` && Type!=`SOA`]' --output json)
    if [ "$(echo "$RECORD_SETS" | jq '. | length')" -gt 0 ]; then
      echo "$RECORD_SETS" | jq '{
        "Comment": "Delete all non-NS/SOA records for hosted zone '$ZONE_ID'",
        "Changes": [.[] | {"Action": "DELETE", "ResourceRecordSet": .}]
      }' > delete-records.json
      log "Deleting non-NS/SOA records for zone $ZONE_ID"
      aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch file://delete-records.json
      rm delete-records.json
    fi
    log "Deleting hosted zone: $ZONE_ID"
    aws route53 delete-hosted-zone --id "$ZONE_ID" || log "Failed to delete hosted zone $ZONE_ID (possibly pending)"
  done
}

# Function to delete VPC endpoints
delete_vpc_endpoints() {
  log "Checking for VPC endpoints..."
  ENDPOINT_IDS=$(aws ec2 describe-vpc-endpoints --region "$REGION" --query 'VpcEndpoints[].VpcEndpointId' --output text)
  for ENDPOINT_ID in $ENDPOINT_IDS; do
    log "Deleting VPC endpoint: $ENDPOINT_ID"
    aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$ENDPOINT_ID" --region "$REGION"
    log "Deleted VPC endpoint: $ENDPOINT_ID"
  done
}

# Function to delete NAT gateways
delete_nat_gateways() {
  log "Checking for NAT gateways..."
  NAT_GATEWAY_IDS=$(aws ec2 describe-nat-gateways --region "$REGION" --query 'NatGateways[].NatGatewayId' --output text)
  for NAT_ID in $NAT_GATEWAY_IDS; do
    log "Deleting NAT gateway: $NAT_ID"
    aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_ID" --region "$REGION"
    aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$NAT_ID" --region "$REGION"
    log "Deleted NAT gateway: $NAT_ID"
  done
}

# Function to delete EIPs
delete_eips() {
  log "Checking for Elastic IPs..."
  EIP_IDS=$(aws ec2 describe-addresses --region "$REGION" --query 'Addresses[].AllocationId' --output text)
  for EIP_ID in $EIP_IDS; do
    log "Releasing EIP: $EIP_ID"
    aws ec2 release-address --allocation-id "$EIP_ID" --region "$REGION"
    log "Released EIP: $EIP_ID"
  done
}

# Function to delete subnets
delete_subnets() {
  log "Checking for subnets..."
  SUBNET_IDS=$(aws ec2 describe-subnets --region "$REGION" --query 'Subnets[].SubnetId' --output text)
  for SUBNET_ID in $SUBNET_IDS; do
    log "Deleting subnet: $SUBNET_ID"
    aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --region "$REGION" || log "Failed to delete subnet $SUBNET_ID"
    log "Deleted subnet: $SUBNET_ID"
  done
}

# Function to delete non-default routes
delete_non_default_routes() {
  log "Checking for non-default routes in route tables..."
  ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables --region "$REGION" --query 'RouteTables[].RouteTableId' --output text)
  for RTB_ID in $ROUTE_TABLE_IDS; do
    log "Checking routes for route table: $RTB_ID"
    ROUTES=$(aws ec2 describe-route-tables --region "$REGION" --route-table-ids "$RTB_ID" --query 'RouteTables[0].Routes[?DestinationCidrBlock!=`null` && (GatewayId!=null || NatGatewayId!=null || VpcPeeringConnectionId!=null || DestinationPrefixListId!=null)].DestinationCidrBlock' --output text)
    for CIDR in $ROUTES; do
      if [ "$CIDR" != "$(aws ec2 describe-route-tables --region "$REGION" --route-table-ids "$RTB_ID" --query 'RouteTables[0].VpcId' --output text | xargs -I {} aws ec2 describe-vpcs --region "$REGION" --vpc-ids {} --query 'Vpcs[0].CidrBlock' --output text)" ]; then
        log "Deleting route $CIDR in $RTB_ID"
        aws ec2 delete-route --route-table-id "$RTB_ID" --destination-cidr-block "$CIDR" --region "$REGION" || log "Failed to delete route $CIDR in $RTB_ID"
      fi
    done
  done
}

# Function to delete route tables
delete_route_tables() {
  log "Checking for route tables..."
  ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables --region "$REGION" --query 'RouteTables[].RouteTableId' --output text)
  for RTB_ID in $ROUTE_TABLE_IDS; do
    log "Checking dependencies for route table: $RTB_ID"
    SUBNETS=$(aws ec2 describe-route-tables --region "$REGION" --route-table-ids "$RTB_ID" --query 'RouteTables[0].Associations[].SubnetId' --output text)
    ROUTES=$(aws ec2 describe-route-tables --region "$REGION" --route-table-ids "$RTB_ID" --query 'RouteTables[0].Routes[?GatewayId!=null || NatGatewayId!=null || VpcPeeringConnectionId!=null || DestinationPrefixListId!=null]' --output text)
    if [ -n "$SUBNETS" ] || [ -n "$ROUTES" ]; then
      log "Cannot delete $RTB_ID due to dependencies: Subnets=$SUBNETS, Routes=$ROUTES"
      continue
    fi
    log "Deleting route table: $RTB_ID"
    aws ec2 delete-route-table --route-table-id "$RTB_ID" --region "$REGION" || log "Failed to delete route table $RTB_ID"
    log "Deleted route table: $RTB_ID"
  done
}

# Function to delete internet gateways
delete_internet_gateways() {
  log "Checking for internet gateways..."
  IGW_IDS=$(aws ec2 describe-internet-gateways --region "$REGION" --query 'InternetGateways[].InternetGatewayId' --output text)
  for IGW_ID in $IGW_IDS; do
    log "Detaching internet gateway: $IGW_ID"
    VPC_ID=$(aws ec2 describe-internet-gateways --region "$REGION" --internet-gateway-ids "$IGW_ID" --query 'InternetGateways[0].Attachments[0].VpcId' --output text)
    if [ -n "$VPC_ID" ]; then
      aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$REGION" || log "Failed to detach $IGW_ID from $VPC_ID"
    fi
    log "Deleting internet gateway: $IGW_ID"
    aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --region "$REGION" || log "Failed to delete $IGW_ID"
    log "Deleted internet gateway: $IGW_ID"
  done
}

# Function to delete dependent objects for security groups (e.g., ENIs)
delete_security_group_dependencies() {
  log "Checking for security group dependencies (e.g., ENIs)..."
  SG_IDS=$(aws ec2 describe-security-groups --region "$REGION" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
  for SG_ID in $SG_IDS; do
    log "Checking dependencies for security group: $SG_ID"
    ENI_IDS=$(aws ec2 describe-network-interfaces --region "$REGION" --filters Name=group-id,Values="$SG_ID" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text)
    for ENI_ID in $ENI_IDS; do
      log "Deleting ENI: $ENI_ID"
      aws ec2 delete-network-interface --network-interface-id "$ENI_ID" --region "$REGION" || log "Failed to delete ENI $ENI_ID"
      log "Deleted ENI: $ENI_ID"
    done
  done
}

# Function to delete security groups
delete_security_groups() {
  log "Checking for non-default security groups..."
  SG_IDS=$(aws ec2 describe-security-groups --region "$REGION" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
  for SG_ID in $SG_IDS; do
    log "Deleting security group: $SG_ID"
    aws ec2 delete-security-group --group-id "$SG_ID" --region "$REGION" || log "Failed to delete security group $SG_ID"
    log "Deleted security group: $SG_ID"
  done
}

# Function to delete VPCs
delete_vpcs() {
  log "Checking for VPCs..."
  VPC_IDS=$(aws ec2 describe-vpcs --region "$REGION" --query 'Vpcs[].VpcId' --output text)
  for VPC_ID in $VPC_IDS; do
    log "Deleting VPC: $VPC_ID"
    aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$REGION" || log "Failed to delete VPC $VPC_ID"
    log "Deleted VPC: $VPC_ID"
  done
}

# Function to delete IAM roles and policies
delete_iam_roles() {
  log "Checking for IAM roles..."
  ROLES=$(aws iam list-roles --query 'Roles[?starts_with(RoleName, `prod-ec2-role`)].RoleName' --output text)
  for ROLE in $ROLES; do
    log "Detaching policies from role: $ROLE"
    POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE" --query 'AttachedPolicies[].PolicyArn' --output text)
    for POLICY_ARN in $POLICIES; do
      aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$POLICY_ARN"
      log "Detached policy $POLICY_ARN from $ROLE"
    done
    log "Deleting role: $ROLE"
    aws iam delete-role --role-name "$ROLE" || log "Failed to delete role $ROLE"
    log "Deleted role: $ROLE"
  done
}

# Main cleanup process
log "Starting AWS resource cleanup in region $REGION"
delete_ec2_instances
delete_alb_and_target_groups
delete_ecr_repositories
delete_route53_zones
delete_vpc_endpoints
delete_nat_gateways
delete_eips
delete_subnets
delete_non_default_routes
delete_route_tables
delete_internet_gateways
delete_security_group_dependencies
delete_security_groups
delete_vpcs
delete_iam_roles
log "Cleanup process completed"
