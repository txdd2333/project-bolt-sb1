#!/bin/bash

# 切换到 MySQL/OceanBase 引擎
echo "正在切换到 MySQL/OceanBase 引擎..."

if [ ! -f .env.mysql ]; then
    echo "错误：找不到 .env.mysql 文件"
    exit 1
fi

cp .env.mysql .env
echo "✅ 已切换到 MySQL/OceanBase 引擎"
echo ""
echo "启动方式："
echo "  # 终端 1: 启动 API 服务器"
echo "  npm run server"
echo ""
echo "  # 终端 2: 启动前端"
echo "  npm run dev"
echo ""
echo "说明："
echo "  - 需要先启动 API 服务器"
echo "  - 数据存储在本地 MySQL/OceanBase"
echo "  - 适合生产部署和内网环境"
