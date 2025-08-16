# WordPress Database Migration Guide
## Bitnami MariaDB 10.6.12 → AWS RDS MariaDB

### 📋 移行概要

**移行元**: Bitnami WordPress (MariaDB 10.6.12)  
**移行先**: AWS RDS MariaDB 10.6.14  
**目的**: 継続的インテグレーション基盤の構築

### 🔍 事前調査

#### 1. 現在の環境分析
```bash
# データベース分析実行
cd hack-note-ci
chmod +x scripts/database/analyze-current-db.sh
./scripts/database/analyze-current-db.sh
```

#### 2. 確認項目
- [ ] データベースサイズ
- [ ] テーブル構造
- [ ] WordPress投稿数
- [ ] ユーザー数
- [ ] プラグイン依存関係

### 💾 バックアップ作成

#### 1. 完全バックアップ実行
```bash
# バックアップスクリプト実行
chmod +x scripts/database/backup-wordpress-db.sh
./scripts/database/backup-wordpress-db.sh
```

#### 2. バックアップ検証
```bash
# バックアップファイル確認
ls -la /tmp/wordpress-backup/

# SQLファイル整合性確認
zcat /tmp/wordpress-backup/wordpress_db_backup_*.sql.gz | head -20
```

### 🏗️ RDS環境構築

#### 1. セキュリティグループ作成
```bash
# WordPress EC2からのアクセス許可
aws ec2 create-security-group \
    --group-name wordpress-rds-sg \
    --description "Security group for WordPress RDS"

aws ec2 authorize-security-group-ingress \
    --group-id <SECURITY_GROUP_ID> \
    --protocol tcp \
    --port 3306 \
    --source-group <EC2_SECURITY_GROUP_ID>
```

#### 2. RDSインスタンス作成
```bash
# RDS作成（設定ファイル使用）
aws rds create-db-instance \
    --db-instance-identifier wordpress-production-db \
    --db-instance-class db.t3.micro \
    --engine mariadb \
    --engine-version 10.6.14 \
    --master-username wpuser \
    --master-user-password <SECURE_PASSWORD> \
    --allocated-storage 20 \
    --vpc-security-group-ids <SECURITY_GROUP_ID> \
    --backup-retention-period 7 \
    --storage-encrypted \
    --deletion-protection
```

#### 3. RDS接続確認
```bash
# RDS接続テスト
mysql -h <RDS_ENDPOINT> -u wpuser -p

# データベース作成
CREATE DATABASE wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 📤 データ移行

#### 1. データインポート
```bash
# 圧縮バックアップをRDSにインポート
zcat /tmp/wordpress-backup/wordpress_db_backup_*.sql.gz | \
mysql -h <RDS_ENDPOINT> -u wpuser -p wordpress
```

#### 2. データ整合性確認
```bash
# テーブル数確認
mysql -h <RDS_ENDPOINT> -u wpuser -p wordpress -e "SHOW TABLES;"

# 投稿数確認
mysql -h <RDS_ENDPOINT> -u wpuser -p wordpress -e "SELECT COUNT(*) FROM wp_posts WHERE post_status='publish';"

# ユーザー数確認
mysql -h <RDS_ENDPOINT> -u wpuser -p wordpress -e "SELECT COUNT(*) FROM wp_users;"
```

### ⚙️ WordPress設定更新

#### 1. wp-config.php バックアップ
```bash
# 現在の設定をバックアップ
cp /opt/bitnami/wordpress/wp-config.php /opt/bitnami/wordpress/wp-config.php.backup
```

#### 2. データベース接続設定変更
```php
// wp-config.php の更新
define('DB_NAME', 'wordpress');
define('DB_USER', 'wpuser');
define('DB_PASSWORD', '<RDS_PASSWORD>');
define('DB_HOST', '<RDS_ENDPOINT>');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', 'utf8mb4_unicode_ci');
```

#### 3. 接続テスト
```bash
# WordPress管理画面アクセステスト
curl -I http://<WORDPRESS_URL>/wp-admin/

# フロントエンド表示テスト
curl -I http://<WORDPRESS_URL>/
```

### ✅ 移行検証

#### 1. 機能テスト
- [ ] WordPress管理画面ログイン
- [ ] 投稿一覧表示
- [ ] 新規投稿作成
- [ ] メディアアップロード
- [ ] プラグイン動作確認
- [ ] テーマ表示確認

#### 2. パフォーマンステスト
- [ ] ページ読み込み速度
- [ ] データベースクエリ応答時間
- [ ] 同時アクセステスト

#### 3. セキュリティ確認
- [ ] RDSアクセス制限
- [ ] SSL/TLS接続
- [ ] バックアップ設定

### 🚨 ロールバック手順

#### 緊急時の復旧
```bash
# 1. 元のwp-config.phpに戻す
cp /opt/bitnami/wordpress/wp-config.php.backup /opt/bitnami/wordpress/wp-config.php

# 2. ローカルMariaDBサービス開始
sudo systemctl start mariadb

# 3. 動作確認
curl -I http://<WORDPRESS_URL>/
```

### 📊 移行後の監視

#### 1. CloudWatch設定
- データベース接続数
- CPU使用率
- ストレージ使用量
- レスポンス時間

#### 2. アラート設定
- 接続エラー
- 高CPU使用率
- ストレージ不足

### 🔄 継続的運用

#### 1. 自動バックアップ
- RDS自動バックアップ: 7日間保持
- 手動スナップショット: 重要な変更前

#### 2. メンテナンス
- 定期的なセキュリティアップデート
- パフォーマンス監視
- ストレージ使用量監視

---

**注意事項**:
- 移行作業は必ずメンテナンス時間に実施
- 完全バックアップ後に作業開始
- ロールバック手順を事前に確認
- 移行後は一定期間、元環境を保持
