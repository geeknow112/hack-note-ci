#!/bin/bash

# Network Information Collection Script
# For environments with limited IAM permissions

echo "=== Network Information Collection ==="
echo "Date: $(date)"
echo ""

# Instance metadata
echo "=== Instance Information ==="
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
MAC=$(curl -s http://169.254.169.254/latest/meta-data/mac)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

echo "Instance ID: $INSTANCE_ID"
echo "MAC Address: $MAC"
echo "Availability Zone: $AZ"
echo "Region: $REGION"
echo ""

# Network information
echo "=== Network Information ==="
VPC_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/vpc-id)
SUBNET_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/subnet-id)
SECURITY_GROUPS=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/security-group-ids)

echo "VPC ID: $VPC_ID"
echo "Subnet ID: $SUBNET_ID"
echo "Security Group IDs: $SECURITY_GROUPS"
echo ""

# RDS permissions check
echo "=== RDS Permissions Check ==="
if aws rds describe-db-instances --max-items 1 >/dev/null 2>&1; then
    echo "✓ RDS describe permission: Available"
else
    echo "✗ RDS describe permission: Limited"
fi

if aws rds describe-db-subnet-groups --max-items 1 >/dev/null 2>&1; then
    echo "✓ RDS subnet groups permission: Available"
else
    echo "✗ RDS subnet groups permission: Limited"
fi

echo ""
echo "=== RDS Creation Information ==="
echo "For RDS creation, you will need:"
echo "1. VPC Security Group ID: $SECURITY_GROUPS"
echo "2. DB Subnet Group: May need to be created or specified"
echo "3. Master Password: Will be prompted during creation"
echo ""
echo "=== Next Steps ==="
echo "1. Run: ./scripts/database/create-rds-instance.sh"
echo "2. Use Security Group ID: $SECURITY_GROUPS"
echo "3. Leave DB Subnet Group empty if unsure (will use default)"
