# 离线部署指南（无需 Docker）

## 🎯 适用场景

- 内网环境，无法访问互联网
- 无法访问 Docker Hub
- 希望直接在服务器上运行应用

---

## 📋 前置要求

服务器上需要已安装：
- **Node.js 18.x** 或更高版本
- **npm** 包管理器
- **MySQL 客户端**（用于测试连接）

---

## 🚀 方案1：使用 PM2 部署（推荐）

### 步骤 1: 在有网络的机器上准备部署包

```bash
# 在有网络的开发机器上
cd /path/to/ops-workflow-center

# 安装依赖
npm install

# 构建前端
npm run build

# 构建后端
npm run server:build

# 打包所有文件（包含 node_modules）
tar -czf ops-workflow-center-offline.tar.gz \
  dist/ \
  server/ \
  node_modules/ \
  package.json \
  package-lock.json \
  ecosystem.config.cjs \
  .env.example \
  scripts/ \
  uploads/ \
  logs/

# 传输到目标服务器
scp ops-workflow-center-offline.tar.gz user@192.168.1.100:/tmp/
```

### 步骤 2: 在目标服务器上部署

```bash
# 创建部署目录
sudo mkdir -p /opt/ops-workflow-center
cd /opt/ops-workflow-center

# 解压部署包
sudo tar -xzf /tmp/ops-workflow-center-offline.tar.gz

# 配置环境变量
sudo cp .env.example .env
sudo vi .env
```

配置 OceanBase 连接：
```bash
VITE_SERVICE_PROVIDER=custom
VITE_API_URL=http://localhost:3000
DB_HOST=192.168.1.70
DB_PORT=2883
DB_USER=root@Tianji4_MySQL#Tianji4
DB_PASSWORD=aaAA11__
DB_DATABASE=ops_workflow_center
JWT_SECRET=your-random-secret-key-here
UPLOAD_DIR=./uploads
```

### 步骤 3: 安装并配置 PM2（如未安装）

```bash
# 检查 PM2 是否已安装
pm2 --version

# 如果未安装（需要在有网络的机器上下载）
# 在有网络的机器上：
npm pack pm2
# 将 pm2-xxx.tgz 传输到目标服务器

# 在目标服务器上：
sudo npm install -g pm2-xxx.tgz
```

或者直接使用项目中的 node_modules：
```bash
# 使用项目本地的 PM2
sudo npm install -g pm2
```

### 步骤 4: 启动应用

```bash
# 使用 PM2 启动
sudo pm2 start ecosystem.config.cjs

# 查看状态
sudo pm2 status

# 查看日志
sudo pm2 logs

# 设置开机自启
sudo pm2 startup
sudo pm2 save
```

### 步骤 5: 配置防火墙

```bash
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=5173/tcp
sudo firewall-cmd --reload
```

### 步骤 6: 验证部署

```bash
# 测试后端
curl http://localhost:3000/health

# 测试前端
curl http://localhost:5173

# 浏览器访问
# http://服务器IP:5173
```

---

## 🚀 方案2：使用 systemd 服务（无需 PM2）

### 创建后端服务

```bash
sudo vi /etc/systemd/system/ops-workflow-api.service
```

内容：
```ini
[Unit]
Description=Ops Workflow Center API Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ops-workflow-center
Environment="NODE_ENV=production"
EnvironmentFile=/opt/ops-workflow-center/.env
ExecStart=/usr/bin/node server/api-server.js
Restart=always
RestartSec=10
StandardOutput=append:/opt/ops-workflow-center/logs/api-out.log
StandardError=append:/opt/ops-workflow-center/logs/api-error.log

[Install]
WantedBy=multi-user.target
```

### 创建前端服务

```bash
sudo vi /etc/systemd/system/ops-workflow-frontend.service
```

内容：
```ini
[Unit]
Description=Ops Workflow Center Frontend Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ops-workflow-center
ExecStart=/usr/bin/npx vite preview --host 0.0.0.0 --port 5173
Restart=always
RestartSec=10
StandardOutput=append:/opt/ops-workflow-center/logs/frontend-out.log
StandardError=append:/opt/ops-workflow-center/logs/frontend-error.log

[Install]
WantedBy=multi-user.target
```

### 启动服务

```bash
# 重载 systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start ops-workflow-api
sudo systemctl start ops-workflow-frontend

# 查看状态
sudo systemctl status ops-workflow-api
sudo systemctl status ops-workflow-frontend

# 设置开机自启
sudo systemctl enable ops-workflow-api
sudo systemctl enable ops-workflow-frontend

# 查看日志
sudo journalctl -u ops-workflow-api -f
sudo journalctl -u ops-workflow-frontend -f
```

---

## 🚀 方案3：使用 nohup 简单部署

### 快速启动脚本

创建 `start.sh`：
```bash
#!/bin/bash

# 加载环境变量
export $(cat .env | grep -v '^#' | xargs)

# 创建日志目录
mkdir -p logs uploads

# 启动后端
nohup node server/api-server.js > logs/api-out.log 2> logs/api-error.log &
echo $! > logs/api.pid

# 启动前端
nohup npx vite preview --host 0.0.0.0 --port 5173 > logs/frontend-out.log 2> logs/frontend-error.log &
echo $! > logs/frontend.pid

echo "✓ 服务已启动"
echo "  后端 PID: $(cat logs/api.pid)"
echo "  前端 PID: $(cat logs/frontend.pid)"
echo ""
echo "访问地址: http://$(hostname -I | awk '{print $1}'):5173"
```

