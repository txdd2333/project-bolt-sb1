# 数据库文档

> 本文档详细说明数据库架构、表结构、RLS 策略和常用查询

---

## 📊 数据库架构

### ERD（实体关系图）

```
┌─────────────────┐
│   auth.users    │
│  (Supabase)     │
└────────┬────────┘
         │
         │ (1:N)
         │
    ┌────┴─────┬─────────┬──────────┬─────────────┐
    │          │         │          │             │
    ▼          ▼         ▼          ▼             ▼
┌─────────┐ ┌──────────┐ ┌────────┐ ┌──────────────┐ ┌─────────┐
│scenarios│ │workflows │ │modules │ │execution_logs│ │  (其他)  │
└─────────┘ └──────────┘ └────────┘ └──────────────┘ └─────────┘
     │            ▲                         │
     │            │                         │
     └────────────┴─────────────────────────┘
       (M:N via workflow_ids)        (N:1)
```

---

## 📋 表结构详解

### 1. scenarios（场景表）

**用途**: 存储运维场景信息，包含 SOP 文档和流程图定义

| 字段名 | 类型 | 约束 | 默认值 | 说明 |
|--------|------|------|--------|------|
| `id` | uuid | PRIMARY KEY | gen_random_uuid() | 场景唯一标识 |
| `name` | text | NOT NULL | - | 场景名称 |
| `description` | text | | - | 场景描述 |
| `category` | text | | - | 场景分类（如：服务器、网络、应用） |
| `sop_content` | text | | - | SOP 文档内容（Markdown 格式） |
| `flowchart_definition` | text | | - | 流程图定义（X6 JSON 格式） |
| `workflow_ids` | jsonb | | `'[]'::jsonb` | 关联的工作流 ID 数组 |
| `user_id` | uuid | NOT NULL, FK | auth.uid() | 创建者 ID |
| `created_at` | timestamptz | NOT NULL | now() | 创建时间 |
| `updated_at` | timestamptz | NOT NULL | now() | 更新时间 |

**索引**:
```sql
CREATE INDEX idx_scenarios_user_id ON scenarios(user_id);
CREATE INDEX idx_scenarios_category ON scenarios(category);
```

**RLS 策略**:
```sql
-- SELECT: 用户只能查看自己的场景
CREATE POLICY "Users can view own scenarios"
  ON scenarios FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- INSERT: 用户只能创建属于自己的场景
CREATE POLICY "Users can create own scenarios"
  ON scenarios FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: 用户只能更新自己的场景
CREATE POLICY "Users can update own scenarios"
  ON scenarios FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- DELETE: 用户只能删除自己的场景
CREATE POLICY "Users can delete own scenarios"
  ON scenarios FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
```

**常用查询**:
```sql
-- 查询用户的所有场景（按分类分组）
SELECT category, COUNT(*) as count
FROM scenarios
WHERE user_id = auth.uid()
GROUP BY category
ORDER BY count DESC;

-- 查询包含特定工作流的场景
SELECT s.*
FROM scenarios s
WHERE user_id = auth.uid()
  AND workflow_ids @> '["<workflow-id>"]'::jsonb;

-- 查询最近更新的场景
SELECT *
FROM scenarios
WHERE user_id = auth.uid()
ORDER BY updated_at DESC
LIMIT 10;

-- 搜索场景（名称或描述）
SELECT *
FROM scenarios
WHERE user_id = auth.uid()
  AND (
    name ILIKE '%关键词%'
    OR description ILIKE '%关键词%'
  );
```

---

### 2. workflows（工作流表）

**用途**: 存储可执行的工作流定义

| 字段名 | 类型 | 约束 | 默认值 | 说明 |
|--------|------|------|--------|------|
| `id` | uuid | PRIMARY KEY | gen_random_uuid() | 工作流唯一标识 |
| `name` | text | NOT NULL | - | 工作流名称 |
| `description` | text | | - | 工作流描述 |
| `trigger_type` | text | NOT NULL | 'manual' | 触发方式（manual/schedule/event） |
| `definition` | text | | - | 工作流定义（X6 JSON 格式） |
| `user_id` | uuid | NOT NULL, FK | auth.uid() | 创建者 ID |
| `created_at` | timestamptz | NOT NULL | now() | 创建时间 |
| `updated_at` | timestamptz | NOT NULL | now() | 更新时间 |

