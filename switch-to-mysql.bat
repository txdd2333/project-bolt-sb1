@echo off
REM Windows 批处理脚本 - 切换到 MySQL/OceanBase 引擎

echo 正在切换到 MySQL/OceanBase 引擎...

if not exist .env.mysql (
    echo 错误：找不到 .env.mysql 文件
    exit /b 1
)

copy /Y .env.mysql .env >nul
echo ✓ 已切换到 MySQL/OceanBase 引擎
echo.
echo 启动方式：
echo   REM 终端 1: 启动 API 服务器
echo   npm run server
echo.
echo   REM 终端 2: 启动前端
echo   npm run dev
echo.
echo 说明：
echo   - 需要先启动 API 服务器
echo   - 数据存储在本地 MySQL/OceanBase
echo   - 适合生产部署和内网环境
echo.
pause
