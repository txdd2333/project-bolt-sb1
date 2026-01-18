# 运维工作流中心 - 项目交接文档

## 📋 项目概述

### 项目名称
运维工作流中心 (Ops Workflow Center)

### 项目目标
构建一个可视化的运维自动化工作流平台，支持：
- 场景化的运维流程管理
- 可视化工作流编辑器
- 可复用的模块化组件
- 浏览器自动化（基于 Playwright）
- SOP 文档管理
- 流程图设计

### 核心价值
让运维人员无需编程即可创建、测试和执行自动化工作流，提升运维效率。

---

## 🏗️ 技术栈

### 前端
- **框架**: React 18 + TypeScript
- **构建工具**: Vite 6
- **路由**: React Router v6
- **状态管理**: Zustand
- **UI组件**: Tailwind CSS + Lucide React
- **流程图编辑器**:
  - LogicFlow (主要编辑器，支持拖拽)
  - ReactFlow (备选)
  - BPMN.js (BPMN 标准流程图)

### 后端
- **运行时**: Node.js 18+
- **框架**: Express
- **自动化引擎**: Playwright (支持 Chromium/Firefox/WebKit)
- **TypeScript 执行**: tsx

### 数据库
- **数据库**: Supabase (PostgreSQL)
- **认证**: Supabase Auth (邮箱/密码)
- **存储**: Supabase Storage (SOP 图片)

---

## 📊 数据库结构

### 核心表

#### 1. modules (模块表)
```sql
- id: uuid (主键)
- name: text (模块名称)
- description: text (描述)
- type: text (类型，如 'playwright')
- config: jsonb (模块配置，存储操作参数)
- icon: text (图标)
- color: text (颜色)
- user_id: uuid (创建者)
- created_at: timestamp
- updated_at: timestamp
```

#### 2. workflows (工作流表)
```sql
- id: uuid (主键)
- name: text (工作流名称)
- description: text (描述)
- definition: jsonb (工作流定义，包含节点和连线)
- user_id: uuid (创建者)
- created_at: timestamp
- updated_at: timestamp
```

#### 3. scenarios (场景表)
```sql
- id: uuid (主键)
- name: text (场景名称)
- description: text (描述)
- workflow_id: uuid (关联工作流)
- parameters: jsonb (场景参数)
- sop_content: text (SOP 内容，markdown格式)
- flowchart_data: jsonb (流程图数据)
- user_id: uuid (创建者)
- created_at: timestamp
- updated_at: timestamp
```

#### 4. execution_logs (执行日志表)
```sql
- id: uuid (主键)
- scenario_id: uuid (场景ID)
- workflow_id: uuid (工作流ID)
- parameters: jsonb (执行参数)
- status: text (状态: pending/running/completed/failed)
- started_at: timestamp (开始时间)
- completed_at: timestamp (完成时间)
- error_message: text (错误信息)
- user_id: uuid (执行者)
- created_at: timestamp
```

### 存储桶 (Storage)
- **sop-images**: 存储 SOP 文档中的图片

---

## 🚀 快速启动指南

### 1. 克隆项目
```bash
git clone <repository-url>
cd ops-workflow-center
```

### 2. 安装依赖
```bash
npm install
```

### 3. 配置环境变量
创建 `.env` 文件（参考 `.env.example`）：
```bash
# Supabase 配置（必需）
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key

# 后端服务端口
PORT=3001
```

**重要**: 必须配置正确的 Supabase 凭证，否则无法启动！

### 4. 启动开发环境

**方式一：两个终端分别启动**
```bash
# 终端1 - 前端
npm run dev

# 终端2 - 后端
npm run server
```

**方式二：使用 PM2（推荐生产环境）**
```bash
npm install -g pm2
pm2 start ecosystem.config.js
pm2 logs
```

### 5. 访问应用
- 前端: http://localhost:5173
- 后端: http://localhost:3001
- 健康检查: http://localhost:3001/health

---

## 🗄️ 数据库快速迁移

### 方法一：使用现有迁移文件（推荐）

项目中已有所有迁移文件在 `supabase/migrations/` 目录。

