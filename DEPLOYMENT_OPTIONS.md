# 部署方案选择指南

## 🎯 推荐方案：Docker 部署（CentOS 7）

**适用场景**:
- ✅ CentOS 7 或更低版本系统
- ✅ 不想手动编译 Node.js
- ✅ 需要稳定可靠的部署方式
- ✅ 生产环境标准方案

**优势**:
- 环境完全隔离，不影响系统
- 一键部署，5分钟上线
- 内置所有依赖（Node.js 18, Playwright）
- 易于管理和维护
- 可快速回滚和更新

**部署时间**: 5-10 分钟（首次构建）

**操作步骤**:
```bash
cd /opt/ops-workflow-center
sudo bash docker-deploy.sh
```

详细文档: [DOCKER_QUICKSTART.md](./DOCKER_QUICKSTART.md)

---

## 🔄 备选方案对比

### 方案 A: CentOS 7 + Docker（推荐 ⭐⭐⭐⭐⭐）

| 项目 | 说明 |
|------|------|
| 系统要求 | CentOS 7 |
| 部署难度 | ⭐ 极简（一键脚本） |
| 维护成本 | ⭐ 极低 |
| 稳定性 | ⭐⭐⭐⭐⭐ 生产级 |
| 是否需要重装 | ❌ 否 |
| 部署时间 | 5-10 分钟 |

### 方案 B: Rocky Linux 8 原生部署（备选 ⭐⭐⭐⭐）

| 项目 | 说明 |
|------|------|
| 系统要求 | Rocky Linux 8 / AlmaLinux 8 |
| 部署难度 | ⭐⭐ 简单 |
| 维护成本 | ⭐⭐ 低 |
| 稳定性 | ⭐⭐⭐⭐ 稳定 |
| 是否需要重装 | ✅ 是 |
| 部署时间 | 30 分钟（含系统安装） |

### 方案 C: CentOS 8（不推荐 ❌）

**原因**: CentOS 8 已于 2021年12月31日 EOL（停止维护）
- 无安全更新
- 社区不再支持
- 存在安全隐患

---

## 📊 部署方案决策树

```
你的服务器是什么系统？
│
├─ CentOS 7
│  └─ 推荐: Docker 部署 ✅
│     └─ 文档: DOCKER_QUICKSTART.md
│
├─ CentOS 8
│  └─ 不推荐（已 EOL）❌
│     └─ 建议: 升级到 Rocky Linux 8
│
├─ Rocky Linux 8 / AlmaLinux 8
│  └─ 两种方案都可以:
│     ├─ 方案1: Docker 部署 ✅ (更灵活)
│     └─ 方案2: 原生部署 ✅ (更简洁)
│
└─ Ubuntu / Debian
   └─ 推荐: Docker 部署 ✅
      └─ 文档: DOCKER_QUICKSTART.md
```

---

## 🚀 快速开始

### 1️⃣ Docker 部署（推荐）

```bash
# 进入项目目录
cd /opt/ops-workflow-center

# 一键部署
sudo bash docker-deploy.sh

# 访问应用
# 前端: http://服务器IP:5173
# 后端: http://服务器IP:3000
```

完整文档: [DOCKER_QUICKSTART.md](./DOCKER_QUICKSTART.md)

### 2️⃣ Rocky Linux 8 原生部署

```bash
# 1. 安装 Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# 2. 安装依赖
cd /opt/ops-workflow-center
npm install

# 3. 构建项目
npm run build
npm run server:build

# 4. 使用 PM2 启动
npm install -g pm2
pm2 start ecosystem.config.cjs
pm2 save
pm2 startup
```

---

## ⚙️ 配置清单

无论选择哪种方案，都需要：

### 1. 环境变量配置

确保 `.env` 文件包含：

```bash
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 2. 防火墙配置

```bash
# 开放前端端口
sudo firewall-cmd --permanent --add-port=5173/tcp

# 开放后端端口
sudo firewall-cmd --permanent --add-port=3000/tcp

