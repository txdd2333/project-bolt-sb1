# 运维工作流中心 - 项目交接文档

## 📋 项目概述

### 项目背景
这是一个企业级的运维工作流管理平台，旨在帮助运维团队管理和执行标准化的操作流程。

### 核心功能
1. **场景管理** - 管理运维场景，包含 SOP 文档、流程图和关联工作流
2. **工作流编辑** - 可视化的工作流设计器（支持多种编辑器）
3. **模块/注册表** - 管理可复用的工作流组件
4. **执行日志** - 追踪工作流执行历史
5. **用户认证** - 基于 Supabase 的邮箱密码认证

---

## 🎯 当前交付状态

### ✅ 已完成功能

#### 1. 核心业务模块
- ✅ 场景列表页 (`/scenarios`) - 展示所有场景
- ✅ 场景详情页 (`/scenarios/:id`) - 查看和编辑场景
  - SOP 文档编辑（Markdown 富文本编辑器）
  - 流程图编辑（X6 图形编辑器，正在调试中）
  - 关联工作流选择
- ✅ 工作流列表页 (`/workflows`) - 管理工作流
- ✅ 工作流编辑页 (`/workflows/:id/edit`) - 编辑工作流定义
- ✅ 模块管理页 (`/modules`) - 管理可复用模块
- ✅ 执行日志页 (`/executions`) - 查看执行历史

#### 2. 编辑器组件
- ✅ Markdown 编辑器 (`MarkdownEditor.tsx`) - 支持撤销/重做，图片上传到 Supabase Storage
- ✅ X6 流程图编辑器 (`X6Editor/`) - AntV X6 可视化编辑器
- ✅ LogicFlow 编辑器 (`LogicFlowEditor/`) - 备用流程编辑器
- ✅ BPMN 编辑器 (`BpmnEditor/`) - 备用流程编辑器

#### 3. 数据库设计
- ✅ 用户认证表（Supabase Auth）
- ✅ `scenarios` 表 - 场景信息（包含 sop_content, flowchart_definition）
- ✅ `workflows` 表 - 工作流定义
- ✅ `modules` 表 - 可复用模块
- ✅ `execution_logs` 表 - 执行日志
- ✅ RLS 策略 - 所有表启用行级安全
- ✅ Storage bucket `sop-images` - 存储 SOP 中的图片

#### 4. 技术栈
- **前端**: React 18 + TypeScript + Vite
- **路由**: React Router v6
- **UI**: Tailwind CSS + Lucide Icons
- **图形编辑器**:
  - AntV X6 (主要使用)
  - LogicFlow (备用)
  - bpmn-js (备用)
- **富文本**: WangEditor + Markdown
- **状态管理**: Zustand (如需要)
- **数据库**: Supabase (PostgreSQL + Auth + Storage)

---

## ⚠️ 当前已知问题

### 🔴 紧急问题

#### 问题 1: X6 编辑器画布白屏
**现象**:
- 打开场景详情页 → 流程图标签页，显示"初始化画布中..."后白屏
- 控制台警告: `"X6Editor container has no size"`

**原因分析**:
- X6 画布容器在初始化时没有正确获取到父容器的尺寸
- 可能是 CSS 布局嵌套层级过深，或者异步渲染时序问题

**已尝试的修复**:
1. ✅ 添加了重试机制（最多尝试 10 次，每次间隔 200ms）
2. ✅ 为容器添加明确的 `width: 100%; height: 100%`
3. ✅ 设置 `min-height: 500px` 确保容器有高度
4. ✅ 添加详细的调试日志

**下一步调试方向**:
```javascript
// 在 ScenarioDetailPage.tsx 中，确保容器高度计算正确
// 当前代码位置: src/pages/ScenarioDetailPage.tsx:349-357

// 方案 A: 使用固定高度
<div style={{ height: 'calc(100vh - 200px)' }}>
  <X6Editor />
</div>

// 方案 B: 检查父容器的 flex 布局
// 确保从 Layout → ScenarioDetailPage → X6Editor 的完整高度链条

// 方案 C: 直接在 X6Editor 内部设置容器尺寸
const container = containerRef.current
container.style.width = '100%'
container.style.height = '600px' // 或使用 window.innerHeight
```

**相关文件**:
- `src/components/X6Editor/index.tsx` (第 59-207 行)
- `src/components/X6Editor/styles.css` (第 1-8 行)
- `src/pages/ScenarioDetailPage.tsx` (第 349-357 行)

