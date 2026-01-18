@echo off
REM Windows 批处理脚本 - 切换到 Supabase 引擎

echo 正在切换到 Supabase 引擎...

if not exist .env.supabase (
    echo 错误：找不到 .env.supabase 文件
    exit /b 1
)

copy /Y .env.supabase .env >nul
echo ✓ 已切换到 Supabase 引擎
echo.
echo 启动方式：
echo   npm run dev
echo.
echo 说明：
echo   - 无需启动 API 服务器
echo   - 数据存储在 Supabase 云端
echo   - 适合快速开发和多人协作
echo.
pause
