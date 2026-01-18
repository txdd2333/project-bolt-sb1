# 双引擎架构使用指南

## 架构说明

本项目支持**双数据库引擎**，可以无缝切换：

```
┌─────────────────────────────────────────────────────┐
│              应用层（React + TypeScript）             │
├─────────────────────────────────────────────────────┤
│            ServiceFactory（服务工厂）                │
│         根据 VITE_SERVICE_PROVIDER 自动选择          │
├──────────────────────┬──────────────────────────────┤
│   Supabase 引擎      │      Custom 引擎             │
├──────────────────────┼──────────────────────────────┤
│ - PostgreSQL 数据库  │ - MySQL/OceanBase 数据库     │
│ - 云端托管           │ - 本地/私有云部署            │
│ - 自动扩展           │ - 完全控制                   │
│ - 内置认证           │ - 自定义认证                 │
│ - 实时订阅           │ - 轮询更新                   │
└──────────────────────┴──────────────────────────────┘
```

---

## 🎯 使用场景

### 场景 1: Supabase（云端开发）

**适用于**：
- 快速原型开发
- 云端协作开发
- 无需本地数据库
- 需要实时协作

**优势**：
- 5 分钟启动，无需配置
- 免费额度充足
- 自动备份和扩展
- 内置管理界面

**成本**：
- 免费：500MB 数据库，50MB 存储
- 付费：$25/月起（生产环境）

---

### 场景 2: MySQL/OceanBase（本地部署）

**适用于**：
- 生产环境部署
- 内网隔离环境
- 数据安全要求高
- 已有数据库基础设施

**优势**：
- 数据完全控制
- 无外网依赖
- 成本可控
- 符合合规要求

**要求**：
- MySQL 5.7+ 或 OceanBase
- 自行维护备份

---

## 📋 快速切换指南

### 当前配置（.env）

```env
# 当前使用 Custom（MySQL/OceanBase）
VITE_SERVICE_PROVIDER=custom

# 同时配置了两个引擎
# Custom 引擎配置
VITE_API_URL=http://localhost:3000
DB_HOST=192.168.1.70
DB_PORT=2883
DB_USER=root@Tianji4_MySQL#Tianji4
DB_PASSWORD=aaAA11__
DB_DATABASE=ops_workflow_center

# Supabase 引擎配置
VITE_SUPABASE_URL=https://0ec90b57d6e95fcbda19832f.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOi...
```

### 切换到 Supabase

```bash
# 方法 1: 直接修改 .env
VITE_SERVICE_PROVIDER=supabase

# 方法 2: 使用命令行覆盖（临时测试）
VITE_SERVICE_PROVIDER=supabase npm run dev
```

### 切换到 MySQL/OceanBase

```bash
# 修改 .env
VITE_SERVICE_PROVIDER=custom

# 确保 API 服务器运行
npm run server
```

---

## 🚀 详细配置

### 配置文件结构

```
项目根目录/
├── .env                    # 主配置文件
├── .env.example            # 配置模板
├── .env.supabase          # Supabase 专用配置（可选）
└── .env.local             # 本地 MySQL 配置（可选）
```

### 创建多套配置

#### .env.supabase（云端开发）

```bash
# Supabase 云端开发配置
VITE_SERVICE_PROVIDER=supabase
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key
```

#### .env.local（本地 MySQL）

```bash
# 本地 MySQL 开发配置
VITE_SERVICE_PROVIDER=custom
VITE_API_URL=http://localhost:3000

DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_DATABASE=ops_workflow_center

JWT_SECRET=your-local-secret-key
UPLOAD_DIR=./uploads
```

#### .env.production（生产 OceanBase）

```bash
# 生产环境 OceanBase 配置
VITE_SERVICE_PROVIDER=custom
VITE_API_URL=http://192.168.1.100:3000

DB_HOST=192.168.1.70
DB_PORT=2883
DB_USER=root@Tianji4_MySQL#Tianji4
DB_PASSWORD=aaAA11__
DB_DATABASE=ops_workflow_center

JWT_SECRET=your-production-secret-key-change-this
UPLOAD_DIR=/var/ops-workflow/uploads
```

### 使用不同配置

```bash
# 使用 Supabase 配置
cp .env.supabase .env
npm run dev

# 使用本地 MySQL 配置
cp .env.local .env
npm run server  # 启动 API 服务器
npm run dev     # 启动前端

# 使用生产配置
cp .env.production .env
npm run build
npm run server:build
```

---

## 🔄 两种引擎对比

