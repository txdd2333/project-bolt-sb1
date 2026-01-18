# 本地部署说明

> 如何将项目部署到 CentOS 服务器（使用 OceanBase MySQL 租户）

---

## 🎯 快速开始

### 方式一：自动化部署（推荐）

#### 1. 在本地打包项目

```bash
# 进入项目目录
cd /path/to/ops-workflow-center

# 执行打包脚本
./scripts/package.sh

# 生成文件：ops-workflow-center_YYYYMMDD_HHMMSS.tar.gz
```

#### 2. 上传到服务器

```bash
scp ops-workflow-center_*.tar.gz root@your-server-ip:/root/
```

#### 3. 在服务器上部署

```bash
# SSH 连接到服务器
ssh root@your-server-ip

# 解压项目
mkdir -p /opt/ops-workflow-center
cd /opt/ops-workflow-center
tar -xzf /root/ops-workflow-center_*.tar.gz

# 一键部署（安装依赖、初始化数据库、构建、启动）
./scripts/deploy.sh
```

---

### 方式二：手动部署

详细步骤请参考：**[QUICKSTART_LOCAL_DEPLOYMENT.md](./QUICKSTART_LOCAL_DEPLOYMENT.md)**

---

## 📚 完整文档

| 文档 | 说明 |
|------|------|
| [QUICKSTART_LOCAL_DEPLOYMENT.md](./QUICKSTART_LOCAL_DEPLOYMENT.md) | 快速部署手册（简化版） |
| [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) | 详细部署指南（完整版） |
| [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) | 架构设计文档 |
| [HANDOVER_DOCUMENT.md](./HANDOVER_DOCUMENT.md) | 项目交接文档 |

---

## 🔑 关键配置

### 数据库连接（.env.server）

```bash
DB_HOST=192.168.1.70
DB_PORT=2883
DB_USER=root@Tianji4_MySQL#Tianji4
DB_PASSWORD=aaAA11__
DB_DATABASE=ops_workflow_center
JWT_SECRET=<使用 openssl rand -base64 64 生成>
```

### 前端配置（.env.production）

```bash
VITE_SERVICE_PROVIDER=custom
VITE_API_URL=http://your-server-ip:3001
```

---

## 🚀 核心命令

### 打包项目
```bash
./scripts/package.sh
```

### 初始化数据库
```bash
./scripts/init-database.sh
```

### 一键部署
```bash
./scripts/deploy.sh
```

### 启动服务
```bash
pm2 start ecosystem.config.cjs
pm2 save
pm2 startup
```

### 查看状态
```bash
pm2 status
pm2 logs
```

---

## ✅ 部署验证

部署完成后，请验证：

```bash
# 1. 检查 API 服务
curl http://localhost:3001/health

# 2. 检查 Playwright 服务
curl http://localhost:3002/health

# 3. 访问前端
# 浏览器打开: http://your-server-ip/

# 4. 注册并登录测试
```

---

## 📞 故障排查

### 常见问题

1. **npm install 失败**
   ```bash
   npm config set registry https://registry.npmmirror.com
   npm cache clean --force
   npm install
   ```

2. **数据库连接失败**
   ```bash
   # 测试连接
   mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__

   # 检查配置
   cat .env.server
   ```

3. **PM2 启动失败**
   ```bash
   # 查看日志
   pm2 logs --lines 100

   # 手动测试
   tsx server/api-server.ts
   ```

4. **Nginx 403 错误**
   ```bash
   # 关闭 SELinux
   setenforce 0

   # 检查权限
   ls -la /opt/ops-workflow-center/dist/
   ```

---

## 🔄 架构对比

### Supabase 版本（开发环境）
```
前端 → Supabase (PostgreSQL + Auth + Storage)
```

### 本地部署版本（生产环境）
```
前端 → Nginx → API Server → OceanBase MySQL
              ↓
         Playwright Server
```

---

## 📊 系统要求

- **操作系统**: CentOS 7/8 或 RHEL 7/8
- **Node.js**: 18.x 或更高
- **MySQL 客户端**: 5.7+ 或 8.0+
- **内存**: 8GB+
- **磁盘**: 50GB+
- **网络**: 能访问 OceanBase 数据库

---

## 🎯 快速参考

```bash
# 【本地】打包
./scripts/package.sh

# 【本地】上传
scp ops-workflow-center_*.tar.gz root@server:/root/

# 【服务器】解压
mkdir -p /opt/ops-workflow-center && cd /opt/ops-workflow-center
tar -xzf /root/ops-workflow-center_*.tar.gz

# 【服务器】一键部署
./scripts/deploy.sh

# 【服务器】验证
pm2 status
curl http://localhost:3001/health
```

---

**提示**: 首次部署建议先阅读 `QUICKSTART_LOCAL_DEPLOYMENT.md`，遇到问题再查阅 `DEPLOYMENT_GUIDE.md` 详细文档。
