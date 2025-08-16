#!/bin/bash

# WordPress Database Backup Script for Bitnami Environment
# MariaDB 10.6.12 対応

set -e  # エラー時に停止

# 設定
BACKUP_DIR="/tmp/wordpress-backup"
DATE=$(date +%Y%m%d_%H%M%S)
WP_CONFIG="/opt/bitnami/wordpress/wp-config.php"

echo "=== WordPress Database Backup ==="
echo "Date: $(date)"
echo "Backup Directory: $BACKUP_DIR"
echo ""

# バックアップディレクトリ作成
mkdir -p $BACKUP_DIR

# WordPress設定から情報取得
if [ -f "$WP_CONFIG" ]; then
    DB_NAME=$(grep "DB_NAME" $WP_CONFIG | cut -d "'" -f 4)
    DB_USER=$(grep "DB_USER" $WP_CONFIG | cut -d "'" -f 4)
    DB_HOST=$(grep "DB_HOST" $WP_CONFIG | cut -d "'" -f 4)
    
    echo "Database Name: $DB_NAME"
    echo "Database User: $DB_USER"
    echo "Database Host: $DB_HOST"
    echo ""
else
    echo "Error: WordPress config file not found"
    exit 1
fi

# データベースバックアップ実行
BACKUP_FILE="$BACKUP_DIR/wordpress_db_backup_$DATE.sql"
echo "Creating database backup: $BACKUP_FILE"

# MariaDB用のmysqldumpオプション
mysqldump \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --add-drop-table \
    --add-locks \
    --create-options \
    --disable-keys \
    --extended-insert \
    --quick \
    --set-charset \
    --comments \
    -u root -p \
    $DB_NAME > $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "✓ Database backup completed successfully"
    
    # バックアップファイル情報
    echo ""
    echo "=== Backup File Information ==="
    ls -lh $BACKUP_FILE
    echo "File size: $(du -h $BACKUP_FILE | cut -f1)"
    
    # 圧縮バックアップ作成
    COMPRESSED_BACKUP="$BACKUP_DIR/wordpress_db_backup_$DATE.sql.gz"
    echo ""
    echo "Creating compressed backup: $COMPRESSED_BACKUP"
    gzip -c $BACKUP_FILE > $COMPRESSED_BACKUP
    
    if [ $? -eq 0 ]; then
        echo "✓ Compressed backup created successfully"
        echo "Compressed size: $(du -h $COMPRESSED_BACKUP | cut -f1)"
        
        # 元のSQLファイルを削除（圧縮版があるため）
        rm $BACKUP_FILE
        echo "✓ Original SQL file removed (compressed version available)"
    else
        echo "✗ Failed to create compressed backup"
    fi
    
    echo ""
    echo "=== WordPress Files Backup ==="
    WP_FILES_BACKUP="$BACKUP_DIR/wordpress_files_backup_$DATE.tar.gz"
    echo "Creating WordPress files backup: $WP_FILES_BACKUP"
    
    tar -czf $WP_FILES_BACKUP \
        --exclude='wp-content/cache' \
        --exclude='wp-content/uploads/cache' \
        -C /opt/bitnami/wordpress .
    
    if [ $? -eq 0 ]; then
        echo "✓ WordPress files backup completed"
        echo "Files backup size: $(du -h $WP_FILES_BACKUP | cut -f1)"
    else
        echo "✗ WordPress files backup failed"
    fi
    
    echo ""
    echo "=== Backup Summary ==="
    echo "Backup location: $BACKUP_DIR"
    ls -lh $BACKUP_DIR/*$DATE*
    
    echo ""
    echo "=== Next Steps ==="
    echo "1. Verify backup integrity"
    echo "2. Transfer backup to secure location"
    echo "3. Proceed with RDS setup"
    echo "4. Test restore process"
    
else
    echo "✗ Database backup failed"
    exit 1
fi
