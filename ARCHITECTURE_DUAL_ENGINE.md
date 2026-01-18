# 双引擎架构详解

## 总体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         用户界面层                               │
│              React Components + React Router                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                      服务抽象层                                  │
│                                                                  │
│   ┌──────────────────────────────────────────────────────┐     │
│   │            ServiceFactory（服务工厂）                 │     │
│   │   根据 VITE_SERVICE_PROVIDER 环境变量选择实现         │     │
│   └────────┬─────────────────────────┬────────────────────┘     │
│            │                         │                          │
│   ┌────────▼────────┐       ┌───────▼─────────┐               │
│   │  IAuthService   │       │  IDataService   │               │
│   │  （认证接口）    │       │  （数据接口）    │               │
│   └─────────────────┘       └─────────────────┘               │
│            │                         │                          │
│   ┌────────▼────────┐                │                          │
│   │ IStorageService │                │                          │
│   │  （存储接口）    │                │                          │
│   └─────────────────┘                │                          │
└───────────────────────────────────────┼──────────────────────────┘
                                        │
                 ┌──────────────────────┴──────────────────────┐
                 │                                             │
        ┌────────▼──────────┐                    ┌────────────▼──────────┐
        │   Supabase 引擎    │                    │    Custom 引擎        │
        └────────┬───────────┘                    └────────────┬──────────┘
                 │                                             │
        ┌────────▼───────────┐              ┌─────────────────▼──────────┐
        │ Supabase Cloud     │              │  Express API Server         │
        │  - PostgreSQL      │              │  - RESTful API              │
        │  - Auth            │              │  - JWT Auth                 │
        │  - Storage         │              │  - File Upload              │
        │  - Realtime        │              └─────────────────┬──────────┘
        └────────────────────┘                                │
                                                   ┌───────────▼──────────┐
                                                   │ MySQL/OceanBase     │
                                                   │  - Local Database   │
                                                   │  - Full Control     │
                                                   └─────────────────────┘
```

---

## 服务接口层

### IAuthService（认证服务接口）

```typescript
interface IAuthService {
  // 用户注册
  signUp(email: string, password: string): Promise<AuthResult>

  // 用户登录
  signIn(email: string, password: string): Promise<AuthResult>

  // 用户登出
  signOut(): Promise<void>

  // 获取当前会话
  getSession(): Promise<Session | null>

  // 监听认证状态变化
  onAuthStateChange(callback: (session: Session | null) => void): () => void
}
```

### IDataService（数据服务接口）

```typescript
interface IDataService {
  // 查询多条记录
  query<T>(
    table: string,
    options?: QueryOptions
  ): Promise<QueryArrayResult<T>>

  // 查询单条记录
  queryOne<T>(
    table: string,
    options?: QueryOptions
  ): Promise<QueryResult<T>>

  // 插入记录
  insert<T>(
    table: string,
    data: Partial<T> | Partial<T>[]
  ): Promise<QueryResult<T>>

  // 更新记录
  update<T>(
    table: string,
    id: string,
    data: Partial<T>
  ): Promise<QueryResult<T>>

  // 删除记录
  delete(
    table: string,
    id: string
  ): Promise<{ error: Error | null }>

  // 实时订阅
  subscribe(
    table: string,
    callback: (event: string, payload: any) => void
  ): () => void
}
```

### IStorageService（存储服务接口）

```typescript
interface IStorageService {
  // 上传文件
  upload(
    bucket: string,
    path: string,
    file: File
  ): Promise<UploadResult>

  // 获取文件 URL
  getPublicUrl(
    bucket: string,
    path: string
  ): string

  // 下载文件
  download(
    bucket: string,
    path: string
  ): Promise<Blob>

  // 删除文件
  remove(
    bucket: string,
    path: string
  ): Promise<{ error: Error | null }>
}
```

---

## 实现层对比

### Supabase 引擎实现

```typescript
// SupabaseAuthService
class SupabaseAuthService implements IAuthService {
  async signIn(email: string, password: string) {
    // 直接调用 Supabase SDK
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    return { data, error }
  }
  // ...其他方法
}

