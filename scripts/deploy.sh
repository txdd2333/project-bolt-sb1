#!/bin/bash

# 部署脚本
# 用于构建和部署应用到 CentOS 服务器

set -e

echo "======================================"
echo "运维工作流中心 - 部署脚本"
echo "======================================"
echo ""

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "错误: 未找到 Node.js，请先安装 Node.js 18+"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "错误: Node.js 版本过低 (需要 18+)，当前版本: $(node -v)"
    exit 1
fi

echo "✓ Node.js 版本: $(node -v)"
echo ""

# 步骤 1: 安装依赖
echo "步骤 1/5: 安装依赖..."
npm install

if [ $? -ne 0 ]; then
    echo "✗ 依赖安装失败"
    exit 1
fi
echo "✓ 依赖安装成功"
echo ""

# 步骤 2: 构建前端
echo "步骤 2/5: 构建前端..."
npm run build

if [ $? -ne 0 ]; then
    echo "✗ 前端构建失败"
    exit 1
fi
echo "✓ 前端构建成功"
echo ""

# 步骤 3: 创建必要的目录
echo "步骤 3/5: 创建目录..."
mkdir -p logs
mkdir -p uploads
mkdir -p dist

echo "✓ 目录创建成功"
echo ""

# 步骤 4: 安装 Playwright 浏览器
echo "步骤 4/5: 安装 Playwright 浏览器..."
npx playwright install chromium firefox webkit

if [ $? -ne 0 ]; then
    echo "警告: Playwright 浏览器安装可能不完整"
fi
echo "✓ Playwright 浏览器安装完成"
echo ""

# 步骤 5: 启动服务
echo "步骤 5/5: 启动服务..."

if command -v pm2 &> /dev/null; then
    echo "使用 PM2 启动服务..."
    pm2 delete all 2>/dev/null || true
    pm2 start ecosystem.config.cjs
    pm2 save
    pm2 startup

    echo ""
    echo "✓ 服务启动成功"
    echo ""
    echo "查看服务状态:"
    pm2 status

    echo ""
    echo "查看日志:"
    echo "  pm2 logs"
    echo "  pm2 logs ops-api-server"
    echo "  pm2 logs ops-playwright-server"
else
    echo "警告: PM2 未安装，跳过服务启动"
    echo "安装 PM2: npm install -g pm2"
fi

echo ""
echo "======================================"
echo "部署完成！"
echo "======================================"
echo ""
echo "访问地址:"
echo "  前端: http://localhost:5173 (开发模式) 或 dist/ 目录"
echo "  API: http://localhost:3001"
echo "  Playwright: http://localhost:3002"
echo ""
echo "下一步:"
echo "  1. 配置 Nginx 反向代理"
echo "  2. 配置防火墙开放端口"
echo "  3. 设置开机自启动"
