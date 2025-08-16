#!/bin/bash

# WordPress RDS Instance Creation Script
# Based on analysis: 118MB database, 917 posts, 8 users

set -e

# 設定
RDS_IDENTIFIER="wordpress-production-db"
ENGINE="mariadb"
ENGINE_VERSION="10.6.14"
INSTANCE_CLASS="db.t3.micro"
ALLOCATED_STORAGE="20"
DB_NAME="bitnami_wordpress"
MASTER_USERNAME="bn_wordpress"

echo "=== WordPress RDS Instance Creation ==="
echo "Date: $(date)"
echo "Database Size: 118.03 MB (current)"
echo "Estimated Storage Need: 20 GB (with growth buffer)"
echo ""

# パラメータ確認
echo "=== Configuration ==="
echo "RDS Identifier: $RDS_IDENTIFIER"
echo "Engine: $ENGINE $ENGINE_VERSION"
echo "Instance Class: $INSTANCE_CLASS"
echo "Storage: ${ALLOCATED_STORAGE}GB (auto-scaling to 50GB)"
echo "Database Name: $DB_NAME"
echo "Master Username: $MASTER_USERNAME"
echo ""

# 必要な情報の確認
read -p "Enter Master Password: " -s MASTER_PASSWORD
echo ""
read -p "Enter VPC Security Group ID: " SECURITY_GROUP_ID
read -p "Enter DB Subnet Group Name (optional): " DB_SUBNET_GROUP

echo ""
echo "=== Creating RDS Instance ==="

# RDS作成コマンド構築
CREATE_CMD="aws rds create-db-instance \
    --db-instance-identifier $RDS_IDENTIFIER \
    --db-instance-class $INSTANCE_CLASS \
    --engine $ENGINE \
    --engine-version $ENGINE_VERSION \
    --master-username $MASTER_USERNAME \
    --master-user-password $MASTER_PASSWORD \
    --allocated-storage $ALLOCATED_STORAGE \
    --max-allocated-storage 50 \
    --storage-type gp2 \
    --storage-encrypted \
    --backup-retention-period 7 \
    --backup-window 03:00-04:00 \
    --maintenance-window sun:04:00-sun:05:00 \
    --deletion-protection \
    --vpc-security-group-ids $SECURITY_GROUP_ID"

# DB Subnet Groupが指定されている場合は追加
if [ ! -z "$DB_SUBNET_GROUP" ]; then
    CREATE_CMD="$CREATE_CMD --db-subnet-group-name $DB_SUBNET_GROUP"
fi

# Performance Insights有効化
CREATE_CMD="$CREATE_CMD --enable-performance-insights --performance-insights-retention-period 7"

# CloudWatch Logs有効化
CREATE_CMD="$CREATE_CMD --enable-cloudwatch-logs-exports error general slow_query"

# タグ追加
CREATE_CMD="$CREATE_CMD --tags Key=Environment,Value=production Key=Application,Value=wordpress Key=Project,Value=hack-note-ci Key=DatabaseSize,Value=118MB"

echo "Executing RDS creation command..."
eval $CREATE_CMD

if [ $? -eq 0 ]; then
    echo "✓ RDS instance creation initiated successfully"
    echo ""
    echo "=== Next Steps ==="
    echo "1. Wait for RDS instance to become available (5-10 minutes)"
    echo "2. Check status: aws rds describe-db-instances --db-instance-identifier $RDS_IDENTIFIER"
    echo "3. Get endpoint: aws rds describe-db-instances --db-instance-identifier $RDS_IDENTIFIER --query 'DBInstances[0].Endpoint.Address' --output text"
    echo "4. Create database: mysql -h <endpoint> -u $MASTER_USERNAME -p -e 'CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'"
    echo "5. Proceed with data migration"
    
    echo ""
    echo "=== Monitoring Commands ==="
    echo "# Check creation status"
    echo "aws rds describe-db-instances --db-instance-identifier $RDS_IDENTIFIER --query 'DBInstances[0].DBInstanceStatus' --output text"
    echo ""
    echo "# Get endpoint when available"
    echo "aws rds describe-db-instances --db-instance-identifier $RDS_IDENTIFIER --query 'DBInstances[0].Endpoint.Address' --output text"
    
else
    echo "✗ RDS instance creation failed"
    echo "Please check AWS CLI configuration and permissions"
    exit 1
fi
