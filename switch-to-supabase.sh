#!/bin/bash

# 切换到 Supabase 引擎
echo "正在切换到 Supabase 引擎..."

if [ ! -f .env.supabase ]; then
    echo "错误：找不到 .env.supabase 文件"
    exit 1
fi

cp .env.supabase .env
echo "✅ 已切换到 Supabase 引擎"
echo ""
echo "启动方式："
echo "  npm run dev"
echo ""
echo "说明："
echo "  - 无需启动 API 服务器"
echo "  - 数据存储在 Supabase 云端"
echo "  - 适合快速开发和多人协作"
