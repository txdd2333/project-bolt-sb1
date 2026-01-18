#!/bin/bash

# Docker 一键部署脚本
# 使用方法: sudo bash docker-deploy.sh

set -e

echo "=========================================="
echo "  OPS Workflow Center - Docker 部署"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为 root 或使用 sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误: 请使用 sudo 运行此脚本${NC}"
    echo "正确用法: sudo bash docker-deploy.sh"
    exit 1
fi

# 步骤 1: 检查并安装 Docker
echo -e "${YELLOW}[1/6] 检查 Docker 环境...${NC}"
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，正在安装..."

    # 安装依赖
    yum install -y yum-utils device-mapper-persistent-data lvm2

    # 添加 Docker 仓库
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    # 安装 Docker
    yum install -y docker-ce docker-ce-cli containerd.io

    # 启动 Docker
    systemctl start docker
    systemctl enable docker

    echo -e "${GREEN}✓ Docker 安装完成${NC}"
else
    echo -e "${GREEN}✓ Docker 已安装${NC}"

    # 确保 Docker 正在运行
    if ! systemctl is-active --quiet docker; then
        echo "启动 Docker 服务..."
        systemctl start docker
    fi
fi

# 步骤 2: 检查并安装 Docker Compose
echo -e "\n${YELLOW}[2/6] 检查 Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose 未安装，正在安装..."

    # 下载 Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

    # 添加执行权限
    chmod +x /usr/local/bin/docker-compose

    # 创建软链接
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

    echo -e "${GREEN}✓ Docker Compose 安装完成${NC}"
else
    echo -e "${GREEN}✓ Docker Compose 已安装${NC}"
fi

# 步骤 3: 检查环境变量文件
echo -e "\n${YELLOW}[3/6] 检查环境配置...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${RED}错误: .env 文件不存在！${NC}"
    echo "请确保 .env 文件包含必需配置："
    echo "  VITE_SERVICE_PROVIDER=custom"
    echo "  DB_HOST=数据库地址"
    echo "  DB_USER=数据库用户"
    echo "  DB_PASSWORD=数据库密码"
    echo "  DB_DATABASE=数据库名称"
    exit 1
fi

# 检查必需的环境变量
if ! grep -q "DB_HOST" .env; then
    echo -e "${RED}错误: .env 文件缺少必需的数据库配置${NC}"
    echo "请确保配置了以下变量："
    echo "  DB_HOST=数据库地址"
    echo "  DB_USER=数据库用户"
    echo "  DB_PASSWORD=数据库密码"
    echo "  DB_DATABASE=数据库名称"
    exit 1
fi

echo -e "${GREEN}✓ 环境配置文件检查通过${NC}"

# 步骤 4: 创建必要的目录
echo -e "\n${YELLOW}[4/6] 创建数据目录...${NC}"
mkdir -p logs uploads
chmod 777 logs uploads
echo -e "${GREEN}✓ 数据目录创建完成${NC}"

# 步骤 5: 构建 Docker 镜像
echo -e "\n${YELLOW}[5/6] 构建 Docker 镜像（首次构建需要 5-10 分钟）...${NC}"
docker-compose build

echo -e "${GREEN}✓ Docker 镜像构建完成${NC}"

# 步骤 6: 启动服务
echo -e "\n${YELLOW}[6/6] 启动服务...${NC}"

# 停止旧容器（如果存在）
if [ "$(docker ps -q -f name=ops-workflow-center)" ]; then
    echo "停止旧容器..."
    docker-compose down
fi

# 启动新容器
docker-compose up -d

# 等待服务启动
echo "等待服务启动..."
sleep 10

# 检查容器状态
if [ "$(docker ps -q -f name=ops-workflow-center)" ]; then
    echo -e "\n${GREEN}=========================================="
    echo "  ✓ 部署成功！"
    echo "==========================================${NC}"
    echo ""
    echo "服务信息："
    echo "  - 前端地址: http://$(hostname -I | awk '{print $1}'):5173"
    echo "  - 后端 API: http://$(hostname -I | awk '{print $1}'):3000"
    echo ""
    echo "常用命令："
    echo "  查看日志: docker-compose logs -f"
    echo "  停止服务: docker-compose down"
    echo "  重启服务: docker-compose restart"
    echo "  查看状态: docker-compose ps"
    echo ""
    echo "数据目录："
    echo "  - 日志文件: ./logs/"
    echo "  - 上传文件: ./uploads/"
    echo ""
else
    echo -e "\n${RED}错误: 容器启动失败${NC}"
    echo "查看日志: docker-compose logs"
    exit 1
fi
