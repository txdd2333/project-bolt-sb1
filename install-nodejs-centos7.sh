#!/bin/bash

# ==============================================
# CentOS 7 安装 Node.js 16 脚本（离线友好）
# ==============================================

set -e

echo "=========================================="
echo "  CentOS 7 - Node.js 16 安装"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

NODE_VERSION="v16.20.2"
NODE_PACKAGE="node-${NODE_VERSION}-linux-x64"
NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_PACKAGE}.tar.gz"
INSTALL_DIR="/usr/local"

# 检查系统版本
echo "[1/5] 检查系统版本..."
if [ -f /etc/redhat-release ]; then
    OS_VERSION=$(cat /etc/redhat-release)
    echo "系统: $OS_VERSION"
else
    echo -e "${RED}✗ 无法识别系统版本${NC}"
    exit 1
fi

# 检查是否已安装 Node.js
echo ""
echo "[2/5] 检查 Node.js..."
if command -v node &> /dev/null; then
    CURRENT_VERSION=$(node -v)
    echo -e "${YELLOW}⚠ Node.js 已安装: $CURRENT_VERSION${NC}"
    read -p "是否继续安装 Node.js 16? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "安装已取消"
        exit 0
    fi
fi

# 检查安装包
echo ""
echo "[3/5] 检查 Node.js 安装包..."
if [ -f "/tmp/${NODE_PACKAGE}.tar.gz" ]; then
    echo -e "${GREEN}✓ 找到本地安装包${NC}"
else
    echo -e "${YELLOW}⚠ 未找到本地安装包${NC}"
    echo ""
    echo "请按以下步骤准备安装包："
    echo ""
    echo "在有网络的机器上执行："
    echo "  wget $NODE_URL"
    echo "  scp ${NODE_PACKAGE}.tar.gz root@$(hostname -I | awk '{print $1}'):/tmp/"
    echo ""
    echo "或者直接下载："
    echo "  $NODE_URL"
    echo ""
    read -p "是否已准备好安装包? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "请准备好安装包后重新运行此脚本"
        exit 1
    fi

    if [ ! -f "/tmp/${NODE_PACKAGE}.tar.gz" ]; then
        echo -e "${RED}✗ 仍然找不到安装包: /tmp/${NODE_PACKAGE}.tar.gz${NC}"
        exit 1
    fi
fi

# 安装 Node.js
echo ""
echo "[4/5] 安装 Node.js..."

# 解压
cd $INSTALL_DIR
echo "解压中..."
tar -xzf /tmp/${NODE_PACKAGE}.tar.gz

# 创建软链接（删除旧的）
if [ -L "$INSTALL_DIR/node" ]; then
    rm -f $INSTALL_DIR/node
fi
ln -s $INSTALL_DIR/$NODE_PACKAGE $INSTALL_DIR/node

echo -e "${GREEN}✓ Node.js 解压完成${NC}"

# 配置环境变量
echo ""
echo "[5/5] 配置环境变量..."

# 创建环境变量文件
cat > /etc/profile.d/nodejs.sh <<EOF
export NODE_HOME=$INSTALL_DIR/node
export PATH=\$NODE_HOME/bin:\$PATH
EOF

# 使环境变量立即生效
source /etc/profile.d/nodejs.sh

# 为当前用户添加到 bashrc
if ! grep -q "NODE_HOME" ~/.bashrc; then
    echo 'export NODE_HOME=/usr/local/node' >> ~/.bashrc
    echo 'export PATH=$NODE_HOME/bin:$PATH' >> ~/.bashrc
fi

echo -e "${GREEN}✓ 环境变量配置完成${NC}"

# 验证安装
echo ""
echo "=========================================="
echo "  验证安装"
echo "=========================================="
echo ""

# 重新加载环境变量
export PATH=$INSTALL_DIR/node/bin:$PATH

if command -v node &> /dev/null; then
    echo -e "${GREEN}✓ Node.js 版本: $(node -v)${NC}"
else
    echo -e "${RED}✗ Node.js 未正确安装${NC}"
    echo "请手动设置环境变量："
    echo "  export PATH=/usr/local/node/bin:\$PATH"
    exit 1
fi

if command -v npm &> /dev/null; then
    echo -e "${GREEN}✓ npm 版本: $(npm -v)${NC}"
else
    echo -e "${RED}✗ npm 未正确安装${NC}"
    exit 1
fi

# 配置 npm 镜像
echo ""
echo "配置 npm 镜像..."
npm config set registry https://registry.npmmirror.com
echo -e "${GREEN}✓ npm 镜像已设置为国内镜像${NC}"

# 测试运行
echo ""
echo "测试 Node.js..."
node -e "console.log('Node.js 工作正常!')"

# 安装完成
echo ""
echo "=========================================="
echo "  🎉 安装完成！"
echo "=========================================="
echo ""
echo "Node.js 版本: $(node -v)"
echo "npm 版本: $(npm -v)"
echo "安装位置: $INSTALL_DIR/node"
echo ""
echo "环境变量已配置到:"
echo "  - /etc/profile.d/nodejs.sh (全局)"
echo "  - ~/.bashrc (当前用户)"
echo ""
echo "如果命令不生效，请执行："
echo "  source /etc/profile.d/nodejs.sh"
echo "  或"
echo "  source ~/.bashrc"
echo ""
echo "下一步："
echo "  cd /path/to/ops-workflow-center"
echo "  bash deploy-without-docker.sh"
echo ""