# 重载防火墙
sudo firewall-cmd --reload
```

### 3. 云服务器安全组

在云控制台添加入站规则：
- 端口 5173 (HTTP)
- 端口 3000 (HTTP)

---

## 📁 项目文件结构

```
ops-workflow-center/
├── Dockerfile                 # Docker 镜像配置
├── docker-compose.yml         # Docker 编排配置
├── docker-deploy.sh           # 一键部署脚本
├── DOCKER_QUICKSTART.md       # Docker 快速指南
├── DOCKER_DEPLOYMENT.md       # Docker 详细文档
├── ecosystem.config.cjs       # PM2 进程管理配置
├── .env                       # 环境变量（需配置）
├── package.json               # 项目依赖
├── src/                       # 前端源码
├── server/                    # 后端源码
└── logs/                      # 日志目录（自动创建）
```

---

## 🔍 方案对比总结

| 特性 | Docker 部署 | Rocky Linux 原生 | CentOS 7 原生 |
|------|------------|-----------------|---------------|
| 部署难度 | ⭐ 极简 | ⭐⭐ 简单 | ⭐⭐⭐⭐⭐ 极难 |
| 系统要求 | 任意 | Rocky 8+ | ❌ 不推荐 |
| 环境隔离 | ✅ 是 | ❌ 否 | ❌ 否 |
| 易于迁移 | ✅ 是 | ❌ 否 | ❌ 否 |
| Playwright 支持 | ✅ 完美 | ✅ 好 | ❌ 困难 |
| 资源占用 | 适中 | 低 | 低 |
| 生产推荐 | ✅ 强烈推荐 | ✅ 推荐 | ❌ 不推荐 |

---

## 💡 为什么推荐 Docker？

1. **零系统污染**: 所有依赖在容器内，删除容器即可完全清理
2. **版本管理**: 可同时运行不同版本，方便测试和回滚
3. **标准化**: 相同的环境在任何服务器上都能运行
4. **简化运维**: 启动、停止、重启都是一行命令
5. **资源控制**: 可限制 CPU 和内存使用
6. **日志管理**: 统一的日志收集和查看方式
7. **快速恢复**: 容器崩溃自动重启
8. **易于扩展**: 需要时可快速扩展到多台服务器

---

## 📞 获取帮助

### 文档索引

- **快速开始**: [DOCKER_QUICKSTART.md](./DOCKER_QUICKSTART.md)
- **详细文档**: [DOCKER_DEPLOYMENT.md](./DOCKER_DEPLOYMENT.md)
- **开发指南**: [DEVELOPMENT.md](./DEVELOPMENT.md)
- **数据库文档**: [DATABASE.md](./DATABASE.md)

### 常见问题

**Q: Docker 会占用很多资源吗？**
A: 不会，Docker 容器比虚拟机轻量得多，额外开销很小。

**Q: 我对 Docker 不熟悉，学习成本高吗？**
A: 不高，日常使用只需要 5 个命令，10分钟就能学会。

**Q: Docker 部署稳定吗？**
A: 非常稳定，Docker 是业界标准，阿里、腾讯等大厂都在用。

**Q: 可以在 CentOS 7 上直接装 Node.js 18 吗？**
A: 理论可以但极其复杂，需要手动编译 glibc，容易破坏系统。

**Q: CentOS 8 还能用吗？**
A: 不建议，已停止维护，无安全更新，建议升级到 Rocky Linux 8。

---

## ⚡ 立即开始

### 推荐流程

1. **上传项目文件** 到 `/opt/ops-workflow-center`
2. **配置 .env** 文件（Supabase 连接信息）
3. **运行部署脚本**: `sudo bash docker-deploy.sh`
4. **访问应用**: `http://服务器IP:5173`

就这么简单！

---

**更新时间**: 2024-01-18

**支持系统**: CentOS 7+, Rocky Linux 8+, Ubuntu 20.04+, Debian 10+
