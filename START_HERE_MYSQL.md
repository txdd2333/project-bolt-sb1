# OPS Workflow Center - 开始部署

## 🎯 本项目使用 MySQL/OceanBase 数据库

---

## 📖 选择您的部署方式

### 推荐：Docker 一键部署

适合生产环境，稳定可靠，5 分钟完成部署。

👉 **[查看 MySQL 部署操作手册](MySQL部署操作手册.md)** - 详细分步骤指南

---

## 🚀 快速开始（5步完成）

### 1️⃣ 初始化数据库

```bash
# 连接到 MySQL/OceanBase 数据库
mysql -h 数据库地址 -u root -p

# 执行初始化脚本
source scripts/init-mysql-database.sql
```

### 2️⃣ 配置环境变量

```bash
# 复制配置模板
cp .env.example .env

# 编辑配置
vi .env
```

配置示例：

```bash
VITE_SERVICE_PROVIDER=custom
DB_HOST=192.168.1.100        # 改为您的数据库地址
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password    # 改为您的密码
DB_DATABASE=ops_workflow_center
JWT_SECRET=random-secret-key # 改为随机字符串
```

### 3️⃣ 一键部署

```bash
sudo bash docker-deploy.sh
```

### 4️⃣ 配置防火墙

```bash
sudo firewall-cmd --permanent --add-port=5173/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

### 5️⃣ 访问应用

- 前端: `http://服务器IP:5173`
- 后端: `http://服务器IP:3000`

---

## 📚 完整文档导航

| 文档 | 说明 | 适合人群 |
|------|------|---------|
| **[MySQL部署操作手册.md](MySQL部署操作手册.md)** | 详细分步骤操作指南 | ⭐ 新手必看 |
| **[MYSQL_DEPLOYMENT.md](MYSQL_DEPLOYMENT.md)** | 完整技术文档 | 运维人员 |
| **[DOCKER_QUICKSTART.md](DOCKER_QUICKSTART.md)** | Docker 命令速查 | 快速参考 |
| **[.env.example](.env.example)** | 环境变量配置模板 | 配置参考 |
| **[scripts/init-mysql-database.sql](scripts/init-mysql-database.sql)** | 数据库初始化脚本 | 数据库管理 |

---

## 💡 重要说明

### 数据库支持

本项目支持以下数据库：

- ✅ MySQL 5.7+
- ✅ MySQL 8.0+
- ✅ OceanBase MySQL 模式
- ✅ MariaDB 10.3+

### 关键配置

**必须在 .env 中设置：**

```bash
VITE_SERVICE_PROVIDER=custom  # 必须是 custom，不是 supabase
```

这个配置决定了应用使用自定义的 MySQL 后端，而不是 Supabase。

### 网络要求

- 应用服务器能访问数据库服务器
- 防火墙开放端口 5173 (前端) 和 3000 (后端)
- 如果是云服务器，记得配置安全组

---

## 🔧 系统要求

- **操作系统**: CentOS 7+, Rocky Linux 8+, Ubuntu 20.04+
- **内存**: 最少 2GB
- **磁盘**: 最少 10GB 可用空间
- **数据库**: MySQL 5.7+ 或 OceanBase MySQL 模式
- **权限**: root 或 sudo 权限

---

## 📦 部署包准备

如果需要从本地上传到服务器：

```bash
# 1. 打包项目
bash pack-for-deploy.sh

# 2. 上传到服务器
scp ops-workflow-center-*.tar.gz root@服务器IP:/opt/

# 3. 在服务器解压
cd /opt
tar -xzf ops-workflow-center-*.tar.gz
cd ops-workflow-center

# 4. 继续上面的配置和部署步骤
```

---

## ⚠️ 常见问题

### Q: 必须使用 Docker 吗？

A: 强烈推荐使用 Docker，它会自动处理所有依赖（Node.js、Playwright 等），避免环境问题。

### Q: 数据存在哪里？

A:
- 业务数据：存储在您的 MySQL/OceanBase 数据库中
- 上传文件：存储在 `./uploads/` 目录
- 日志文件：存储在 `./logs/` 目录

### Q: 可以连接云数据库吗？

A: 可以！只需在 .env 中配置云数据库的地址和凭证即可。

### Q: 端口可以修改吗？

A: 可以。编辑 `docker-compose.yml` 中的 `ports` 配置。

### Q: 如何查看日志？

A:
```bash
sudo docker-compose logs -f
```

### Q: 服务启动失败怎么办？

A:
1. 查看日志: `sudo docker-compose logs`
2. 检查数据库连接: `mysql -h DB_HOST -u DB_USER -p`
3. 验证配置: `cat .env`

---

## 🎯 架构说明

```
┌─────────────────────────────────────┐
│     Docker Container                │
│                                     │
│  ┌──────────────┐  ┌─────────────┐ │
│  │   Frontend   │  │   Backend   │ │
│  │   (Vite)     │  │   (Node.js) │ │
│  │   :5173      │  │   :3000     │ │
│  └──────────────┘  └─────────────┘ │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   Playwright Service         │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
              │
              ▼
     ┌────────────────┐
     │  MySQL/        │
     │  OceanBase     │
     └────────────────┘
```

---

## 🔐 安全建议

1. 修改 JWT_SECRET 为随机字符串
2. 使用强数据库密码
3. 限制数据库远程访问IP
4. 定期备份数据库
5. 及时更新系统和应用

---

## 📞 需要帮助？

### 第一步：查看文档

- 新手请看: **[MySQL部署操作手册.md](MySQL部署操作手册.md)**
- 详细文档: **[MYSQL_DEPLOYMENT.md](MYSQL_DEPLOYMENT.md)**

### 第二步：检查日志

```bash
# 查看应用日志
sudo docker-compose logs

# 查看数据库连接
mysql -h DB_HOST -u DB_USER -p -e "SELECT 1;"
```

### 第三步：验证配置

```bash
# 检查环境变量
cat .env

# 检查容器状态
sudo docker-compose ps

# 检查端口
sudo netstat -tulpn | grep -E "5173|3000"
```

---

## ✅ 部署检查清单

部署完成后，确认以下项目：

- [ ] 数据库已初始化（执行了 SQL 脚本）
- [ ] .env 文件已正确配置
- [ ] VITE_SERVICE_PROVIDER=custom
- [ ] 数据库连接正常
- [ ] Docker 容器正在运行
- [ ] 前端可访问 (http://服务器IP:5173)
- [ ] 后端可访问 (http://服务器IP:3000)
- [ ] 防火墙已配置
- [ ] 可以注册和登录

---

## 🚀 立即开始

1. **查看详细指南**: [MySQL部署操作手册.md](MySQL部署操作手册.md)
2. **初始化数据库**: 执行 `scripts/init-mysql-database.sql`
3. **配置环境**: 编辑 `.env` 文件
4. **一键部署**: 运行 `sudo bash docker-deploy.sh`

---

**预计部署时间**: 15-20 分钟

**技术支持**: 查看文档或检查日志

---

更新时间: 2024-01-18

版本: v1.0.0 (MySQL Edition)
