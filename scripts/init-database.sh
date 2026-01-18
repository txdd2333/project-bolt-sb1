#!/bin/bash

# 数据库初始化脚本
# 用于在 OceanBase MySQL 租户中创建数据库和表

set -e

echo "======================================"
echo "运维工作流中心 - 数据库初始化脚本"
echo "======================================"
echo ""

# 从 .env.server 文件读取配置
if [ -f .env.server ]; then
    export $(cat .env.server | grep -v '^#' | xargs)
fi

# 数据库连接参数
DB_HOST=${DB_HOST:-"192.168.1.70"}
DB_PORT=${DB_PORT:-"2883"}
DB_USER=${DB_USER:-"root@Tianji4_MySQL#Tianji4"}
DB_PASSWORD=${DB_PASSWORD:-"aaAA11__"}
DB_DATABASE=${DB_DATABASE:-"ops_workflow_center"}

echo "数据库连接信息:"
echo "  主机: $DB_HOST"
echo "  端口: $DB_PORT"
echo "  用户: $DB_USER"
echo "  数据库: $DB_DATABASE"
echo ""

# 检查 mysql 客户端是否安装
if ! command -v mysql &> /dev/null; then
    echo "错误: 未找到 mysql 客户端，请先安装 MySQL 客户端"
    echo ""
    echo "安装命令:"
    echo "  CentOS/RHEL: sudo yum install mysql"
    echo "  Ubuntu/Debian: sudo apt-get install mysql-client"
    exit 1
fi

echo "步骤 1/3: 创建数据库..."
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS $DB_DATABASE
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
EOF

if [ $? -eq 0 ]; then
    echo "✓ 数据库创建成功"
else
    echo "✗ 数据库创建失败"
    exit 1
fi

echo ""
echo "步骤 2/3: 创建表结构..."
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_DATABASE" < docs/mysql-schema.sql

if [ $? -eq 0 ]; then
    echo "✓ 表结构创建成功"
else
    echo "✗ 表结构创建失败"
    exit 1
fi

echo ""
echo "步骤 3/3: 验证表结构..."
TABLE_COUNT=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_DATABASE" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$DB_DATABASE';")

echo "✓ 成功创建 $TABLE_COUNT 个表"
echo ""

mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_DATABASE" -e "SHOW TABLES;"

echo ""
echo "======================================"
echo "数据库初始化完成！"
echo "======================================"