---

### 🟡 次要问题

#### 问题 2: 工作流编辑器功能待完善
- 工作流编辑页面 (`/workflows/:id/edit`) 目前是占位页面
- 需要选择使用哪个编辑器（X6 / LogicFlow / BPMN）
- 建议：先解决 X6 编辑器的白屏问题，然后复用到工作流编辑页

#### 问题 3: 场景和工作流的关联逻辑
- 数据库层面支持多对多关系（通过 `workflow_ids` JSONB 数组）
- 前端 UI 中的"关联工作流"功能需要完善：
  - 工作流选择器（多选）
  - 显示已关联的工作流列表
  - 取消关联操作

---

## 🚀 环境设置

### 1. 克隆和安装依赖

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build
```

### 2. 环境变量配置

`.env` 文件已配置（敏感信息已隐藏）：

```env
VITE_SUPABASE_URL=<your-supabase-url>
VITE_SUPABASE_ANON_KEY=<your-supabase-anon-key>
```

**重要**: 确保 `.env` 文件存在且包含有效的 Supabase 凭证。

### 3. Supabase 配置

#### 项目信息
- 已创建 Supabase 项目
- 数据库、认证、存储均已配置

#### 数据库迁移
所有迁移文件位于 `supabase/migrations/`：

```bash
supabase/migrations/
├── 20260114061922_create_ops_workflow_tables.sql       # 初始表结构
├── 20260115135451_add_user_associations.sql            # 添加用户关联
├── 20260115140156_fix_scenarios_table_structure.sql    # 修复场景表
├── 20260115140652_add_sop_and_flowchart_to_scenarios.sql # 添加 SOP 和流程图字段
├── 20260115151616_create_sop_images_storage_policies.sql # 图片存储策略
├── 20260116032128_add_definition_to_workflows.sql      # 工作流定义字段
└── 20260116072525_add_definition_to_workflows_update.sql # 更新工作流定义
```

**所有迁移已自动应用**，无需手动执行。

#### Storage Bucket
- Bucket 名称: `sop-images`
- 用途: 存储 SOP 文档中上传的图片
- 权限: 已配置 RLS 策略，认证用户可读写

---

## 📊 数据库架构

### 核心表结构

#### 1. scenarios (场景表)
```sql
scenarios {
  id: uuid (PK)
  name: text
  description: text
  category: text
  sop_content: text               -- Markdown 格式的 SOP 文档
  flowchart_definition: text      -- X6 图形定义 JSON 字符串
  workflow_ids: jsonb             -- 关联的工作流 ID 数组
  user_id: uuid (FK → auth.users)
  created_at: timestamptz
  updated_at: timestamptz
}
```

#### 2. workflows (工作流表)
```sql
workflows {
  id: uuid (PK)
  name: text
  description: text
  trigger_type: text              -- manual, schedule, event
  definition: text                -- 工作流定义 JSON 字符串
  user_id: uuid (FK → auth.users)
  created_at: timestamptz
  updated_at: timestamptz
}
```

#### 3. modules (模块表)
```sql
modules {
  id: uuid (PK)
  name: text
  type: text
  config: jsonb
  user_id: uuid (FK → auth.users)
  created_at: timestamptz
}
```

#### 4. execution_logs (执行日志表)
```sql
execution_logs {
  id: uuid (PK)
  workflow_id: uuid (FK → workflows)
  status: text                    -- running, success, failed
  start_time: timestamptz
  end_time: timestamptz
  logs: text
  user_id: uuid (FK → auth.users)
  created_at: timestamptz
}
```

### RLS 策略
所有表都启用了行级安全（RLS），规则如下：
- **SELECT**: 用户只能查看自己创建的数据
- **INSERT**: 用户只能插入数据，且 `user_id` 必须是自己
- **UPDATE**: 用户只能更新自己创建的数据
- **DELETE**: 用户只能删除自己创建的数据

---

## 🔐 认证流程

### 登录/注册
- 使用 Supabase Auth 的邮箱密码认证
- 无需邮箱验证（已禁用）
- 认证状态通过 `AuthContext` 管理
- 受保护路由使用 `ProtectedRoute` 组件

### 文件位置
- 认证上下文: `src/contexts/AuthContext.tsx`
- 登录页: `src/pages/LoginPage.tsx`
- 注册页: `src/pages/RegisterPage.tsx`
- 路由保护: `src/components/ProtectedRoute.tsx`

---

## 📁 项目结构

```
src/
├── components/
│   ├── BpmnEditor/           # BPMN 流程编辑器（备用）
│   ├── LogicFlowEditor/      # LogicFlow 编辑器（备用）
│   │   └── nodes/            # 自定义节点类型
│   ├── X6Editor/             # X6 图形编辑器（主要使用）
│   │   ├── index.tsx         # 主组件
│   │   ├── Canvas.tsx        # 画布组件
│   │   ├── Toolbar.tsx       # 工具栏
│   │   ├── Inspector.tsx     # 属性面板
│   │   ├── StatusBar.tsx     # 状态栏
│   │   └── styles.css
│   ├── Layout.tsx            # 整体布局（侧边栏 + 导航）
│   ├── MarkdownEditor.tsx    # Markdown 编辑器
│   └── ProtectedRoute.tsx    # 路由保护
├── contexts/
│   └── AuthContext.tsx       # 认证上下文
├── hooks/
│   └── useUndoRedo.ts        # 撤销重做 Hook
├── lib/
│   ├── supabase.ts           # Supabase 客户端
│   ├── database.types.ts     # 数据库类型定义
│   └── documentUtils.ts      # 文档处理工具
├── pages/
│   ├── ExecutionLogsPage.tsx      # 执行日志
│   ├── LoginPage.tsx              # 登录
│   ├── RegisterPage.tsx           # 注册
│   ├── ModulesPage.tsx            # 模块管理
│   ├── ScenarioDetailPage.tsx     # 场景详情 ⚠️ 主要问题所在
│   ├── ScenariosPage.tsx          # 场景列表
│   ├── WorkflowEditorPage.tsx     # 工作流编辑（占位）
│   └── WorkflowsPage.tsx          # 工作流列表
├── x6-registry/              # X6 节点注册表（备用）
│   ├── registry.ts
│   ├── types.ts
│   └── utils.ts
├── App.tsx                   # 路由配置
├── main.tsx                  # 入口文件
└── index.css                 # 全局样式

