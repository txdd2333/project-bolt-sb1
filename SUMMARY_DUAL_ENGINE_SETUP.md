# 双引擎架构配置总结

## 🎉 配置完成！

您的项目现在支持**双引擎架构**，可以在 Supabase（云端）和 MySQL/OceanBase（本地）之间无缝切换！

---

## 📦 新增文件清单

### 核心文档（必读）

| 文件 | 说明 | 优先级 |
|------|------|--------|
| **QUICKSTART_DUAL_ENGINE.md** | 快速上手指南（30 秒理解） | ⭐⭐⭐⭐⭐ |
| **DUAL_ENGINE_GUIDE.md** | 完整使用指南（详细说明） | ⭐⭐⭐⭐⭐ |
| **DUAL_ENGINE_QUICK_REF.md** | 快速参考卡片（速查表） | ⭐⭐⭐⭐ |
| **ARCHITECTURE_DUAL_ENGINE.md** | 架构详解（技术细节） | ⭐⭐⭐ |

### 配置文件

| 文件 | 说明 |
|------|------|
| `.env.supabase` | Supabase 引擎配置（预设） |
| `.env.mysql` | MySQL/OceanBase 引擎配置（预设） |
| `.env` | 当前使用的配置 |

### 切换脚本

| 文件 | 平台 | 说明 |
|------|------|------|
| `switch-to-supabase.sh` | Linux/Mac | 切换到 Supabase |
| `switch-to-mysql.sh` | Linux/Mac | 切换到 MySQL |
| `switch-to-supabase.bat` | Windows | 切换到 Supabase |
| `switch-to-mysql.bat` | Windows | 切换到 MySQL |

### 其他文档

| 文件 | 说明 |
|------|------|
| **WINDOWS_QUICKSTART.md** | Windows 开发快速指南 |
| **NODEJS_VERSION_COMPATIBILITY.md** | Node.js 版本兼容性说明 |
| **DEPLOYMENT_STRATEGY.md** | 部署策略建议 |

---

## 🚀 立即开始

### 方法 1: 使用 Supabase（推荐先试这个）

```bash
# Windows
.\switch-to-supabase.bat
npm run dev

# Linux/Mac
bash switch-to-supabase.sh
npm run dev

# 访问 http://localhost:5173
```

**优势**：
- ⚡ 无需配置数据库
- ⚡ 5 分钟启动
- ⚡ 适合快速开发

---

### 方法 2: 使用 MySQL/OceanBase

```bash
# Windows
.\switch-to-mysql.bat
# 终端 1
npm run server
# 终端 2
npm run dev

# Linux/Mac
bash switch-to-mysql.sh
npm run server &
npm run dev

# 访问 http://localhost:5173
```

**优势**：
- 🏠 数据本地存储
- 🏠 连接真实生产库
- 🏠 内网访问

---

## 📊 架构概览

```
┌─────────────────────────────────────────────────────────┐
│              一套代码，两个引擎                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│   React 应用                                             │
│        ↓                                                │
│   ServiceFactory（自动选择）                             │
│        ↓                                                │
│   ┌──────────┬──────────┐                              │
│   │          │          │                              │
│   │ Supabase │  Custom  │                              │
│   │  引擎    │   引擎   │                              │
│   │          │          │                              │
│   └──────────┴──────────┘                              │
│        ↓            ↓                                   │
│    PostgreSQL   MySQL/OceanBase                         │
│    （云端）     （本地）                                 │
│                                                          │
└─────────────────────────────────────────────────────────┘

切换方式：修改 .env 中的 VITE_SERVICE_PROVIDER
```

---

## 🎯 使用场景推荐

### 场景 1: 云端快速开发（当前可用）

```
团队：多人协作开发
环境：Bolt.new 或本地 Windows
引擎：Supabase
配置：bash switch-to-supabase.sh

优势：
✅ 零配置启动
✅ 自动备份
✅ 多人实时协作
✅ 无需维护数据库
```

### 场景 2: 本地功能测试

```
团队：个人或小团队
环境：Windows 开发机
引擎：Custom（连接远程 OceanBase）
配置：bash switch-to-mysql.sh

优势：
✅ 连接真实数据
✅ 测试生产环境
✅ 性能验证
✅ 离线开发
```

### 场景 3: 生产环境部署

```
团队：运维团队
环境：CentOS 7 服务器
引擎：Custom（本地 OceanBase）
配置：.env.production

优势：
✅ 数据完全控制
✅ 无外网依赖
✅ 最低延迟
✅ 符合安全要求
```

