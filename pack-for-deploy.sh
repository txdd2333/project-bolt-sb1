#!/bin/bash

# 项目打包脚本 - 用于准备部署包
# 使用方法: bash pack-for-deploy.sh

set -e

echo "=========================================="
echo "  项目打包工具"
echo "=========================================="
echo ""

# 定义打包文件名
PACKAGE_NAME="ops-workflow-center-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "正在打包项目..."
echo ""

# 创建临时目录
TEMP_DIR="ops-workflow-center"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# 复制必要的文件
echo "📦 复制项目文件..."

# 核心文件
cp -r src "$TEMP_DIR/"
cp -r server "$TEMP_DIR/"
cp -r public "$TEMP_DIR/" 2>/dev/null || true
cp -r supabase "$TEMP_DIR/" 2>/dev/null || true

# 配置文件
cp package*.json "$TEMP_DIR/"
cp tsconfig*.json "$TEMP_DIR/"
cp vite.config.ts "$TEMP_DIR/"
cp tailwind.config.js "$TEMP_DIR/"
cp postcss.config.js "$TEMP_DIR/"
cp index.html "$TEMP_DIR/"
cp ecosystem.config.cjs "$TEMP_DIR/"

# Docker 文件
cp Dockerfile "$TEMP_DIR/"
cp docker-compose.yml "$TEMP_DIR/"
cp .dockerignore "$TEMP_DIR/"
cp docker-deploy.sh "$TEMP_DIR/"

# 环境变量模板
if [ -f ".env" ]; then
    cp .env "$TEMP_DIR/.env.example"
    echo "⚠️  .env 文件已复制为 .env.example（请勿直接使用，需修改配置）"
fi

# 文档
cp *.md "$TEMP_DIR/" 2>/dev/null || true

# 创建空目录
mkdir -p "$TEMP_DIR/logs"
mkdir -p "$TEMP_DIR/uploads"

echo ""
echo "📝 文件清单:"
echo "  ✓ 源代码 (src/, server/)"
echo "  ✓ 配置文件 (package.json, tsconfig.json, etc.)"
echo "  ✓ Docker 配置 (Dockerfile, docker-compose.yml)"
echo "  ✓ 部署脚本 (docker-deploy.sh)"
echo "  ✓ 文档 (*.md)"
echo ""

# 打包
echo "🗜️  压缩文件..."
tar -czf "$PACKAGE_NAME" "$TEMP_DIR"

# 清理临时目录
rm -rf "$TEMP_DIR"

# 显示结果
FILE_SIZE=$(du -h "$PACKAGE_NAME" | cut -f1)

echo ""
echo "=========================================="
echo "  ✅ 打包完成！"
echo "=========================================="
echo ""
echo "文件信息:"
echo "  文件名: $PACKAGE_NAME"
echo "  大小: $FILE_SIZE"
echo "  路径: $(pwd)/$PACKAGE_NAME"
echo ""
echo "下一步操作:"
echo ""
echo "1. 上传到服务器:"
echo "   scp $PACKAGE_NAME root@服务器IP:/opt/"
echo ""
echo "2. 在服务器上解压:"
echo "   cd /opt"
echo "   tar -xzf $PACKAGE_NAME"
echo ""
echo "3. 配置环境变量:"
echo "   cd /opt/ops-workflow-center"
echo "   cp .env.example .env"
echo "   vi .env  # 修改数据库配置（MySQL/OceanBase）"
echo ""
echo "4. 运行部署脚本:"
echo "   sudo bash docker-deploy.sh"
echo ""
echo "详细步骤请查看: MySQL部署操作手册.md"
echo ""
echo "=========================================="