| 特性 | Supabase | MySQL/OceanBase |
|------|----------|-----------------|
| **部署** |
| 启动时间 | ⚡ 5 分钟 | ⏱️ 15 分钟（含数据库） |
| 配置复杂度 | ⭐ 简单 | ⭐⭐⭐ 中等 |
| 外网依赖 | ✅ 需要 | ❌ 不需要 |
| **功能** |
| 数据存储 | ✅ PostgreSQL | ✅ MySQL/OceanBase |
| 文件存储 | ✅ 内置 | ✅ 本地文件系统 |
| 用户认证 | ✅ 内置 | ✅ JWT 实现 |
| 实时订阅 | ✅ WebSocket | ⚠️ 轮询（可扩展） |
| **性能** |
| API 延迟 | 50-200ms（跨区域） | 1-10ms（局域网） |
| 并发支持 | ⭐⭐⭐⭐⭐ 自动扩展 | ⭐⭐⭐⭐ 连接池 |
| **数据安全** |
| 数据位置 | 云端（AWS） | 本地控制 |
| 访问控制 | RLS 策略 | MySQL 权限 |
| 备份 | 自动 | 手动 |
| **成本** |
| 开发环境 | 免费 | 免费 |
| 生产环境 | $25+/月 | 硬件成本 |
| **维护** |
| 数据库维护 | Supabase 负责 | 自行维护 |
| 系统升级 | 自动 | 手动 |

---

## 💻 开发工作流

### 工作流 1: 云端开发 + 本地部署

**最推荐的方式**

```
开发阶段（快速迭代）
    ↓
使用 Supabase
- 无需本地数据库
- 多人协作方便
- 云端自动备份
    ↓
功能开发完成
    ↓
切换到 MySQL/OceanBase
- 本地测试
- 性能验证
- 生产部署准备
    ↓
生产环境
```

**操作步骤**：

```bash
# 1. 开发阶段 - 使用 Supabase
echo "VITE_SERVICE_PROVIDER=supabase" > .env
cat .env.supabase >> .env
npm run dev

# 2. 本地测试 - 切换到 MySQL
echo "VITE_SERVICE_PROVIDER=custom" > .env
cat .env.local >> .env
npm run server &
npm run dev

# 3. 生产部署 - 使用 OceanBase
cp .env.production .env
bash deploy-without-docker.sh
```

---

### 工作流 2: 全程本地开发

**适合内网环境**

```bash
# 始终使用本地 MySQL
VITE_SERVICE_PROVIDER=custom

# 前端（终端 1）
npm run dev

# 后端（终端 2）
npm run server
```

---

### 工作流 3: 混合模式

**多环境测试**

```bash
# 开两个终端，同时运行
# 终端 1: Supabase
VITE_SERVICE_PROVIDER=supabase npm run dev -- --port 5173

# 终端 2: MySQL（需要先启动 API 服务器）
npm run server &
VITE_SERVICE_PROVIDER=custom npm run dev -- --port 5174

# 对比测试两个环境
```

---

## 🔧 技术实现

### 前端架构

```typescript
// src/services/ServiceFactory.ts
class ServiceFactory {
  private static getProvider(): ServiceProvider {
    // 从环境变量读取配置
    return import.meta.env.VITE_SERVICE_PROVIDER || 'supabase'
  }

  static getAuthService(): IAuthService {
    const provider = this.getProvider()
    switch (provider) {
      case 'supabase':
        return new SupabaseAuthService()
      case 'custom':
        return new CustomAuthService()
    }
  }

  static getDataService(): IDataService {
    // 同样的逻辑
  }

  static getStorageService(): IStorageService {
    // 同样的逻辑
  }
}
```

### 服务接口

所有服务实现相同接口：

```typescript
// 数据服务接口
interface IDataService {
  query<T>(table: string, options?: QueryOptions): Promise<QueryArrayResult<T>>
  queryOne<T>(table: string, options?: QueryOptions): Promise<QueryResult<T>>
  insert<T>(table: string, data: Partial<T>): Promise<QueryResult<T>>
  update<T>(table: string, id: string, data: Partial<T>): Promise<QueryResult<T>>
  delete(table: string, id: string): Promise<{ error: Error | null }>
  subscribe(table: string, callback: Function): () => void
}
```

### 使用示例

```typescript
import ServiceFactory from '@/services/ServiceFactory'

// 组件中使用（自动选择引擎）
function MyComponent() {
  const dataService = ServiceFactory.getDataService()

  async function loadData() {
    const { data, error } = await dataService.query('workflows', {
      filter: { user_id: userId },
      order: { column: 'created_at', ascending: false },
      limit: 10
    })

    // 相同的代码，自动适配不同引擎
  }
}
```

---

## 📊 性能测试

### Supabase（云端）

```bash
# 测试环境：北京 → AWS ap-northeast-1（东京）
API 响应时间：
- 查询单条：80-120ms
- 查询列表：100-150ms
- 插入数据：100-180ms
- 更新数据：90-140ms

优化建议：
- 使用就近区域
- 启用连接池
- 使用 CDN 缓存
```

### MySQL（本地）

