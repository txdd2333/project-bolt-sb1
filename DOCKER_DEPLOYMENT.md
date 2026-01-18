# Docker 部署指南

## 快速开始（5分钟部署）

### 方式一：一键部署（推荐）

```bash
# 1. 上传项目到服务器
cd /opt
# 将项目文件解压到当前目录

# 2. 进入项目目录
cd ops-workflow-center

# 3. 运行一键部署脚本
sudo bash docker-deploy.sh
```

部署脚本会自动：
- ✅ 检查并安装 Docker
- ✅ 检查并安装 Docker Compose
- ✅ 验证环境配置
- ✅ 构建 Docker 镜像
- ✅ 启动服务

### 方式二：手动部署

如果一键脚本失败，可以手动执行以下步骤：

#### 步骤 1: 安装 Docker

```bash
# 安装依赖
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# 添加 Docker 仓库
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 安装 Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
docker --version
```

#### 步骤 2: 安装 Docker Compose

```bash
# 下载 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 添加执行权限
sudo chmod +x /usr/local/bin/docker-compose

# 创建软链接
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# 验证安装
docker-compose --version
```

#### 步骤 3: 配置环境变量

确保项目根目录有 `.env` 文件，内容如下：

```bash
# Supabase 配置
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key

# 其他配置（可选）
NODE_ENV=production
```

#### 步骤 4: 构建并启动

```bash
# 进入项目目录
cd /opt/ops-workflow-center

# 创建数据目录
mkdir -p logs uploads
sudo chmod 777 logs uploads

# 构建镜像（首次需要 5-10 分钟）
sudo docker-compose build

# 启动服务
sudo docker-compose up -d

# 查看启动日志
sudo docker-compose logs -f
```

## 验证部署

### 检查容器状态

```bash
# 查看运行中的容器
sudo docker-compose ps

# 应该看到类似输出：
# NAME                    STATUS          PORTS
# ops-workflow-center     Up 2 minutes    0.0.0.0:3000->3000/tcp, 0.0.0.0:5173->5173/tcp
```

### 测试服务

```bash
# 测试前端（应返回 HTML）
curl http://localhost:5173

# 测试后端 API（应返回 JSON）
curl http://localhost:3000/api/health
```

### 浏览器访问

1. **前端页面**: `http://服务器IP:5173`
2. **后端 API**: `http://服务器IP:3000`

## 常用管理命令

### 日志管理

```bash
# 查看实时日志
sudo docker-compose logs -f

# 查看特定服务日志
sudo docker-compose logs -f app

# 查看最近 100 行日志
sudo docker-compose logs --tail=100

# 查看应用日志文件
tail -f logs/api-server.log
tail -f logs/workflow-runner.log
```

### 服务管理

```bash
# 启动服务
sudo docker-compose up -d

# 停止服务
sudo docker-compose down

# 重启服务
sudo docker-compose restart

# 重新构建并启动
sudo docker-compose up -d --build

# 查看容器状态
sudo docker-compose ps

# 进入容器
sudo docker exec -it ops-workflow-center bash
```

### 更新部署

```bash
# 1. 停止服务
sudo docker-compose down

# 2. 拉取最新代码/上传新文件
# ...

# 3. 重新构建
sudo docker-compose build --no-cache

# 4. 启动服务
sudo docker-compose up -d
```

### 清理资源

```bash
# 停止并删除容器
sudo docker-compose down

# 删除镜像
sudo docker rmi ops-workflow-center_app

# 清理未使用的镜像和容器
sudo docker system prune -a
```

## 数据持久化

以下目录会自动持久化到宿主机：

- `./logs/` - 应用日志文件
- `./uploads/` - 用户上传的文件

这些数据即使删除容器也不会丢失。

## 端口配置

默认端口：
- **5173** - 前端服务
- **3000** - 后端 API

如需修改端口，编辑 `docker-compose.yml`：

```yaml
ports:
  - "8080:5173"  # 将前端改为 8080 端口
  - "8000:3000"  # 将后端改为 8000 端口
```

## 防火墙配置

### CentOS 7 开放端口

```bash
# 开放前端端口
sudo firewall-cmd --permanent --add-port=5173/tcp

# 开放后端端口
sudo firewall-cmd --permanent --add-port=3000/tcp

# 重载防火墙
sudo firewall-cmd --reload

# 查看已开放端口
sudo firewall-cmd --list-ports
```

### 阿里云/腾讯云安全组

记得在云控制台的安全组中添加入站规则：
- 端口 5173 (前端)
- 端口 3000 (后端)

## 故障排查

### 容器无法启动

```bash
# 查看详细日志
sudo docker-compose logs

# 查看容器状态
sudo docker ps -a

# 检查环境变量
sudo docker-compose config
```

### 端口被占用

```bash
# 查看端口占用
sudo netstat -tulpn | grep 5173
sudo netstat -tulpn | grep 3000

# 停止占用端口的进程
sudo kill -9 <PID>
```

### 构建失败

```bash
# 清理缓存重新构建
sudo docker-compose build --no-cache

# 检查磁盘空间
df -h
```

### 无法访问服务

```bash
# 检查防火墙
sudo firewall-cmd --list-all

# 检查 SELinux
sudo getenforce
# 如果是 Enforcing，临时关闭测试
sudo setenforce 0

# 检查容器网络
sudo docker network ls
sudo docker network inspect ops-workflow-center_ops-network
```

## 性能优化

### 资源限制

编辑 `docker-compose.yml` 添加资源限制：

```yaml
services:
  app:
    # ... 其他配置
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### 日志轮转

防止日志文件过大：

```bash
# 创建 Docker 日志轮转配置
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# 重启 Docker
sudo systemctl restart docker
```

## 备份与恢复

### 备份

```bash
# 备份数据目录
tar -czf backup-$(date +%Y%m%d).tar.gz logs uploads .env

# 导出 Docker 镜像
sudo docker save ops-workflow-center_app > ops-workflow-center-image.tar
```

### 恢复

```bash
# 恢复数据目录
tar -xzf backup-20240118.tar.gz

# 导入 Docker 镜像
sudo docker load < ops-workflow-center-image.tar
```

## 监控

### 查看资源使用

```bash
# 实时监控
sudo docker stats ops-workflow-center

# 查看容器进程
sudo docker top ops-workflow-center
```

### 健康检查

```bash
# 检查健康状态
sudo docker inspect --format='{{json .State.Health}}' ops-workflow-center | jq
```

## 生产环境建议

1. **使用反向代理**: 建议使用 Nginx 作为反向代理
2. **配置 HTTPS**: 使用 Let's Encrypt 配置 SSL 证书
3. **定期备份**: 设置定时任务自动备份数据
4. **监控告警**: 接入监控系统（如 Prometheus）
5. **日志收集**: 配置日志收集系统（如 ELK）

## 需要帮助？

如果遇到问题：

1. 查看日志: `sudo docker-compose logs -f`
2. 检查容器状态: `sudo docker-compose ps`
3. 验证环境配置: `cat .env`
4. 检查网络连接: `curl http://localhost:5173`

---

更新时间: 2024-01-18