**触发类型说明**:
- `manual`: 手动触发（默认）
- `schedule`: 定时触发（需要配合 cron 表达式）
- `event`: 事件触发（如：文件变化、API 调用）

**索引**:
```sql
CREATE INDEX idx_workflows_user_id ON workflows(user_id);
CREATE INDEX idx_workflows_trigger_type ON workflows(trigger_type);
```

**RLS 策略**:（与 scenarios 类似）
```sql
-- 所有策略与 scenarios 表结构相同
-- 用户只能操作自己的工作流
```

**常用查询**:
```sql
-- 查询所有可用工作流（用于场景关联）
SELECT id, name, description, trigger_type
FROM workflows
WHERE user_id = auth.uid()
ORDER BY name;

-- 查询定时触发的工作流
SELECT *
FROM workflows
WHERE user_id = auth.uid()
  AND trigger_type = 'schedule';

-- 查询未被任何场景使用的工作流
SELECT w.*
FROM workflows w
WHERE w.user_id = auth.uid()
  AND NOT EXISTS (
    SELECT 1
    FROM scenarios s
    WHERE s.user_id = auth.uid()
      AND s.workflow_ids @> jsonb_build_array(w.id)
  );
```

---

### 3. modules（模块表）

**用途**: 存储可复用的工作流模块（如：常用脚本、API 调用配置）

| 字段名 | 类型 | 约束 | 默认值 | 说明 |
|--------|------|------|--------|------|
| `id` | uuid | PRIMARY KEY | gen_random_uuid() | 模块唯一标识 |
| `name` | text | NOT NULL | - | 模块名称 |
| `type` | text | NOT NULL | - | 模块类型（script/api/notification 等） |
| `config` | jsonb | NOT NULL | '{}' | 模块配置（JSON 格式） |
| `user_id` | uuid | NOT NULL, FK | auth.uid() | 创建者 ID |
| `created_at` | timestamptz | NOT NULL | now() | 创建时间 |

**模块类型示例**:
```jsonb
-- script 类型
{
  "type": "script",
  "language": "bash",
  "code": "#!/bin/bash\necho 'Hello World'"
}

-- api 类型
{
  "type": "api",
  "method": "POST",
  "url": "https://api.example.com/webhook",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "message": "Alert!"
  }
}

-- notification 类型
{
  "type": "notification",
  "channel": "email",
  "recipients": ["admin@example.com"],
  "template": "alert_template"
}
```

**索引**:
```sql
CREATE INDEX idx_modules_user_id ON modules(user_id);
CREATE INDEX idx_modules_type ON modules(type);
```

**常用查询**:
```sql
-- 按类型查询模块
SELECT *
FROM modules
WHERE user_id = auth.uid()
  AND type = 'script'
ORDER BY name;

-- 查询包含特定关键词的模块
SELECT *
FROM modules
WHERE user_id = auth.uid()
  AND (
    name ILIKE '%关键词%'
    OR config::text ILIKE '%关键词%'
  );
```

---

### 4. execution_logs（执行日志表）

**用途**: 记录工作流的执行历史和结果

| 字段名 | 类型 | 约束 | 默认值 | 说明 |
|--------|------|------|--------|------|
| `id` | uuid | PRIMARY KEY | gen_random_uuid() | 日志唯一标识 |
| `workflow_id` | uuid | NOT NULL, FK | - | 关联的工作流 ID |
| `status` | text | NOT NULL | 'running' | 执行状态（running/success/failed） |
| `start_time` | timestamptz | NOT NULL | now() | 开始时间 |
| `end_time` | timestamptz | | - | 结束时间 |
| `logs` | text | | - | 执行日志详情 |
| `error_message` | text | | - | 错误信息（如果失败） |
| `user_id` | uuid | NOT NULL, FK | auth.uid() | 执行者 ID |
| `created_at` | timestamptz | NOT NULL | now() | 创建时间 |

