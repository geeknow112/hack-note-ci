#!/bin/bash

# WordPress Database Analysis Script
# 現在のBitnami WordPress環境のデータベース情報を収集

echo "=== WordPress Database Analysis ==="
echo "Date: $(date)"
echo "Server: $(hostname)"
echo ""

# MariaDB バージョン確認
echo "=== Database Version ==="
mysql --version
echo ""

# WordPress データベース情報取得
echo "=== WordPress Database Information ==="

# Bitnami のデフォルト設定ファイルから情報取得
WP_CONFIG="/opt/bitnami/wordpress/wp-config.php"
if [ -f "$WP_CONFIG" ]; then
    echo "WordPress Config File: $WP_CONFIG"
    
    # データベース名取得
    DB_NAME=$(grep "DB_NAME" $WP_CONFIG | cut -d "'" -f 4)
    DB_USER=$(grep "DB_USER" $WP_CONFIG | cut -d "'" -f 4)
    DB_HOST=$(grep "DB_HOST" $WP_CONFIG | cut -d "'" -f 4)
    
    echo "Database Name: $DB_NAME"
    echo "Database User: $DB_USER"
    echo "Database Host: $DB_HOST"
    echo ""
else
    echo "WordPress config file not found at expected location"
    echo "Please check WordPress installation path"
    exit 1
fi

# データベースサイズ確認
echo "=== Database Size Analysis ==="
mysql -u bn_wordpress -p -h 127.0.0.1 -e "
SELECT 
    table_schema as 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) as 'Size (MB)'
FROM information_schema.tables 
WHERE table_schema = '$DB_NAME'
GROUP BY table_schema;
"

echo ""
echo "=== Table Information ==="
mysql -u bn_wordpress -p -h 127.0.0.1 -e "
SELECT 
    table_name as 'Table',
    ROUND(((data_length + index_length) / 1024 / 1024), 2) as 'Size (MB)',
    table_rows as 'Rows'
FROM information_schema.TABLES 
WHERE table_schema = '$DB_NAME'
ORDER BY (data_length + index_length) DESC;
"

echo ""
echo "=== WordPress Posts Count ==="
mysql -u bn_wordpress -p -h 127.0.0.1 -D $DB_NAME -e "
SELECT 
    post_type,
    post_status,
    COUNT(*) as count
FROM wp_posts 
GROUP BY post_type, post_status
ORDER BY count DESC;
"

echo ""
echo "=== WordPress Users Count ==="
mysql -u bn_wordpress -p -h 127.0.0.1 -D $DB_NAME -e "
SELECT COUNT(*) as total_users FROM wp_users;
"

echo ""
echo "=== Analysis Complete ==="
echo "Next steps:"
echo "1. Review database size and structure"
echo "2. Plan RDS instance specifications"
echo "3. Create backup before migration"