// SupabaseDataService
class SupabaseDataService implements IDataService {
  async query<T>(table: string, options?: QueryOptions) {
    // 使用 Supabase Query Builder
    let query = supabase.from(table).select(options?.select || '*')

    if (options?.filter) {
      Object.entries(options.filter).forEach(([key, value]) => {
        query = query.eq(key, value)
      })
    }

    const { data, error } = await query
    return { data, error }
  }
  // ...其他方法
}
```

**特点**：
- 直接使用 Supabase JavaScript SDK
- 无需后端服务器
- 支持实时订阅（WebSocket）
- 自动处理认证和 RLS

---

### Custom 引擎实现

```typescript
// CustomAuthService
class CustomAuthService implements IAuthService {
  async signIn(email: string, password: string) {
    // 调用自定义 API
    const response = await fetch(`${apiUrl}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    })

    const result = await response.json()

    if (!response.ok) {
      return { data: null, error: new Error(result.message) }
    }

    // 存储 session 到 localStorage
    localStorage.setItem('auth_session', JSON.stringify(result.session))
    return { data: result.session, error: null }
  }
  // ...其他方法
}

// CustomDataService
class CustomDataService implements IDataService {
  async query<T>(table: string, options?: QueryOptions) {
    // 构建查询字符串
    const queryString = this.buildQueryString(options)

    // 调用自定义 API
    const response = await fetch(
      `${apiUrl}/api/data/${table}${queryString}`,
      {
        headers: this.getAuthHeaders(),
      }
    )

    const result = await response.json()
    return { data: result.data, error: null }
  }
  // ...其他方法
}
```

**特点**：
- 调用自定义 Express API
- 需要运行后端服务器
- 使用 JWT 认证
- 轮询实现更新（可扩展 WebSocket）

---

## 后端架构（Custom 引擎）

```
┌─────────────────────────────────────────────────────────┐
│              Express API Server (api-server.ts)         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │          认证中间件 (JWT)                       │    │
│  │  authenticateToken(req, res, next)             │    │
│  └────────────────┬───────────────────────────────┘    │
│                   │                                      │
│  ┌────────────────▼───────────────┐                     │
│  │      认证路由                   │                     │
│  │  POST /api/auth/register        │                     │
│  │  POST /api/auth/login           │                     │
│  │  POST /api/auth/logout          │                     │
│  │  GET  /api/auth/session         │                     │
│  └─────────────────────────────────┘                     │
│                                                          │
│  ┌─────────────────────────────────┐                     │
│  │      数据路由（需认证）          │                     │
│  │  GET    /api/data/:table         │                     │
│  │  POST   /api/data/:table         │                     │
│  │  PUT    /api/data/:table/:id     │                     │
│  │  DELETE /api/data/:table/:id     │                     │
│  └────────────────┬────────────────┘                     │
│                   │                                      │
│  ┌────────────────▼───────────────┐                     │
│  │      文件上传路由                │                     │
│  │  POST /api/storage/upload        │                     │
│  │  GET  /api/storage/:bucket/:path │                     │
│  └─────────────────────────────────┘                     │
│                                                          │
└────────────────────┬────────────────────────────────────┘
                     │
          ┌──────────▼──────────┐
          │  MySQL Connection   │
          │  Pool (mysql2)      │
          └──────────┬──────────┘
                     │
          ┌──────────▼──────────┐
          │  MySQL/OceanBase    │
          │  Database           │
          └─────────────────────┘
```

### API 端点详解

#### 认证 API

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}

Response:
{
  "session": {
    "access_token": "jwt_token",
    "user": { "id": "uuid", "email": "user@example.com" }
  }
}
```

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}

Response:
{
  "session": {
    "access_token": "jwt_token",
    "user": { "id": "uuid", "email": "user@example.com" }
  }
}
```

#### 数据 API

```http
GET /api/data/workflows?filter_user_id=xxx&order=created_at:desc&limit=10
Authorization: Bearer jwt_token

Response:
{
  "data": [
    { "id": "1", "name": "Workflow 1", ... },
    { "id": "2", "name": "Workflow 2", ... }
  ]
}
```

```http
POST /api/data/workflows
Authorization: Bearer jwt_token
Content-Type: application/json

{
  "data": {
    "name": "New Workflow",
    "user_id": "xxx"
  }
}

Response:
{
  "data": { "id": "3", "name": "New Workflow", ... }
}
```

---

## 数据流图

### Supabase 引擎数据流

```
React Component
      ↓
  调用 dataService.query()
      ↓
  ServiceFactory.getDataService()
      ↓
  SupabaseDataService.query()
      ↓
  supabase.from(table).select()
      ↓ HTTPS
  Supabase API (自动认证)
      ↓
  PostgreSQL Database
      ↓
  返回数据
      ↓
  React Component 更新
```

### Custom 引擎数据流

```
React Component
      ↓
  调用 dataService.query()
      ↓
  ServiceFactory.getDataService()
      ↓
  CustomDataService.query()
      ↓
  fetch(`${apiUrl}/api/data/...`)
      ↓ HTTP
  Express API Server
      ↓
  验证 JWT Token
      ↓
  pool.query('SELECT * FROM ...')
      ↓
  MySQL/OceanBase Database
      ↓
  返回数据
      ↓
  Express Response
      ↓
  React Component 更新
```

---

## 配置切换机制

### 环境变量

```env
# .env
VITE_SERVICE_PROVIDER=supabase  # 或 custom

# Supabase 配置
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJxxx...

# Custom 配置
VITE_API_URL=http://localhost:3000
DB_HOST=192.168.1.70
DB_PORT=2883
DB_USER=root@xxx#xxx
DB_PASSWORD=xxx
```

### 运行时选择

```typescript
// ServiceFactory.ts
private static getProvider(): ServiceProvider {
  // 读取环境变量
  const provider = import.meta.env.VITE_SERVICE_PROVIDER

  // 默认使用 supabase
  return provider || 'supabase'
}

static getDataService(): IDataService {
  const provider = this.getProvider()

  // 根据配置返回不同实现
  switch (provider) {
    case 'supabase':
      return new SupabaseDataService()
    case 'custom':
      return new CustomDataService()
    default:
      throw new Error(`Unknown provider: ${provider}`)
  }
}
```

---

## 数据库模式

### Supabase (PostgreSQL)

```sql
-- 自动创建（通过 migrations）
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE workflows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  user_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS 策略
ALTER TABLE workflows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own workflows"
  ON workflows FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
```

### MySQL/OceanBase

```sql
-- 手动创建或通过脚本
CREATE TABLE users (
  id VARCHAR(36) PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE workflows (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  user_id VARCHAR(36),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 权限通过 API 层控制
-- 不使用数据库级 RLS
```

---

## 扩展性

### 添加新引擎

1. **定义接口实现**

```typescript
// src/services/data/MongoDBDataService.ts
export class MongoDBDataService implements IDataService {
  async query<T>(table: string, options?: QueryOptions) {
    // MongoDB 实现
  }
  // ...
}
```

2. **更新工厂**

```typescript
// src/services/ServiceFactory.ts
type ServiceProvider = 'supabase' | 'custom' | 'mongodb'

static getDataService(): IDataService {
  const provider = this.getProvider()

  switch (provider) {
    case 'supabase':
      return new SupabaseDataService()
    case 'custom':
      return new CustomDataService()
    case 'mongodb':
      return new MongoDBDataService()
  }
}
```

3. **添加配置**

```env
VITE_SERVICE_PROVIDER=mongodb
MONGODB_URI=mongodb://localhost:27017/ops
```

---

## 性能优化

### Supabase 优化

```typescript
// 1. 使用连接池
const supabase = createClient(url, key, {
  db: {
    schema: 'public',
  },
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
})

// 2. 选择性字段
await supabase
  .from('workflows')
  .select('id, name, created_at')  // 只选择需要的字段

// 3. 使用索引
// 在 Supabase Dashboard 创建索引
CREATE INDEX idx_workflows_user_id ON workflows(user_id);
```

### Custom 优化

```typescript
// 1. 数据库连接池
const pool = mysql.createPool({
  connectionLimit: 10,  // 连接池大小
  queueLimit: 0,
  waitForConnections: true,
})

// 2. 查询优化
const [rows] = await pool.query(
  'SELECT id, name, created_at FROM workflows WHERE user_id = ? LIMIT ?',
  [userId, limit]
)

// 3. 缓存
const cache = new Map()
if (cache.has(cacheKey)) {
  return cache.get(cacheKey)
}
```

---

## 安全性

### Supabase

- **RLS**: Row Level Security 自动过滤数据
- **JWT**: 自动验证和刷新 Token
- **API Key**: Anon key 限制客户端权限

### Custom

- **JWT**: 手动验证 Token
- **API 层**: 验证用户权限
- **SQL Injection**: 使用参数化查询

```typescript
// ✅ 正确：参数化查询
await pool.query(
  'SELECT * FROM workflows WHERE user_id = ?',
  [userId]
)

// ❌ 错误：字符串拼接（SQL 注入风险）
await pool.query(
  `SELECT * FROM workflows WHERE user_id = '${userId}'`
)
```

---

## 总结

### 关键设计原则

1. **接口抽象**: 统一的服务接口，隐藏实现细节
2. **工厂模式**: 根据配置动态选择实现
3. **环境变量**: 通过配置文件切换引擎
4. **零代码修改**: 业务代码完全不感知引擎变化

### 优势

- ✅ **灵活性**: 一行配置切换引擎
- ✅ **可测试性**: 可以模拟不同引擎进行测试
- ✅ **可扩展性**: 易于添加新的数据库引擎
- ✅ **可维护性**: 清晰的架构，易于理解和维护

---

更新时间：2024-01-18