**状态说明**:
- `running`: 执行中
- `success`: 执行成功
- `failed`: 执行失败
- `cancelled`: 已取消（可选）

**索引**:
```sql
CREATE INDEX idx_execution_logs_user_id ON execution_logs(user_id);
CREATE INDEX idx_execution_logs_workflow_id ON execution_logs(workflow_id);
CREATE INDEX idx_execution_logs_status ON execution_logs(status);
CREATE INDEX idx_execution_logs_start_time ON execution_logs(start_time DESC);
```

**常用查询**:
```sql
-- 查询最近的执行记录
SELECT el.*, w.name as workflow_name
FROM execution_logs el
JOIN workflows w ON w.id = el.workflow_id
WHERE el.user_id = auth.uid()
ORDER BY el.start_time DESC
LIMIT 50;

-- 查询特定工作流的执行历史
SELECT *
FROM execution_logs
WHERE user_id = auth.uid()
  AND workflow_id = '<workflow-id>'
ORDER BY start_time DESC;

-- 查询失败的执行记录
SELECT el.*, w.name as workflow_name
FROM execution_logs el
JOIN workflows w ON w.id = el.workflow_id
WHERE el.user_id = auth.uid()
  AND el.status = 'failed'
ORDER BY el.start_time DESC;

-- 统计工作流执行成功率
SELECT
  w.name,
  COUNT(*) as total_runs,
  SUM(CASE WHEN el.status = 'success' THEN 1 ELSE 0 END) as successful_runs,
  ROUND(
    SUM(CASE WHEN el.status = 'success' THEN 1 ELSE 0 END)::numeric / COUNT(*) * 100,
    2
  ) as success_rate
FROM execution_logs el
JOIN workflows w ON w.id = el.workflow_id
WHERE el.user_id = auth.uid()
GROUP BY w.id, w.name
ORDER BY success_rate DESC;

-- 查询执行时间最长的记录
SELECT
  el.*,
  w.name as workflow_name,
  EXTRACT(EPOCH FROM (el.end_time - el.start_time)) as duration_seconds
FROM execution_logs el
JOIN workflows w ON w.id = el.workflow_id
WHERE el.user_id = auth.uid()
  AND el.end_time IS NOT NULL
ORDER BY duration_seconds DESC
LIMIT 10;
```

---

## 🔐 认证和安全

### auth.users（Supabase 内置）

**字段**（部分）:
- `id`: uuid（用户唯一标识）
- `email`: text（邮箱）
- `encrypted_password`: text（加密密码）
- `created_at`: timestamptz
- `raw_user_meta_data`: jsonb（用户元数据）
- `raw_app_meta_data`: jsonb（应用元数据）

**获取当前用户 ID**:
```sql
SELECT auth.uid();  -- 返回当前登录用户的 ID
```

**获取当前用户信息**:
```sql
SELECT * FROM auth.users WHERE id = auth.uid();
```

---

## 🖼️ Storage（存储）

### sop-images（Bucket）

**用途**: 存储 SOP 文档中上传的图片

**策略**:
```sql
-- 允许认证用户上传图片
CREATE POLICY "Authenticated users can upload images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'sop-images');

-- 允许所有人查看图片（公开访问）
CREATE POLICY "Anyone can view images"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'sop-images');

-- 允许用户删除自己上传的图片
CREATE POLICY "Users can delete own images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'sop-images'
    AND auth.uid() = owner
  );
```

**上传图片**（前端代码）:
```typescript
const { data, error } = await supabase.storage
  .from('sop-images')
  .upload(`${Date.now()}-${file.name}`, file)

if (error) throw error

// 获取公开 URL
const { data: { publicUrl } } = supabase.storage
  .from('sop-images')
  .getPublicUrl(data.path)

console.log('Image URL:', publicUrl)
```

**删除图片**:
```typescript
const { error } = await supabase.storage
  .from('sop-images')
  .remove(['path/to/image.jpg'])
```

---

## 🔄 迁移历史

### 已应用的迁移