创建 `stop.sh`：
```bash
#!/bin/bash

# 停止后端
if [ -f logs/api.pid ]; then
    kill $(cat logs/api.pid)
    rm logs/api.pid
    echo "✓ 后端已停止"
fi

# 停止前端
if [ -f logs/frontend.pid ]; then
    kill $(cat logs/frontend.pid)
    rm logs/frontend.pid
    echo "✓ 前端已停止"
fi
```

使用方法：
```bash
# 启动
sudo bash start.sh

# 停止
sudo bash stop.sh

# 查看日志
tail -f logs/api-out.log
tail -f logs/frontend-out.log
```

---

## 📦 方案4：离线 Docker 镜像部署

如果必须使用 Docker，可以在有网络的机器上构建镜像，然后导出。

### 在有网络的机器上

```bash
# 构建镜像
docker build -t ops-workflow-center:latest .

# 导出镜像
docker save ops-workflow-center:latest | gzip > ops-workflow-center-image.tar.gz

# 传输到目标服务器
scp ops-workflow-center-image.tar.gz user@192.168.1.100:/tmp/
```

### 在目标服务器上

```bash
# 加载镜像
sudo docker load < /tmp/ops-workflow-center-image.tar.gz

# 查看镜像
sudo docker images | grep ops-workflow-center

# 修改 docker-compose.yml 使用本地镜像
sudo vi docker-compose.yml
```

修改 `docker-compose.yml`：
```yaml
services:
  app:
    image: ops-workflow-center:latest  # 使用本地镜像
    # build: .  # 注释掉 build
    container_name: ops-workflow-center
    # ... 其他配置保持不变
```

```bash
# 启动容器
sudo docker-compose up -d

# 查看日志
sudo docker-compose logs -f
```

---

## 🔍 各方案对比

| 方案 | 优点 | 缺点 | 推荐指数 |
|------|------|------|----------|
| **PM2** | 简单、稳定、易管理 | 需要安装 PM2 | ⭐⭐⭐⭐⭐ |
| **systemd** | 系统原生、最可靠 | 配置稍复杂 | ⭐⭐⭐⭐ |
| **nohup** | 最简单、无依赖 | 管理不便 | ⭐⭐⭐ |
| **Docker 离线** | 环境隔离 | 需要两台机器 | ⭐⭐ |

---

## ✅ 验证清单

### 部署前

- [ ] 已在有网络的机器上构建项目
- [ ] 已打包所有必要文件（包含 node_modules）
- [ ] 已传输到目标服务器
- [ ] 目标服务器已安装 Node.js
- [ ] 已配置 .env 文件
- [ ] 数据库连接测试成功

### 部署后

- [ ] 后端进程正在运行
- [ ] 前端进程正在运行
- [ ] 端口 3000 和 5173 已监听
- [ ] 防火墙规则已配置
- [ ] 可以从浏览器访问
- [ ] 可以注册和登录
- [ ] 数据正常写入数据库

---

## 🛠️ 常用命令

### PM2 方式

```bash
# 查看进程
sudo pm2 list

# 查看日志
sudo pm2 logs

# 重启服务
sudo pm2 restart all

# 停止服务
sudo pm2 stop all

# 查看资源使用
sudo pm2 monit
```

### systemd 方式

```bash
# 重启服务
sudo systemctl restart ops-workflow-api
sudo systemctl restart ops-workflow-frontend

# 停止服务
sudo systemctl stop ops-workflow-api
sudo systemctl stop ops-workflow-frontend

# 查看日志
sudo journalctl -u ops-workflow-api -f
sudo journalctl -u ops-workflow-frontend -f

# 查看状态
sudo systemctl status ops-workflow-*
```

### nohup 方式

```bash
# 查看进程
ps aux | grep node

# 查看日志
tail -f logs/api-out.log
tail -f logs/frontend-out.log

# 手动停止
kill $(cat logs/api.pid)
kill $(cat logs/frontend.pid)
```

---

## 📞 故障排查

### 问题：端口被占用

```bash
# 查看端口占用
sudo netstat -tulpn | grep -E "3000|5173"

# 杀掉占用进程
sudo kill -9 <PID>
```

### 问题：权限不足

```bash
# 修改文件权限
sudo chown -R root:root /opt/ops-workflow-center
sudo chmod -R 755 /opt/ops-workflow-center

# 确保日志目录可写
sudo mkdir -p logs uploads
sudo chmod -R 777 logs uploads
```

### 问题：Node.js 版本不对

```bash
# 检查版本
node --version

# 如果版本低于 18，需要升级
# 可以使用 nvm 或从官网下载离线包
```

---

## 📚 相关文档

- [OCEANBASE_QUICKSTART.md](OCEANBASE_QUICKSTART.md) - OceanBase 快速配置
- [OCEANBASE_CONFIG.md](OCEANBASE_CONFIG.md) - 配置详解
- [MySQL部署操作手册.md](MySQL部署操作手册.md) - 详细部署指南

---

**更新时间**: 2024-01-18

**推荐方案**: PM2 或 systemd