supabase/
└── migrations/               # 数据库迁移文件
```

---

## 🎨 UI 设计规范

### 配色方案
- 主色调: 蓝色系 (`blue-500`, `blue-600`)
- 辅助色: 灰色系 (`gray-100` 到 `gray-900`)
- 成功: 绿色 (`green-500`)
- 警告: 黄色 (`yellow-500`)
- 错误: 红色 (`red-500`)

### 布局规范
- 侧边栏宽度: 256px
- 主内容区: 左右 padding 24px
- 卡片间距: 16px
- 按钮高度: 36px (medium)

---

## 🔄 推进节奏建议

### 第一阶段：紧急修复（1-2 天）
**目标**: 解决 X6 编辑器白屏问题

**任务清单**:
1. ✅ 检查 `ScenarioDetailPage` 的布局层级
   - 确保从根节点到 X6 容器的完整高度传递
   - 使用浏览器开发工具检查每一层的 computed height

2. ✅ 尝试固定高度方案
   ```typescript
   // 在 ScenarioDetailPage.tsx 第 350 行
   <div style={{ height: 'calc(100vh - 200px)' }}>
     <X6Editor ... />
   </div>
   ```

3. ✅ 如果固定高度可行，重构为响应式计算
   ```typescript
   const [containerHeight, setContainerHeight] = useState(600)

   useEffect(() => {
     const updateHeight = () => {
       // 计算可用高度
       const headerHeight = 64  // 顶部导航
       const tabsHeight = 48    // 标签栏
       const padding = 32       // 内边距
       const availableHeight = window.innerHeight - headerHeight - tabsHeight - padding
       setContainerHeight(availableHeight)
     }

     updateHeight()
     window.addEventListener('resize', updateHeight)
     return () => window.removeEventListener('resize', updateHeight)
   }, [])
   ```

4. ✅ 验证编辑器基本功能
   - 添加节点
   - 连接节点
   - 删除节点
   - 保存/加载数据

### 第二阶段：功能完善（3-5 天）
**目标**: 完善场景和工作流的核心功能

**任务清单**:
1. **场景工作流关联**
   - 实现工作流多选组件
   - 显示已关联工作流列表
   - 保存关联关系到 `workflow_ids` 字段

2. **工作流编辑器**
   - 在 `WorkflowEditorPage` 中集成 X6Editor（复用场景页的代码）
   - 保存工作流定义到 `workflows.definition` 字段
   - 添加工作流测试/执行功能

3. **数据验证**
   - 场景名称唯一性检查
   - 工作流定义 JSON 格式验证
   - 必填字段校验

### 第三阶段：执行引擎（5-10 天）
**目标**: 实现工作流的实际执行

**任务清单**:
1. **工作流执行器**
   - 创建 Supabase Edge Function 处理工作流执行
   - 解析工作流定义 JSON
   - 按顺序执行节点逻辑
   - 记录执行日志

2. **节点类型实现**
   - 任务节点：执行脚本/API 调用
   - 决策节点：条件分支
   - 审批节点：人工审批（可选）
   - 延迟节点：等待指定时间
   - 循环节点：重复执行

3. **执行监控**
   - 实时日志流
   - 执行状态查询
   - 错误处理和重试

### 第四阶段：优化和扩展（持续）
**任务清单**:
1. 性能优化（大型流程图渲染）
2. 添加工作流模板市场
3. 实现定时触发器
4. 添加工作流版本管理
5. 集成通知系统（邮件/短信）

---

## 🔧 开发调试技巧

### 1. 查看数据库数据
```sql
-- 在 Supabase Dashboard → SQL Editor 执行