**步骤：**
1. 登录 Supabase 控制台
2. 进入 SQL Editor
3. 按时间顺序执行以下迁移文件：
```bash
supabase/migrations/20260114061922_create_ops_workflow_tables.sql
supabase/migrations/20260115135451_add_user_associations.sql
supabase/migrations/20260115140156_fix_scenarios_table_structure.sql
supabase/migrations/20260115140652_add_sop_and_flowchart_to_scenarios.sql
supabase/migrations/20260115151616_create_sop_images_storage_policies.sql
supabase/migrations/20260116032128_add_definition_to_workflows.sql
supabase/migrations/20260116072525_add_definition_to_workflows_update.sql
supabase/migrations/20260118092624_20260115135451_add_user_associations.sql
supabase/migrations/20260118092631_20260115140156_fix_scenarios_table_structure.sql
supabase/migrations/20260118092639_20260115140652_add_sop_and_flowchart_to_scenarios.sql
supabase/migrations/20260118092646_20260116032128_add_definition_to_workflows.sql
supabase/migrations/20260118093422_20260118101500_add_scenario_id_to_execution_logs.sql
```

### 方法二：使用一键导入脚本

创建文件 `scripts/setup-database.sql`（包含完整的数据库结构）：

```sql
-- 创建所有表和 RLS 策略
-- 运行此脚本可一次性设置整个数据库

-- 1. 创建 modules 表
CREATE TABLE IF NOT EXISTS modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  type text NOT NULL,
  config jsonb DEFAULT '{}',
  icon text DEFAULT '📦',
  color text DEFAULT '#3b82f6',
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE modules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own modules"
  ON modules FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create modules"
  ON modules FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own modules"
  ON modules FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own modules"
  ON modules FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 2. 创建 workflows 表
CREATE TABLE IF NOT EXISTS workflows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  definition jsonb DEFAULT '{"nodes":[],"edges":[]}',
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE workflows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own workflows"
  ON workflows FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create workflows"
  ON workflows FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workflows"
  ON workflows FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own workflows"
  ON workflows FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 3. 创建 scenarios 表
CREATE TABLE IF NOT EXISTS scenarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  workflow_id uuid REFERENCES workflows(id) ON DELETE SET NULL,
  parameters jsonb DEFAULT '{}',
  sop_content text DEFAULT '',
  flowchart_data jsonb DEFAULT '{}',
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE scenarios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own scenarios"
  ON scenarios FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create scenarios"
  ON scenarios FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own scenarios"
  ON scenarios FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own scenarios"
  ON scenarios FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 4. 创建 execution_logs 表
CREATE TABLE IF NOT EXISTS execution_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id uuid REFERENCES scenarios(id) ON DELETE CASCADE,
  workflow_id uuid REFERENCES workflows(id) ON DELETE CASCADE,
  parameters jsonb DEFAULT '{}',
  status text DEFAULT 'pending',
  started_at timestamptz,
  completed_at timestamptz,
  error_message text,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE execution_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own execution logs"
  ON execution_logs FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create execution logs"
  ON execution_logs FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 5. 创建存储桶
INSERT INTO storage.buckets (id, name, public)
VALUES ('sop-images', 'sop-images', true)
ON CONFLICT (id) DO NOTHING;

-- 6. 创建存储策略
CREATE POLICY "Anyone can view SOP images"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'sop-images');

CREATE POLICY "Authenticated users can upload SOP images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'sop-images');

CREATE POLICY "Users can update own SOP images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'sop-images' AND auth.uid()::text = owner);

CREATE POLICY "Users can delete own SOP images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'sop-images' AND auth.uid()::text = owner);
```

在 Supabase SQL Editor 中执行此脚本即可完成数据库设置。

### 测试数据（可选）

```sql
-- 插入示例模块
INSERT INTO modules (name, description, type, config, icon, color, user_id)
VALUES (
  '打开百度首页',
  '自动打开百度首页并截图',
  'playwright',
  '{"action":"navigate","url":"https://www.baidu.com","browserType":"chromium"}',
  '🌐',
  '#3b82f6',
  auth.uid()
);
```

