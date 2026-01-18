#!/bin/bash

# 项目打包脚本
# 用于在本地打包项目以便上传到服务器

set -e

echo "======================================"
echo "运维工作流中心 - 项目打包脚本"
echo "======================================"
echo ""

# 获取当前日期时间
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PACKAGE_NAME="ops-workflow-center_${TIMESTAMP}.tar.gz"

echo "打包信息:"
echo "  文件名: $PACKAGE_NAME"
echo "  时间: $(date)"
echo ""

# 检查是否在项目根目录
if [ ! -f "package.json" ]; then
    echo "错误: 请在项目根目录下执行此脚本"
    exit 1
fi

echo "步骤 1/3: 清理临时文件..."
rm -rf node_modules
rm -rf dist
rm -rf .next
rm -rf .turbo
rm -rf uploads
rm -rf logs

echo "✓ 清理完成"
echo ""

echo "步骤 2/3: 打包项目文件..."
tar -czf "$PACKAGE_NAME" \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='dist' \
    --exclude='uploads' \
    --exclude='logs' \
    --exclude='*.log' \
    --exclude='.DS_Store' \
    --exclude='*.tar.gz' \
    .

if [ $? -eq 0 ]; then
    echo "✓ 打包成功"
else
    echo "✗ 打包失败"
    exit 1
fi

echo ""
echo "步骤 3/3: 验证打包文件..."
FILE_SIZE=$(du -h "$PACKAGE_NAME" | cut -f1)
echo "✓ 打包文件大小: $FILE_SIZE"
echo ""

echo "======================================"
echo "打包完成！"
echo "======================================"
echo ""
echo "打包文件: $PACKAGE_NAME"
echo ""
echo "下一步:"
echo "  1. 使用 SCP 上传到服务器:"
echo "     scp $PACKAGE_NAME root@your-server-ip:/root/"
echo ""
echo "  2. 在服务器上解压:"
echo "     mkdir -p /opt/ops-workflow-center"
echo "     tar -xzf /root/$PACKAGE_NAME -C /opt/ops-workflow-center/"
echo ""
echo "  3. 参考部署文档继续操作:"
echo "     QUICKSTART_LOCAL_DEPLOYMENT.md"
