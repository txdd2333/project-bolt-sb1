#!/bin/bash

# ==============================================
# Ops Workflow Center - 启动脚本
# ==============================================

# 加载环境变量
export $(cat .env | grep -v '^#' | xargs)

# 创建必要目录
mkdir -p logs uploads

echo "=========================================="
echo "  启动 Ops Workflow Center"
echo "=========================================="

# 检查是否已安装 PM2
if command -v pm2 &> /dev/null; then
    echo "使用 PM2 启动..."
    pm2 start ecosystem.config.cjs
    echo ""
    echo "✓ 服务已启动"
    echo ""
    echo "管理命令："
    echo "  查看状态: pm2 status"
    echo "  查看日志: pm2 logs"
    echo "  重启服务: pm2 restart all"
    echo "  停止服务: pm2 stop all"
else
    echo "使用 nohup 启动..."

    # 启动后端
    nohup node server/api-server.js > logs/api-out.log 2> logs/api-error.log &
    echo $! > logs/api.pid
    echo "✓ 后端已启动 (PID: $(cat logs/api.pid))"

    # 启动前端
    nohup npx vite preview --host 0.0.0.0 --port 5173 > logs/frontend-out.log 2> logs/frontend-error.log &
    echo $! > logs/frontend.pid
    echo "✓ 前端已启动 (PID: $(cat logs/frontend.pid))"

    echo ""
    echo "查看日志："
    echo "  tail -f logs/api-out.log"
    echo "  tail -f logs/frontend-out.log"
fi

echo ""
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "访问地址: http://$SERVER_IP:5173"
echo ""