---

## ✅ 已完成功能

### 1. 认证系统 ✅
- [x] 用户注册
- [x] 用户登录
- [x] 会话管理
- [x] 受保护路由

### 2. 场景管理 ✅
- [x] 场景列表展示
- [x] 场景详情页
- [x] SOP 文档编辑（Markdown + 富文本）
- [x] 流程图设计
- [x] 关联工作流

### 3. 工作流管理 ✅
- [x] 工作流列表
- [x] 可视化编辑器（LogicFlow）
- [x] 节点拖拽
- [x] 连线操作
- [x] 保存/加载工作流
- [x] 工作流执行

### 4. 模块管理 ✅ (最新)
- [x] 模块列表展示
- [x] 模块卡片样式
- [x] **模块测试功能** (NEW)
  - 点击绿色播放按钮测试
  - 显示测试进度和结果
  - 展示执行日志
- [x] 删除模块
- [x] 编辑按钮（待实现具体编辑逻辑）

### 5. 工作流编辑器优化 ✅ (最新)
- [x] 左侧元素面板分组显示
- [x] "--- 我的模块 ---" 分组
- [x] 模块配置自动应用
- [x] **浏览器类型选择** (NEW)
  - Chromium（默认）
  - Firefox
  - WebKit (Safari)

### 6. Playwright 集成 ✅
- [x] 浏览器启动（三种引擎）
- [x] 8种基础操作：
  - 打开标签页
  - 导航到URL
  - 点击元素
  - 填充输入框
  - 等待
  - 截图
  - 提取文本
  - 关闭标签页
- [x] 工作流执行引擎
- [x] 实时状态更新

### 7. 执行日志 ✅
- [x] 日志列表
- [x] 状态过滤
- [x] 执行详情

---

## 📁 项目结构

```
ops-workflow-center/
├── src/
│   ├── components/          # React 组件
│   │   ├── BpmnEditor/      # BPMN 编辑器
│   │   ├── DrawioEditor/    # Drawio 编辑器（未启用）
│   │   ├── LogicFlowEditor/ # LogicFlow 编辑器（主要）
│   │   │   ├── index.tsx
│   │   │   ├── styles.css   # 样式（包含模块分组样式）
│   │   │   └── nodes/       # 自定义节点
│   │   ├── ReactFlowEditor/ # ReactFlow 编辑器（备选）
│   │   ├── Layout.tsx       # 布局组件
│   │   ├── MarkdownEditor.tsx  # Markdown 编辑器
│   │   ├── PlaywrightPropertiesPanel.tsx  # Playwright 配置面板
│   │   └── ProtectedRoute.tsx  # 路由保护
│   │
│   ├── contexts/
│   │   └── AuthContext.tsx  # 认证上下文
│   │
│   ├── hooks/
│   │   └── useUndoRedo.ts   # 撤销/重做钩子
│   │
│   ├── lib/
│   │   ├── database.types.ts  # 数据库类型定义
│   │   ├── documentUtils.ts   # 文档工具
│   │   └── supabase.ts        # Supabase 客户端
│   │
│   ├── pages/
│   │   ├── ExecutionLogsPage.tsx  # 执行日志页
│   │   ├── LoginPage.tsx          # 登录页
│   │   ├── ModulesPage.tsx        # 模块管理页（含测试功能）
│   │   ├── RegisterPage.tsx       # 注册页
│   │   ├── ScenarioDetailPage.tsx # 场景详情页
│   │   ├── ScenariosPage.tsx      # 场景列表页
│   │   ├── WorkflowEditorPage.tsx # 工作流编辑页
│   │   └── WorkflowsPage.tsx      # 工作流列表页
│   │
│   ├── services/            # 服务层
│   │   ├── auth/            # 认证服务
│   │   ├── data/            # 数据服务
│   │   ├── playwright/      # Playwright 服务
│   │   ├── storage/         # 存储服务
│   │   ├── ServiceFactory.ts
│   │   └── types.ts
│   │
│   ├── App.tsx              # 应用入口
│   ├── main.tsx             # 主入口
│   └── index.css            # 全局样式
│
├── server/                  # 后端服务
│   ├── index.ts             # Express 服务器（含测试接口）
│   ├── playwright-executor.ts  # Playwright 执行器（支持3种浏览器）
│   ├── workflow-runner.ts   # 工作流运行器（支持模块节点）
│   └── tsconfig.json
│
├── supabase/
│   └── migrations/          # 数据库迁移文件
│
├── docs/                    # 文档
│   ├── ARCHITECTURE.md      # 架构文档
│   └── mysql-schema.sql     # 历史 MySQL 方案（已废弃）
│
├── .env                     # 环境变量（需配置）
├── .env.example             # 环境变量示例
├── package.json
├── tsconfig.json
├── vite.config.ts
└── tailwind.config.js
```