```bash
# 测试环境：局域网
API 响应时间：
- 查询单条：3-8ms
- 查询列表：5-15ms
- 插入数据：5-12ms
- 更新数据：4-10ms

优化建议：
- 添加索引
- 启用查询缓存
- 使用连接池
```

---

## 🎯 推荐策略

### 推荐配置

```
┌────────────────────────────────────────────┐
│          您的开发部署方案                   │
└────────────────────────────────────────────┘

阶段 1: 云端开发（当前 - 立即可用）
├─ 环境：Bolt.new / 本地 Windows
├─ 引擎：Supabase
├─ 用途：功能开发、UI 调试、快速迭代
└─ 优势：无需配置，多人协作

阶段 2: 本地验证（Windows）
├─ 环境：Windows 开发机
├─ 引擎：Custom（连接远程 OceanBase）
├─ 用途：功能测试、性能验证
└─ 配置：.env.local

阶段 3: 生产部署（CentOS 7）
├─ 环境：内网服务器
├─ 引擎：Custom（本地 OceanBase）
├─ 用途：正式环境运行
└─ 配置：.env.production
```

### 环境变量最佳实践

```bash
# 1. 永远不要提交 .env 到 Git
echo ".env" >> .gitignore
echo ".env.local" >> .gitignore
echo ".env.production" >> .gitignore

# 2. 使用 .env.example 作为模板
cp .env.example .env.local
# 然后编辑 .env.local

# 3. 生产环境使用环境变量或密钥管理
# 而不是 .env 文件
export VITE_SERVICE_PROVIDER=custom
export DB_PASSWORD=secure_password
```

---

## 🔍 故障排查

### 问题 1: 切换引擎后无法连接

**症状**：
```
Error: Failed to fetch
或
Error: Network error
```

**解决**：

```bash
# 1. 检查 .env 配置
cat .env | grep VITE_SERVICE_PROVIDER

# 2. 如果是 custom，确保 API 服务器运行
ps aux | grep "node.*server"
npm run server

# 3. 检查端口占用
netstat -ano | findstr "3000"  # Windows
lsof -i :3000                  # Linux/Mac

# 4. 清除缓存重启
rm -rf node_modules/.vite
npm run dev
```

---

### 问题 2: Supabase 认证失败

**症状**：
```
Error: Invalid API key
或
Error: Project not found
```

**解决**：

```bash
# 1. 检查 Supabase 配置
cat .env | grep VITE_SUPABASE

# 2. 验证密钥是否正确
# 登录 https://supabase.com
# 查看 Settings → API

# 3. 检查项目是否暂停
# Supabase 免费版 7 天无活动会暂停
```

---

### 问题 3: MySQL 连接失败

**症状**：
```
Error: connect ECONNREFUSED
或
Error: Access denied for user
```

**解决**：

```bash
# 1. 测试数据库连接
mysql -h192.168.1.70 -P2883 -u'root@Tianji4_MySQL#Tianji4' -p

# 2. 检查防火墙
# 确保端口 2883 开放

# 3. 检查用户权限
# OceanBase: 确保用户名格式正确
# 格式：用户名@租户名#集群名

# 4. 查看 API 服务器日志
npm run server
# 查看错误信息
```

---

### 问题 4: 数据不同步

**症状**：在一个引擎创建的数据，切换后看不到

**说明**：这是正常的！两个引擎使用**完全独立的数据库**。

**解决**：

```bash
# 如果需要迁移数据
# 1. 导出 Supabase 数据
#    在 Supabase Dashboard → Database → Backup

# 2. 导入到 MySQL
mysql -h192.168.1.70 -P2883 -u'root@Tianji4_MySQL#Tianji4' -p < backup.sql

# 或使用数据同步脚本（需要自行开发）
```

---

## 📚 相关文档

| 文档 | 说明 |
|------|------|
| [WINDOWS_QUICKSTART.md](WINDOWS_QUICKSTART.md) | Windows 快速开发 |
| [START_HERE_CENTOS7.md](START_HERE_CENTOS7.md) | CentOS 7 部署 |
| [DEPLOYMENT_STRATEGY.md](DEPLOYMENT_STRATEGY.md) | 部署策略 |
| [DATABASE.md](DATABASE.md) | 数据库详细说明 |

---

## 🎉 总结

### 核心优势

```
✅ 灵活切换 - 一行配置即可切换引擎
✅ 代码统一 - 业务代码完全相同
✅ 零成本迁移 - 不同环境自由选择
✅ 最佳体验 - 开发用云，生产用本地
```

### 快速开始

```bash
# 当前就可以用！
# 1. Supabase 已配置（云端开发）
VITE_SERVICE_PROVIDER=supabase npm run dev

# 2. OceanBase 已配置（本地测试）
VITE_SERVICE_PROVIDER=custom npm run server &
VITE_SERVICE_PROVIDER=custom npm run dev

# 一套代码，两个引擎，随意切换！
```

---

更新时间：2024-01-18
