#!/bin/bash

# ==============================================
# Ops Workflow Center - 离线部署脚本（无需 Docker）
# ==============================================

set -e

echo "=========================================="
echo "  OPS Workflow Center - PM2 部署"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# 步骤 1: 检查 Node.js
# ============================================
echo "[1/8] 检查 Node.js 环境..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js 未安装${NC}"
    echo "请先安装 Node.js 18.x 或更高版本"
    echo "下载地址: https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}✗ Node.js 版本过低 (当前: $(node -v), 需要: v18.x+)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Node.js 版本: $(node -v)${NC}"

# ============================================
# 步骤 2: 检查 npm
# ============================================
echo "[2/8] 检查 npm..."
if ! command -v npm &> /dev/null; then
    echo -e "${RED}✗ npm 未安装${NC}"
    exit 1
fi
echo -e "${GREEN}✓ npm 版本: $(npm -v)${NC}"

# ============================================
# 步骤 3: 检查环境配置
# ============================================
echo "[3/8] 检查环境配置..."
if [ ! -f .env ]; then
    echo -e "${RED}✗ .env 文件不存在${NC}"
    echo "正在从 .env.example 复制..."
    cp .env.example .env
    echo -e "${YELLOW}请编辑 .env 文件并配置数据库信息${NC}"
    echo ""
    read -p "配置完成后按回车继续..."
fi

# 检查数据库配置
if grep -q "your_password" .env; then
    echo -e "${YELLOW}⚠ 警告: 检测到默认密码，请修改 .env 文件${NC}"
    read -p "确认已修改配置后按回车继续..."
fi

# 检查服务提供商配置
if ! grep -q "VITE_SERVICE_PROVIDER=custom" .env; then
    echo -e "${RED}✗ 请确保 .env 中设置了 VITE_SERVICE_PROVIDER=custom${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 环境配置检查通过${NC}"

# ============================================
# 步骤 4: 检查数据库连接
# ============================================
echo "[4/8] 检查数据库连接..."

# 从 .env 读取数据库配置
export $(cat .env | grep -v '^#' | xargs)

if command -v mysql &> /dev/null; then
    if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -e "USE $DB_DATABASE; SELECT 1;" &> /dev/null; then
        echo -e "${GREEN}✓ 数据库连接成功${NC}"
    else
        echo -e "${RED}✗ 数据库连接失败${NC}"
        echo "请检查 .env 中的数据库配置："
        echo "  DB_HOST=$DB_HOST"
        echo "  DB_PORT=$DB_PORT"
        echo "  DB_USER=$DB_USER"
        echo "  DB_DATABASE=$DB_DATABASE"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ mysql 客户端未安装，跳过数据库连接测试${NC}"
fi

# ============================================
# 步骤 5: 安装依赖（如果需要）
# ============================================
echo "[5/8] 检查项目依赖..."
if [ ! -d "node_modules" ]; then
    echo "正在安装依赖..."
    npm install
    echo -e "${GREEN}✓ 依赖安装完成${NC}"
else
    echo -e "${GREEN}✓ 依赖已存在${NC}"
fi

# ============================================
# 步骤 6: 构建项目
# ============================================
echo "[6/8] 构建项目..."

# 构建前端
if [ ! -d "dist" ]; then
    echo "构建前端..."
    npm run build
fi

# 构建后端
if [ ! -d "server" ] || [ ! -f "server/api-server.js" ]; then
    echo "构建后端..."
    npm run server:build
fi

echo -e "${GREEN}✓ 项目构建完成${NC}"

# ============================================
# 步骤 7: 创建必要目录
# ============================================
echo "[7/8] 创建数据目录..."
mkdir -p logs uploads
chmod 755 logs uploads
echo -e "${GREEN}✓ 数据目录创建完成${NC}"

# ============================================
# 步骤 8: 启动服务
# ============================================
echo "[8/8] 启动服务..."

# 检查是否安装了 PM2
if command -v pm2 &> /dev/null; then
    echo "使用 PM2 启动服务..."

    # 停止旧进程（如果存在）
    pm2 delete ecosystem.config.cjs 2>/dev/null || true

    # 启动新进程
    pm2 start ecosystem.config.cjs

    echo -e "${GREEN}✓ 服务启动完成${NC}"
    echo ""
    echo "管理命令："
    echo "  查看状态: pm2 status"
    echo "  查看日志: pm2 logs"
    echo "  重启服务: pm2 restart all"
    echo "  停止服务: pm2 stop all"
    echo ""

    # 询问是否设置开机自启
    read -p "是否设置开机自启动? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pm2 startup
        pm2 save
        echo -e "${GREEN}✓ 已设置开机自启动${NC}"
    fi

else
    echo "PM2 未安装，使用 nohup 启动服务..."

    # 停止旧进程
    if [ -f logs/api.pid ]; then
        kill $(cat logs/api.pid) 2>/dev/null || true
        rm logs/api.pid
    fi
    if [ -f logs/frontend.pid ]; then
        kill $(cat logs/frontend.pid) 2>/dev/null || true
        rm logs/frontend.pid
    fi

    # 启动后端
    nohup node server/api-server.js > logs/api-out.log 2> logs/api-error.log &
    echo $! > logs/api.pid

    # 启动前端
    nohup npx vite preview --host 0.0.0.0 --port 5173 > logs/frontend-out.log 2> logs/frontend-error.log &
    echo $! > logs/frontend.pid

    echo -e "${GREEN}✓ 服务启动完成${NC}"
    echo ""
    echo "进程 PID："
    echo "  后端: $(cat logs/api.pid)"
    echo "  前端: $(cat logs/frontend.pid)"
    echo ""
    echo "管理命令："
    echo "  查看日志: tail -f logs/api-out.log"
    echo "  停止服务: kill \$(cat logs/api.pid); kill \$(cat logs/frontend.pid)"
    echo ""
fi

# ============================================
# 配置防火墙
# ============================================
echo "配置防火墙..."
if command -v firewall-cmd &> /dev/null; then
    read -p "是否配置防火墙规则? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        firewall-cmd --permanent --add-port=3000/tcp
        firewall-cmd --permanent --add-port=5173/tcp
        firewall-cmd --reload
        echo -e "${GREEN}✓ 防火墙配置完成${NC}"
    fi
fi

# ============================================
# 部署完成
# ============================================
echo ""
echo "=========================================="
echo "  🎉 部署完成！"
echo "=========================================="
echo ""

# 获取服务器 IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "访问地址："
echo "  前端: http://$SERVER_IP:5173"
echo "  后端: http://$SERVER_IP:3000"
echo ""
echo "数据库配置："
echo "  地址: $DB_HOST:$DB_PORT"
echo "  数据库: $DB_DATABASE"
echo ""

# 测试服务
sleep 3
echo "测试服务..."
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 后端服务正常${NC}"
else
    echo -e "${YELLOW}⚠ 后端服务可能需要几秒钟启动，请稍后访问${NC}"
fi

if curl -s http://localhost:5173 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 前端服务正常${NC}"
else
    echo -e "${YELLOW}⚠ 前端服务可能需要几秒钟启动，请稍后访问${NC}"
fi

echo ""
echo "下一步："
echo "  1. 浏览器访问 http://$SERVER_IP:5173"
echo "  2. 注册新账号"
echo "  3. 开始使用系统"
echo ""
echo "查看日志："
if command -v pm2 &> /dev/null; then
    echo "  pm2 logs"
else
    echo "  tail -f logs/api-out.log"
    echo "  tail -f logs/frontend-out.log"
fi
echo ""
echo "详细文档："
echo "  cat OFFLINE_DEPLOYMENT.md"
echo ""