---

## 🔧 重要配置说明

### 1. Supabase 配置
**文件**: `src/lib/supabase.ts`
```typescript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

**获取凭证**:
1. 登录 Supabase 控制台
2. 进入项目设置 → API
3. 复制 URL 和 anon public key

### 2. Playwright 浏览器配置
**文件**: `server/playwright-executor.ts`

支持三种浏览器引擎，可在节点属性中选择：
```typescript
// chromium (默认)
browser = await chromium.launch({ headless: false, args: ['--start-maximized'] })

// firefox
browser = await firefox.launch({ headless: false })

// webkit (Safari)
browser = await webkit.launch({ headless: false })
```

### 3. 后端接口
**文件**: `server/index.ts`

主要接口：
- `POST /api/playwright/execute` - 执行工作流
- `POST /api/playwright/test-module` - 测试模块 (NEW)
- `GET /api/playwright/execution/:id` - 查询执行状态
- `GET /api/playwright/execution/:id/stream` - SSE 流式更新
- `GET /health` - 健康检查

---

## 🐛 已知问题

### 1. 模块编辑功能未实现
**位置**: `src/pages/ModulesPage.tsx:96-100`
```typescript
<button
  className="p-1.5 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded transition-colors"
  title="编辑"
>
  <Edit2 className="w-4 h-4" />
</button>
```
**状态**: 按钮存在但未绑定处理函数
**影响**: 无法编辑已创建的模块
**建议**: 实现编辑对话框或跳转到编辑页面

### 2. 模块创建功能未实现
**位置**: `src/pages/ModulesPage.tsx:49-52`
```typescript
<button className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors">
  <Plus className="w-4 h-4" />
  新建模块
</button>
```
**状态**: 按钮存在但未绑定处理函数
**影响**: 无法通过界面创建新模块（只能通过数据库手动插入）
**建议**: 实现创建对话框，包含：
- 模块名称
- 描述
- 类型选择（playwright/其他）
- 操作配置
- 颜色和图标选择

### 3. WebKit 浏览器可能需要额外依赖
**影响**: 在某些 Linux 发行版上可能无法启动 WebKit
**解决方案**:
```bash
# Ubuntu/Debian
npx playwright install-deps webkit

# CentOS/RHEL
# 可能需要手动安装相关库
```

### 4. 工作流节点类型不一致
**问题**: 代码中存在多种节点类型命名
- `start` vs `start-node`
- `end` vs `end-node`
- `playwright-node` vs `playwright` vs `task`

**建议**: 统一为单一命名规范

---

## 📝 待办事项

### 高优先级
- [ ] 实现模块创建对话框
- [ ] 实现模块编辑功能
- [ ] 添加工作流模板功能
- [ ] 完善错误处理和用户提示

### 中优先级
- [ ] 实现工作流版本控制
- [ ] 添加工作流调度（定时执行）
- [ ] 增加更多 Playwright 操作类型
- [ ] 实现工作流导入/导出

### 低优先级
- [ ] 性能优化（代码分割）
- [ ] 国际化支持
- [ ] 主题切换（暗色模式）
- [ ] 移动端适配

---

## 🚢 部署指南

### 开发环境
```bash
# 前端
npm run dev  # http://localhost:5173