| 迁移文件 | 应用时间 | 说明 |
|----------|----------|------|
| `20260114061922_create_ops_workflow_tables.sql` | 2026-01-14 | 创建初始表结构 |
| `20260115135451_add_user_associations.sql` | 2026-01-15 | 添加用户关联字段 |
| `20260115140156_fix_scenarios_table_structure.sql` | 2026-01-15 | 修复场景表结构 |
| `20260115140652_add_sop_and_flowchart_to_scenarios.sql` | 2026-01-15 | 添加 SOP 和流程图字段 |
| `20260115151616_create_sop_images_storage_policies.sql` | 2026-01-15 | 创建图片存储策略 |
| `20260116032128_add_definition_to_workflows.sql` | 2026-01-16 | 添加工作流定义字段 |
| `20260116072525_add_definition_to_workflows_update.sql` | 2026-01-16 | 更新工作流定义字段 |

### 创建新迁移

**注意**: 本项目使用 Supabase MCP 工具自动应用迁移，无需手动执行 SQL。

**步骤**:
1. 在左侧工具栏选择 Supabase
2. 使用 `apply_migration` 工具
3. 提供文件名和 SQL 内容

**迁移最佳实践**:
- ✅ 使用 `IF NOT EXISTS` 避免重复创建
- ✅ 添加详细的注释说明
- ✅ 先创建表，再添加 RLS 策略
- ✅ 使用事务（自动）
- ❌ 不要使用 `DROP TABLE`（数据安全）
- ❌ 不要硬编码用户 ID

---

## 📊 性能优化建议

### 1. 添加适当的索引
```sql
-- 为常用查询字段添加索引
CREATE INDEX IF NOT EXISTS idx_scenarios_updated_at
  ON scenarios(updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_execution_logs_composite
  ON execution_logs(user_id, workflow_id, start_time DESC);
```

### 2. 使用物化视图（如需要）
```sql
-- 创建场景统计视图
CREATE MATERIALIZED VIEW scenario_stats AS
SELECT
  user_id,
  COUNT(*) as total_scenarios,
  COUNT(DISTINCT category) as total_categories,
  MAX(updated_at) as last_updated
FROM scenarios
GROUP BY user_id;

-- 刷新视图
REFRESH MATERIALIZED VIEW scenario_stats;
```

### 3. 分页查询
```typescript
// 前端代码
const PAGE_SIZE = 20

const { data, error, count } = await supabase
  .from('scenarios')
  .select('*', { count: 'exact' })
  .range(page * PAGE_SIZE, (page + 1) * PAGE_SIZE - 1)
  .order('created_at', { ascending: false })
```

---

## 🛠️ 常用维护命令

### 查看表大小
```sql
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### 查看活跃连接
```sql
SELECT
  pid,
  usename,
  application_name,
  client_addr,
  state,
  query
FROM pg_stat_activity
WHERE state = 'active';
```

### 清理测试数据
```sql
-- ⚠️ 谨慎使用：删除所有数据
DELETE FROM execution_logs WHERE user_id = '<test-user-id>';
DELETE FROM scenarios WHERE user_id = '<test-user-id>';
DELETE FROM workflows WHERE user_id = '<test-user-id>';
DELETE FROM modules WHERE user_id = '<test-user-id>';
```

---

## 📞 故障排查

### 问题：RLS 阻止查询
**症状**: 查询返回空结果，但数据确实存在

**检查**:
```sql
-- 检查 RLS 是否启用
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';

-- 查看表的 RLS 策略
SELECT *
FROM pg_policies
WHERE tablename = 'scenarios';
```

**解决**:
- 确认用户已登录（`auth.uid()` 不为空）
- 确认数据的 `user_id` 与当前用户匹配
- 临时禁用 RLS 测试（仅开发环境）

### 问题：外键约束错误
**症状**: 插入/更新时报错 "violates foreign key constraint"

**检查**:
```sql
-- 检查引用的记录是否存在
SELECT * FROM workflows WHERE id = '<workflow-id>';
```

**解决**:
- 确认引用的记录存在
- 确认 UUID 格式正确
- 先创建被引用的记录，再创建引用记录

---

**最后更新**: 2026-01-16