---

## 🔄 典型工作流

### 推荐工作流

```
阶段 1: 原型开发（1-2 周）
├─ 使用 Supabase
├─ 快速迭代功能
└─ UI/UX 调优
      ↓
阶段 2: 功能测试（3-5 天）
├─ 切换到 MySQL
├─ 连接生产数据库
└─ 性能和兼容性测试
      ↓
阶段 3: 生产部署（1 天）
├─ 部署到 CentOS 7
├─ 使用本地 MySQL/OceanBase
└─ 正式上线
```

### 操作步骤

```bash
# 阶段 1: Supabase 开发
bash switch-to-supabase.sh
npm run dev
# 开发功能...

# 阶段 2: 本地测试
bash switch-to-mysql.sh
npm run server &
npm run dev
# 测试功能...

# 阶段 3: 生产部署
scp -r project/* root@服务器:/opt/ops-workflow-center/
ssh root@服务器
cd /opt/ops-workflow-center
bash deploy-without-docker.sh
```

---

## 🔧 技术实现

### 前端自动适配

所有页面和组件自动适配两个引擎，**无需修改代码**：

```typescript
// 组件中的代码（完全相同）
import ServiceFactory from '@/services/ServiceFactory'

function MyComponent() {
  const dataService = ServiceFactory.getDataService()

  // 自动选择引擎
  const { data } = await dataService.query('workflows')

  // Supabase: 调用 Supabase API
  // Custom: 调用 Express API
}
```

### 后端透明切换

```bash
# Supabase 模式
VITE_SERVICE_PROVIDER=supabase
# → 前端直接调用 Supabase
# → 无需后端服务器

# Custom 模式
VITE_SERVICE_PROVIDER=custom
# → 前端调用 Express API
# → Express 连接 MySQL/OceanBase
```

---

## 📋 配置参数对照表

### Supabase 配置

```env
VITE_SERVICE_PROVIDER=supabase
VITE_SUPABASE_URL=https://0ec90b57d6e95fcbda19832f.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOi...
```

| 参数 | 说明 | 获取方式 |
|------|------|---------|
| `VITE_SUPABASE_URL` | Supabase 项目 URL | Dashboard → Settings → API |
| `VITE_SUPABASE_ANON_KEY` | 匿名访问密钥 | Dashboard → Settings → API |

### MySQL/OceanBase 配置

```env
VITE_SERVICE_PROVIDER=custom
VITE_API_URL=http://localhost:3000
DB_HOST=192.168.1.70
DB_PORT=2883
DB_USER=root@Tianji4_MySQL#Tianji4
DB_PASSWORD=aaAA11__
DB_DATABASE=ops_workflow_center
JWT_SECRET=your-secret-key
```

| 参数 | 说明 | 示例 |
|------|------|------|
| `VITE_API_URL` | API 服务器地址 | http://localhost:3000 |
| `DB_HOST` | 数据库主机 | 192.168.1.70 |
| `DB_PORT` | 数据库端口 | 2883（OceanBase）/ 3306（MySQL） |
| `DB_USER` | 数据库用户 | root@租户#集群（OceanBase）/ root（MySQL） |
| `DB_PASSWORD` | 数据库密码 | - |
| `DB_DATABASE` | 数据库名称 | ops_workflow_center |
| `JWT_SECRET` | JWT 签名密钥 | 随机字符串（生产环境必改） |

---

## ✅ 验证清单

### Supabase 引擎

- [ ] 配置文件：`.env.supabase` 存在
- [ ] 环境变量：`VITE_SERVICE_PROVIDER=supabase`
- [ ] Supabase URL 配置正确
- [ ] Supabase Anon Key 配置正确
- [ ] 前端启动：`npm run dev` 成功
- [ ] 页面访问：http://localhost:5173 正常
- [ ] 用户注册：可以创建新用户
- [ ] 数据操作：可以 CRUD 数据

### MySQL/OceanBase 引擎

- [ ] 配置文件：`.env.mysql` 存在
- [ ] 环境变量：`VITE_SERVICE_PROVIDER=custom`
- [ ] 数据库连接配置正确
- [ ] API 服务器启动：`npm run server` 成功
- [ ] 前端启动：`npm run dev` 成功
- [ ] 页面访问：http://localhost:5173 正常
- [ ] 用户注册：可以创建新用户
- [ ] 数据操作：可以 CRUD 数据
- [ ] 数据库验证：数据写入 MySQL/OceanBase