# 后端
npm run server  # http://localhost:3001
```

### 生产环境

#### 1. 构建前端
```bash
npm run build
# 生成 dist/ 目录
```

#### 2. 使用 PM2 部署
```bash
npm install -g pm2

# 启动
pm2 start ecosystem.config.js

# 查看状态
pm2 status

# 查看日志
pm2 logs

# 重启
pm2 restart all

# 停止
pm2 stop all
```

#### 3. Nginx 配置（可选）
```nginx
server {
    listen 80;
    server_name your-domain.com;

    # 前端
    location / {
        root /path/to/dist;
        try_files $uri $uri/ /index.html;
    }

    # 后端代理
    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## 🔐 安全注意事项

### 1. 环境变量
- 永远不要提交 `.env` 文件到 Git
- 使用不同的 Supabase 项目区分开发/生产环境

### 2. RLS 策略
- 所有表都已启用 RLS
- 用户只能访问自己创建的数据
- 公开访问仅限于 SOP 图片

### 3. API 密钥
- `VITE_SUPABASE_ANON_KEY` 是公开密钥，可以暴露
- 服务端使用的 `service_role_key` 绝不能暴露

---

## 📞 常见问题

### Q: 无法连接数据库？
**A**: 检查 `.env` 文件中的 Supabase 配置是否正确。

### Q: Playwright 无法启动浏览器？
**A**: 运行 `npx playwright install` 安装浏览器二进制文件。

### Q: 测试模块时报错"无法连接到后端服务"？
**A**: 确保后端服务已启动（`npm run server`）。

### Q: 如何切换到其他数据库？
**A**: 不建议！项目深度集成 Supabase，切换成本极高。

### Q: 模块测试一直显示"正在测试"？
**A**: 检查后端日志，可能是 Playwright 执行超时。

---

## 🎯 快速验证清单

在交接完成后，新工程师应该验证以下功能：

### 基础功能
- [ ] 能够访问登录页面
- [ ] 能够注册新用户
- [ ] 能够登录并看到主界面

### 数据库功能
- [ ] 场景列表能正常加载
- [ ] 能创建新场景
- [ ] 能编辑 SOP 文档
- [ ] 能上传图片到 SOP

### 工作流功能
- [ ] 能打开工作流编辑器
- [ ] 能拖拽节点到画布
- [ ] 能连接节点
- [ ] 能看到"我的模块"分组
- [ ] 能选择浏览器类型

### 模块功能
- [ ] 能查看模块列表
- [ ] 能点击绿色播放按钮测试模块
- [ ] 能看到测试结果和日志

### Playwright 功能
- [ ] 后端服务能正常启动
- [ ] 能执行简单工作流（如打开百度）
- [ ] 浏览器能正常启动（Chromium）
- [ ] 能在日志中看到执行记录

---

## 📚 参考资源

### 文档
- [Supabase 文档](https://supabase.com/docs)
- [Playwright 文档](https://playwright.dev/)
- [LogicFlow 文档](http://logic-flow.org/)
- [React Router 文档](https://reactrouter.com/)
- [Tailwind CSS 文档](https://tailwindcss.com/)

### 项目内文档
- `DATABASE.md` - 数据库详细说明
- `DEVELOPMENT.md` - 开发指南
- `PLAYWRIGHT_GUIDE.md` - Playwright 使用指南
- `ARCHITECTURE.md` - 架构设计文档

---

## 🤝 交接清单

### 需要交接的信息
- [ ] Supabase 项目访问权限
- [ ] 项目 Git 仓库访问权限
- [ ] `.env` 环境变量配置
- [ ] 服务器访问权限（如有）
- [ ] 域名和 DNS 配置（如有）

### 需要确认的事项
- [ ] 新工程师能独立启动项目
- [ ] 数据库结构已完整迁移
- [ ] 所有功能可正常运行
- [ ] 已知问题已充分说明
- [ ] 文档已更新到最新

---

## 📧 联系方式

如有问题，请参考项目文档或联系前任开发者。

---

**最后更新**: 2026-01-18
**文档版本**: v1.0
**项目版本**: 0.1.0

祝接手顺利！🎉