-- 查看所有场景
SELECT * FROM scenarios ORDER BY created_at DESC;

-- 查看所有工作流
SELECT * FROM workflows ORDER BY created_at DESC;

-- 查看执行日志
SELECT * FROM execution_logs ORDER BY start_time DESC;
```

### 2. 清理测试数据
```sql
-- ⚠️ 谨慎使用：删除所有数据
DELETE FROM execution_logs;
DELETE FROM scenarios;
DELETE FROM workflows;
DELETE FROM modules;
```

### 3. 查看 X6 画布数据
```javascript
// 在浏览器控制台执行
const graph = window.__x6_graph_instance__  // 如果暴露到全局
console.log(graph.toJSON())
```

### 4. 模拟用户登录
```javascript
// 在浏览器控制台执行
import { supabase } from '@/lib/supabase'

await supabase.auth.signInWithPassword({
  email: 'test@example.com',
  password: 'password123'
})
```

---

## 📞 关键联系信息

### 技术支持
- **Supabase 文档**: https://supabase.com/docs
- **AntV X6 文档**: https://x6.antv.antgroup.com/
- **React Router 文档**: https://reactrouter.com/

### 代码仓库
- 项目位置: `/tmp/cc-agent/62536010/project`
- Git 仓库: (如果有，请填写)

---

## 🐛 故障排查指南

### 问题：页面白屏，控制台无错误
**检查项**:
1. 网络请求是否成功（F12 → Network）
2. Supabase 环境变量是否正确
3. 用户是否已登录（检查 localStorage 中的 session）

### 问题：图片上传失败
**检查项**:
1. Storage bucket `sop-images` 是否存在
2. RLS 策略是否正确配置
3. 文件大小是否超过限制（默认 50MB）

### 问题：数据保存失败
**检查项**:
1. 查看浏览器控制台的错误信息
2. 检查 RLS 策略是否阻止了写入
3. 验证字段类型和长度限制

### 问题：X6 编辑器白屏
**检查项**:
1. 控制台是否有 `"X6Editor container has no size"` 警告
2. 检查容器的 computed height（F12 → Elements → Computed）
3. 尝试给容器设置固定高度（如 `height: 600px`）

---

## ✅ 交接清单

### 移交内容
- ✅ 完整项目代码
- ✅ 数据库迁移文件
- ✅ 环境配置文件（`.env` 需要接收方自行配置）
- ✅ 本交接文档

### 待确认事项
- ⬜ Supabase 项目访问权限（需要邀请新成员）
- ⬜ 代码仓库访问权限（如果使用 Git）
- ⬜ 开发环境验证（新工程师能否成功启动）

### 下一步建议
1. **立即**: 解决 X6 编辑器白屏问题（参考"推进节奏 - 第一阶段"）
2. **短期**: 完善场景工作流关联功能
3. **中期**: 实现工作流执行引擎
4. **长期**: 优化性能，扩展功能

---

## 📝 更新日志

| 日期 | 操作人 | 更新内容 |
|------|--------|----------|
| 2026-01-16 | 初始开发者 | 创建交接文档，记录当前状态和已知问题 |
| | | |

---

**祝顺利！有任何问题可以参考本文档的"故障排查指南"部分。** 🚀