---

## 🐛 常见问题

### Q1: 切换引擎后看不到之前的数据？

**A**: 这是正常的！两个引擎使用**完全独立**的数据库。

```
Supabase 数据 → 存储在 Supabase PostgreSQL
MySQL 数据 → 存储在本地 MySQL/OceanBase

切换引擎 = 切换数据库
```

如需数据迁移，请使用数据导入/导出工具。

---

### Q2: Custom 引擎启动失败？

**症状**：
```
Error: connect ECONNREFUSED
Error: Access denied
```

**解决**：

```bash
# 1. 检查 API 服务器是否运行
ps aux | grep "node.*server"

# 2. 启动 API 服务器
npm run server

# 3. 测试数据库连接
mysql -h192.168.1.70 -P2883 -u'root@Tianji4_MySQL#Tianji4' -p

# 4. 检查防火墙
# 确保端口 2883 和 3000 开放
```

---

### Q3: Supabase 提示项目未找到？

**症状**：
```
Error: Project not found
Error: Invalid API key
```

**解决**：

```bash
# 1. 检查配置
cat .env | grep SUPABASE

# 2. 验证 Supabase 项目
# 登录 https://supabase.com
# 检查项目是否暂停（免费版 7 天无活动会暂停）

# 3. 重新获取密钥
# Dashboard → Settings → API
# 复制 URL 和 anon key
```

---

### Q4: 能否同时使用两个引擎？

**A**: 当前是**单选模式**，同一时间只能使用一个引擎。

如需同时使用（例如数据同步），需要：
1. 开发数据同步服务
2. 监听两个数据库的变化
3. 自动同步数据

这个功能可以作为后续扩展。

---

## 📞 获取帮助

### 文档索引

| 问题 | 查看文档 |
|------|---------|
| 如何快速开始？ | [QUICKSTART_DUAL_ENGINE.md](QUICKSTART_DUAL_ENGINE.md) |
| 详细使用说明？ | [DUAL_ENGINE_GUIDE.md](DUAL_ENGINE_GUIDE.md) |
| 命令速查？ | [DUAL_ENGINE_QUICK_REF.md](DUAL_ENGINE_QUICK_REF.md) |
| 架构原理？ | [ARCHITECTURE_DUAL_ENGINE.md](ARCHITECTURE_DUAL_ENGINE.md) |
| Windows 开发？ | [WINDOWS_QUICKSTART.md](WINDOWS_QUICKSTART.md) |
| 生产部署？ | [START_HERE_CENTOS7.md](START_HERE_CENTOS7.md) |
| Node.js 版本？ | [NODEJS_VERSION_COMPATIBILITY.md](NODEJS_VERSION_COMPATIBILITY.md) |

---

## 🎯 下一步行动

### 立即尝试

```bash
# 1. 试用 Supabase（推荐）
bash switch-to-supabase.sh
npm run dev
# 访问 http://localhost:5173，注册用户，创建数据

# 2. 切换到 MySQL
bash switch-to-mysql.sh
npm run server
npm run dev
# 注意：数据是独立的，Supabase 的数据不会出现在这里

# 3. 对比体验
# 感受两个引擎的速度、功能差异
```

### 推荐阅读顺序

1. [QUICKSTART_DUAL_ENGINE.md](QUICKSTART_DUAL_ENGINE.md) - 5 分钟了解基础
2. [DUAL_ENGINE_GUIDE.md](DUAL_ENGINE_GUIDE.md) - 15 分钟深入理解
3. [WINDOWS_QUICKSTART.md](WINDOWS_QUICKSTART.md) - 开始 Windows 开发
4. [ARCHITECTURE_DUAL_ENGINE.md](ARCHITECTURE_DUAL_ENGINE.md) - 技术深入（可选）

---

## 🌟 核心优势总结

```
✅ 一套代码 - 无需修改业务逻辑
✅ 两个引擎 - Supabase + MySQL/OceanBase
✅ 随意切换 - 一行配置即可
✅ 零学习成本 - 业务代码完全透明
✅ 最佳实践 - 开发用云，生产用本地
```

---

**恭喜！您的项目现在支持双引擎架构了！**

**开始探索吧：`bash switch-to-supabase.sh && npm run dev`**

---

更新时间：2024-01-18
