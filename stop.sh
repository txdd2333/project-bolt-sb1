#!/bin/bash

# ==============================================
# Ops Workflow Center - 停止脚本
# ==============================================

echo "=========================================="
echo "  停止 Ops Workflow Center"
echo "=========================================="

# 检查是否使用 PM2
if command -v pm2 &> /dev/null && pm2 list | grep -q "ops-workflow"; then
    echo "停止 PM2 进程..."
    pm2 stop all
    echo "✓ 服务已停止"
else
    echo "停止 nohup 进程..."

    # 停止后端
    if [ -f logs/api.pid ]; then
        kill $(cat logs/api.pid) 2>/dev/null && echo "✓ 后端已停止" || echo "⚠ 后端进程未运行"
        rm logs/api.pid
    else
        echo "⚠ 未找到后端进程文件"
    fi

    # 停止前端
    if [ -f logs/frontend.pid ]; then
        kill $(cat logs/frontend.pid) 2>/dev/null && echo "✓ 前端已停止" || echo "⚠ 前端进程未运行"
        rm logs/frontend.pid
    else
        echo "⚠ 未找到前端进程文件"
    fi
fi

echo ""
